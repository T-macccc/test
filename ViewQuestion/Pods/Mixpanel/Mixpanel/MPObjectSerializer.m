//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <objc/runtime.h>
#import "UIView+MPHelpers.h"
#import "MPClassDescription.h"
#import "MPEnumDescription.h"
#import "MPObjectIdentityProvider.h"
#import "MPObjectSerializer.h"
#import "MPObjectSerializerConfig.h"
#import "MPObjectSerializerContext.h"
#import "MPPropertyDescription.h"
#import "NSInvocation+MPHelpers.h"

@interface MPObjectSerializer ()

@end

@implementation MPObjectSerializer

{
    MPObjectSerializerConfig *_configuration;
    MPObjectIdentityProvider *_objectIdentityProvider;
}

- (instancetype)initWithConfiguration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider
{
    self = [super init];
    if (self) {
        _configuration = configuration;
        _objectIdentityProvider = objectIdentityProvider;
    }

    return self;
}

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject
{
    NSParameterAssert(rootObject != nil);

    MPObjectSerializerContext *context = [[MPObjectSerializerContext alloc] initWithRootObject:rootObject];
    //unvisitedObjects = rootObject;visitedObjects,serializedObjects初始化

    while ([context hasUnvisitedObjects])//unvisitedObjects>0
    {
        [self visitObject:[context dequeueUnvisitedObject] withContext:context];
    }

    return @{
            @"objects" : [context allSerializedObjects],
            @"rootObject": [_objectIdentityProvider identifierForObject:rootObject]//identifier
    };
}

- (void)visitObject:(NSObject *)object withContext:(MPObjectSerializerContext *)context//context[id]增加一个元素（包含propertyValue和delegateMethod:delegateInfo.selectorName）
{
    NSParameterAssert(object != nil);
    NSParameterAssert(context !=  nil);

    [context addVisitedObject:object];

    NSMutableDictionary *propertyValues = [[NSMutableDictionary alloc] init];

    MPClassDescription *classDescription = [self classDescriptionForObject:object];//classDescription = _classes[@"object"]
    if (classDescription) {
        for (MPPropertyDescription *propertyDescription in [classDescription propertyDescriptions]) {//遍历self.propertyDescription
            if ([propertyDescription shouldReadPropertyValueForObject:object]) {
                id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context];//返回id array;
                propertyValues[propertyDescription.name] = propertyValue ?: [NSNull null];
            }
        }
    }

    NSMutableArray *delegateMethods = [NSMutableArray array];
    id delegate;
    SEL delegateSelector = NSSelectorFromString(@"delegate");

    if (classDescription && [[classDescription delegateInfos] count] > 0 && [object respondsToSelector:delegateSelector]) {
        delegate = ((id (*)(id, SEL))[object methodForSelector:delegateSelector])(object, delegateSelector);
        for (MPDelegateInfo *delegateInfo in [classDescription delegateInfos]) {
            if ([delegate respondsToSelector:NSSelectorFromString(delegateInfo.selectorName)]) {
                [delegateMethods addObject:delegateInfo.selectorName];
            }
        }
    }

    NSDictionary *serializedObject = @{
        @"id": [_objectIdentityProvider identifierForObject:object],
        @"class": [self classHierarchyArrayForObject:object],
        @"properties": propertyValues,
        @"delegate": @{
                @"class": delegate ? NSStringFromClass([delegate class]) : @"",
                @"selectors": delegateMethods
            }
    };

    [context addSerializedObject:serializedObject];
}

- (NSArray *)classHierarchyArrayForObject:(NSObject *)object//向Hierachy添加object类名字符串
{
    NSMutableArray *classHierarchy = [[NSMutableArray alloc] init];

    Class aClass = [object class];
    while (aClass)
    {
        [classHierarchy addObject:NSStringFromClass(aClass)];
        aClass = [aClass superclass];//更新
    }

    return [classHierarchy copy];
}

- (NSArray *)allValuesForType:(NSString *)typeName
{//取出_configuration的@"type"中的所有value
    
    NSParameterAssert(typeName != nil);

    MPTypeDescription *typeDescription = [_configuration typeWithName:typeName];//取_enum或_class对应@"type"的value,
    if ([typeDescription isKindOfClass:[MPEnumDescription class]]) {
        MPEnumDescription *enumDescription = (MPEnumDescription *)typeDescription;
        return [enumDescription allValues];
    }

    return @[];
}

- (NSArray *)parameterVariationsForPropertySelector:(MPPropertySelectorDescription *)selectorDescription//遍历组一个由selectorDescription.parameters[0].type组成的variants数组
{
    NSAssert([selectorDescription.parameters count] <= 1, @"Currently only support selectors that take 0 to 1 arguments.");

    NSMutableArray *variations = [[NSMutableArray alloc] init];

    // TODO: write an algorithm that generates all the variations of parameter combinations.
    if ([selectorDescription.parameters count] > 0) {
        MPPropertySelectorParameterDescription *parameterDescription = (selectorDescription.parameters)[0];
        for (id value in [self allValuesForType:parameterDescription.type]) {
            [variations addObject:@[ value ]];
        }
    } else {
        // An empty array of parameters (for methods that have no parameters).
        [variations addObject:@[]];
    }

    return [variations copy];
}

- (id)instanceVariableValueForObject:(id)object propertyDescription:(MPPropertyDescription *)propertyDescription
{
    NSParameterAssert(object != nil);
    NSParameterAssert(propertyDescription != nil);

    Ivar ivar = class_getInstanceVariable([object class], [propertyDescription.name UTF8String]);
    if (ivar) {
        const char *objCType = ivar_getTypeEncoding(ivar);

        ptrdiff_t ivarOffset = ivar_getOffset(ivar);
        const void *objectBaseAddress = (__bridge const void *)object;
        const void *ivarAddress = (((const uint8_t *)objectBaseAddress) + ivarOffset);

        switch (objCType[0])
        {
            case _C_ID:       return object_getIvar(object, ivar);
            case _C_CHR:      return @(*((char *)ivarAddress));
            case _C_UCHR:     return @(*((unsigned char *)ivarAddress));
            case _C_SHT:      return @(*((short *)ivarAddress));
            case _C_USHT:     return @(*((unsigned short *)ivarAddress));
            case _C_INT:      return @(*((int *)ivarAddress));
            case _C_UINT:     return @(*((unsigned int *)ivarAddress));
            case _C_LNG:      return @(*((long *)ivarAddress));
            case _C_ULNG:     return @(*((unsigned long *)ivarAddress));
            case _C_LNG_LNG:  return @(*((long long *)ivarAddress));
            case _C_ULNG_LNG: return @(*((unsigned long long *)ivarAddress));
            case _C_FLT:      return @(*((float *)ivarAddress));
            case _C_DBL:      return @(*((double *)ivarAddress));
            case _C_BOOL:     return @(*((_Bool *)ivarAddress));
            case _C_SEL:      return NSStringFromSelector(*((SEL*)ivarAddress));
            default:
                NSAssert(NO, @"Currently unsupported return type!");
                break;
        }
    }

    return nil;
}

- (NSInvocation *)invocationForObject:(id)object withSelectorDescription:(MPPropertySelectorDescription *)selectorDescription//由selectorDescription.selectorName构invocation
{
    NSUInteger __unused parameterCount = [selectorDescription.parameters count];

    SEL aSelector = NSSelectorFromString(selectorDescription.selectorName);
    NSAssert(aSelector != nil, @"Expected non-nil selector!");

    NSMethodSignature *methodSignature = [object methodSignatureForSelector:aSelector];
    NSInvocation *invocation = nil;

    if (methodSignature) {
        NSAssert([methodSignature numberOfArguments] == (parameterCount + 2), @"Unexpected number of arguments!");

        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = aSelector;
    }
    return invocation;
}

- (id)propertyValue:(id)propertyValue propertyDescription:(MPPropertyDescription *)propertyDescription context:(MPObjectSerializerContext *)context
{//将propertyValue分类visit和unvisit，并生成id列表
    if (propertyValue != nil) {
        if ([context isVisitedObject:propertyValue]) {//如果包含，则返回id
            return [_objectIdentityProvider identifierForObject:propertyValue];
        }
        else if ([self isNestedObjectType:propertyDescription.type])//如果嵌套propertyDescription.type，则将第一个参数加入unvisitObject,返回id
        {
            [context enqueueUnvisitedObject:propertyValue];
            return [_objectIdentityProvider identifierForObject:propertyValue];
        }
        else if ([propertyValue isKindOfClass:[NSArray class]] || [propertyValue isKindOfClass:[NSSet class]])
        {
            NSMutableArray *arrayOfIdentifiers = [[NSMutableArray alloc] init];
            for (id value in propertyValue) {
                if ([context isVisitedObject:value] == NO) {
                    [context enqueueUnvisitedObject:value];
                }

                [arrayOfIdentifiers addObject:[_objectIdentityProvider identifierForObject:value]];//添加 value的identify
            }
            propertyValue = [arrayOfIdentifiers copy];//identify列表
        }
    }

    return [propertyDescription.valueTransformer transformedValue:propertyValue];
}

- (id)propertyValueForObject:(NSObject *)object withPropertyDescription:(MPPropertyDescription *)propertyDescription context:(MPObjectSerializerContext *)context
{//value为valueForKey(selectorDescription.selectorName),valueForIvar(propertyDescription),returnValue([invocation mp_returnValue])生成id的数组
    NSMutableArray *values = [[NSMutableArray alloc] init];


    MPPropertySelectorDescription *selectorDescription = propertyDescription.getSelectorDescription;

    if (propertyDescription.useKeyValueCoding) {
        // the "fast" (also also simple) path is to use KVC
        id valueForKey = [object valueForKey:selectorDescription.selectorName];//propertyDescription.getSelectDescription.selectorname

        id value = [self propertyValue:valueForKey
                   propertyDescription:propertyDescription
                               context:context];

        NSDictionary *valueDictionary = @{
                @"value" : (value ?: [NSNull null])
        };

        [values addObject:valueDictionary];
    }
    else if (propertyDescription.useInstanceVariableAccess)
    {
        id valueForIvar = [self instanceVariableValueForObject:object propertyDescription:propertyDescription];

        id value = [self propertyValue:valueForIvar
                   propertyDescription:propertyDescription
                               context:context];

        NSDictionary *valueDictionary = @{
            @"value" : (value ?: [NSNull null])
        };

        [values addObject:valueDictionary];
    } else {
        // the "slow" NSInvocation path. Required in order to invoke methods that take parameters.
        NSInvocation *invocation = [self invocationForObject:object withSelectorDescription:selectorDescription];//由第二个参数生成invacation
        if (invocation) {
            NSArray *parameterVariations = [self parameterVariationsForPropertySelector:selectorDescription];//参数类型数组

            for (NSArray *parameters in parameterVariations) {
                [invocation mp_setArgumentsFromArray:parameters];
                [invocation invokeWithTarget:object];

                id returnValue = [invocation mp_returnValue];

                id value = [self propertyValue:returnValue
                           propertyDescription:propertyDescription
                                       context:context];

                NSDictionary *valueDictionary = @{
                    @"where": @{ @"parameters" : parameters },
                    @"value": (value ?: [NSNull null])
                };

                [values addObject:valueDictionary];
            }
        }
    }

    return @{@"values": values};
}

- (BOOL)isNestedObjectType:(NSString *)typeName//嵌套
{
    return [_configuration classWithName:typeName] != nil;//className[@"typename"]
}

- (MPClassDescription *)classDescriptionForObject:(NSObject *)object
{
    NSParameterAssert(object != nil);

    Class aClass = [object class];
    while (aClass != nil)
    {
        MPClassDescription *classDescription = [_configuration classWithName:NSStringFromClass(aClass)];//_classes[@"aclass"]
        if (classDescription) {
            return classDescription;
        }

        aClass = [aClass superclass];
    }

    return nil;
}

@end

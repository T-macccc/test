//
//  MPEventBinding.m
//  HelloMixpanel
//
//  Created by Amanda Canyon on 7/22/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "Mixpanel.h"
#import "MPEventBinding.h"
#import "MPUIControlBinding.h"
#import "MPUITableViewBinding.h"

@implementation MPEventBinding

+ (MPEventBinding *)bindingWithJSONObject:(NSDictionary *)object
{
    if (object == nil) {
        NSLog(@"must supply an JSON object to initialize from");
        return nil;
    }

    NSString *bindingType = object[@"event_type"];//object[@"event_type"]=@"ui_control";
    Class klass = [self subclassFromString:bindingType];//子类类型:MPUIControlBinding查找
    return [klass bindingWithJSONObject:object];//创建并初始化MPUIControlBinding(继承MPEventBinding)对象，验证object[@"verify_Event"]
}

+ (MPEventBinding *)bindngWithJSONObject:(NSDictionary *)object//object[@"event_type"]的子类创建并初始化MPUIControlBinding对象，验证object[@"verify_Event"]
{
    return [self bindingWithJSONObject:object];
}

+ (Class)subclassFromString:(NSString *)bindingType//?
{
    NSDictionary *classTypeMap = @{
                                   [MPUIControlBinding typeName] : [MPUIControlBinding class],
                                   [MPUITableViewBinding typeName] : [MPUITableViewBinding class]
                                   };
    NSLog(@"%@",[classTypeMap valueForKey:bindingType] ?: [MPUIControlBinding class]);
    return[classTypeMap valueForKey:bindingType] ?: [MPUIControlBinding class];
}

+ (void)track:(NSString *)event properties:(NSDictionary *)properties//properties添加key:@"$from_binding"
{
    NSMutableDictionary *bindingProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys: @YES, @"$from_binding", nil];
    [bindingProperties addEntriesFromDictionary:properties];
    [[Mixpanel sharedInstance] track:event properties:bindingProperties];
}

- (instancetype)initWithEventName:(NSString *)eventName onPath:(NSString *)path
{
    if (self = [super init]) {
        self.eventName = eventName;
        self.path = [[MPObjectSelector alloc] initWithString:path];
        self.name = [[NSUUID UUID] UUIDString];
        self.running = NO;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Event Binding base class: '%@' for '%@'", [self eventName], [self path]];
}

#pragma mark -- Method stubs

+ (NSString *)typeName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)execute
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)stop
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark -- NSCoder

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSString *path = [aDecoder decodeObjectForKey:@"path"];
    NSString *eventName = [aDecoder decodeObjectForKey:@"eventName"];
    if (self = [self initWithEventName:eventName onPath:path]) {
        self.ID = [[aDecoder decodeObjectForKey:@"ID"] unsignedLongValue];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.swizzleClass = NSClassFromString([aDecoder decodeObjectForKey:@"swizzleClass"]);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(_ID) forKey:@"ID"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_path.string forKey:@"path"];
    [aCoder encodeObject:_eventName forKey:@"eventName"];
    [aCoder encodeObject:NSStringFromClass(_swizzleClass) forKey:@"swizzleClass"];
}

@end

//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPClassDescription.h"
#import "MPPropertyDescription.h"

@implementation MPDelegateInfo

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _selectorName = dictionary[@"selector"];
    }
    return self;
}

@end

@implementation MPClassDescription

{
    NSArray *_propertyDescriptions;
    NSArray *_delegateInfos;
}

- (instancetype)initWithSuperclassDescription:(MPClassDescription *)superclassDescription dictionary:(NSDictionary *)dictionary//将字典中的properties加入propertyDescriptions，将字典中的delegateImplements加入delegateInfos
{
    self = [super initWithDictionary:dictionary];//self.name = dictionary[@"name"];
    if (self) {
        _superclassDescription = superclassDescription;//?

        NSMutableArray *propertyDescriptions = [NSMutableArray array];
        for (NSDictionary *propertyDictionary in dictionary[@"properties"]) {
            [propertyDescriptions addObject:[[MPPropertyDescription alloc] initWithDictionary:propertyDictionary]];
        }

        _propertyDescriptions = [propertyDescriptions copy];

        NSMutableArray *delegateInfos = [NSMutableArray array];
        for (NSDictionary *delegateInfoDictionary in dictionary[@"delegateImplements"]) {
            [delegateInfos addObject:[[MPDelegateInfo alloc] initWithDictionary:delegateInfoDictionary]];
        }
        _delegateInfos = [delegateInfos copy];
    }

    return self;
}

- (NSArray *)propertyDescriptions//获得self.propertyDescription
{
    NSMutableDictionary *allPropertyDescriptions = [[NSMutableDictionary alloc] init];

    MPClassDescription *description = self;
    while (description)
    {
        for (MPPropertyDescription *propertyDescription in description->_propertyDescriptions) {
            if (!allPropertyDescriptions[propertyDescription.name]) {
                allPropertyDescriptions[propertyDescription.name] = propertyDescription;
            }
        }
        description = description.superclassDescription;
    }

    return [allPropertyDescriptions allValues];
}

- (BOOL)isDescriptionForKindOfClass:(Class)class
{
    return [self.name isEqualToString:NSStringFromClass(class)] && [self.superclassDescription isDescriptionForKindOfClass:[class superclass]];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@:%p name='%@' superclass='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.superclassDescription ? self.superclassDescription.name : @""];
}

@end

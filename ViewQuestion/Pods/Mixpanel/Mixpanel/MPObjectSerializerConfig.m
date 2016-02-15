//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPClassDescription.h"
#import "MPEnumDescription.h"
#import "MPObjectSerializerConfig.h"
#import "MPTypeDescription.h"

@implementation MPObjectSerializerConfig

{
    NSDictionary *_classes;
    NSDictionary *_enums;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary//获得_class,_enums
{
    self = [super init];
    if (self) {//classDescription内的元素为dictionary[@"classes"]的元素，enumDescription内的元素为dictionary[@"enum"]的元素
        NSMutableDictionary *classDescriptions = [[NSMutableDictionary alloc] init];
        for (NSDictionary *d in dictionary[@"classes"]) {//遍历dictionary[@"classes"]，获得其中元素
            NSString *superclassName = d[@"superclass"];//获取元素superclass键值
            MPClassDescription *superclassDescription = superclassName ? classDescriptions[superclassName] : nil;
            MPClassDescription *classDescription = [[MPClassDescription alloc] initWithSuperclassDescription:superclassDescription
                                                                                                  dictionary:d];

            classDescriptions[classDescription.name] = classDescription;
        }

        NSMutableDictionary *enumDescriptions = [[NSMutableDictionary alloc] init];
        for (NSDictionary *d in dictionary[@"enums"]) {
            MPEnumDescription *enumDescription = [[MPEnumDescription alloc] initWithDictionary:d];
            enumDescriptions[enumDescription.name] = enumDescription;
        }

        _classes = [classDescriptions copy];
        _enums = [enumDescriptions copy];
    }

    return self;
}

- (NSArray *)classDescriptions
{
    return [_classes allValues];
}

- (MPEnumDescription *)enumWithName:(NSString *)name
{
    return _enums[name];
}

- (MPClassDescription *)classWithName:(NSString *)name
{
    return _classes[name];
}

- (MPTypeDescription *)typeWithName:(NSString *)name
{
    MPEnumDescription *enumDescription = [self enumWithName:name];//_enum[name]
    if (enumDescription) {
        return enumDescription;
    }

    MPClassDescription *classDescription = [self classWithName:name];//_class[name]
    if (classDescription) {
        return classDescription;
    }

    return nil;
}

@end

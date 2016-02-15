//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPObjectSerializerContext.h"

@implementation MPObjectSerializerContext

{
    NSMutableSet *_visitedObjects;
    NSMutableSet *_unvisitedObjects;
    NSMutableDictionary *_serializedObjects;
}

- (instancetype)initWithRootObject:(id)object
{
    self = [super init];
    if (self) {
        _visitedObjects = [NSMutableSet set];
        _unvisitedObjects = [NSMutableSet setWithObject:object];
        _serializedObjects = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (BOOL)hasUnvisitedObjects//是否含有unvisitedObjects
{
    return [_unvisitedObjects count] > 0;
}

- (void)enqueueUnvisitedObject:(NSObject *)object//unvisitedObjected添加元素
{
    NSParameterAssert(object != nil);

    [_unvisitedObjects addObject:object];
}

- (NSObject *)dequeueUnvisitedObject//从_unvisitedObjecteds取出元素，并移除该元素
{
    NSObject *object = [_unvisitedObjects anyObject];
    [_unvisitedObjects removeObject:object];

    return object;
}

- (void)addVisitedObject:(NSObject *)object//_visitedObjects添加元素
{
    NSParameterAssert(object != nil);

    [_visitedObjects addObject:object];
}

- (BOOL)isVisitedObject:(NSObject *)object//是否包含该值
{
    return object && [_visitedObjects containsObject:object];
}

- (void)addSerializedObject:(NSDictionary *)serializedObject//_serializedObjects[object[@"id"]]添加object
{
    NSParameterAssert(serializedObject[@"id"] != nil);
    _serializedObjects[serializedObject[@"id"]] = serializedObject;
}

- (NSArray *)allSerializedObjects
{
    return [_serializedObjects allValues];
}

@end

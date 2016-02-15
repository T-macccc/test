//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPObjectIdentityProvider.h"
#import "MPSequenceGenerator.h"

@implementation MPObjectIdentityProvider

{
    NSMapTable *_objectToIdentifierMap;
    MPSequenceGenerator *_sequenceGenerator;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _objectToIdentifierMap = [NSMapTable weakToStrongObjectsMapTable];
        _sequenceGenerator = [[MPSequenceGenerator alloc] init];
    }

    return self;
}

- (NSString *)identifierForObject:(id)object//从_objectToIdentifierMap的key[object]的值初始化identifier
{
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    NSString *identifier = [_objectToIdentifierMap objectForKey:object];//identify = _objectToIdentifierMap[object];
    if (identifier == nil) {
        identifier = [NSString stringWithFormat:@"$%" PRIi32, [_sequenceGenerator nextValue]];
        [_objectToIdentifierMap setObject:identifier forKey:object];
    }

    return identifier;
}

@end

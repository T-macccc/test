//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <QuartzCore/QuartzCore.h>
#import "MPApplicationStateSerializer.h"
#import "MPClassDescription.h"
#import "MPLogger.h"
#import "MPObjectIdentityProvider.h"
#import "MPObjectSerializer.h"
#import "MPObjectSerializerConfig.h"

@implementation MPApplicationStateSerializer

{
    MPObjectSerializer *_serializer;
    UIApplication *_application;
}

- (instancetype)initWithApplication:(UIApplication *)application configuration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider
{
    NSParameterAssert(application != nil);
    NSParameterAssert(configuration != nil);

    self = [super init];
    if (self) {
        _application = application;
        _serializer = [[MPObjectSerializer alloc] initWithConfiguration:configuration objectIdentityProvider:objectIdentityProvider];
    }

    return self;
}

- (UIImage *)screenshotImageForWindowAtIndex:(NSUInteger)index//获取快照
{
    UIImage *image = nil;

    UIWindow *window = [self windowAtIndex:index];
    if (window && !CGRectEqualToRect(window.frame, CGRectZero)) {//存在有效windows
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, window.screen.scale);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {//致使当前快照的视图层次结构放于context中
            if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO] == NO) {//快照数据丢失
                MixpanelError(@"Unable to get complete screenshot for window at index: %d.", (int)index);
            }
        } else {//获得context
            [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
#else
        [window.layer renderInContext:UIGraphicsGetCurrentContext()];
#endif
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return image;
}

- (UIWindow *)windowAtIndex:(NSUInteger)index//获得windows[index]
{
    NSParameterAssert(index < [_application.windows count]);
    return _application.windows[index];
}

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index
{
    UIWindow *window = [self windowAtIndex:index];
    if (window) {
        return [_serializer serializedObjectsWithRootObject:window];//生成id，
    }

    return @{};
}

@end

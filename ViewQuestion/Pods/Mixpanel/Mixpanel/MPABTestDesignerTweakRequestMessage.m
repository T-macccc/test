//
//  MPABTestDesignerTweakRequestMessage.h
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 7/5/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerTweakRequestMessage.h"
#import "MPABTestDesignerTweakResponseMessage.h"
#import "MPLogger.h"
#import "MPVariant.h"

NSString *const MPABTestDesignerTweakRequestMessageType = @"tweak_request";

@implementation MPABTestDesignerTweakRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerTweakRequestMessageType];//self.type = @"tweak_request"
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection//variant添加_payload[@"tweak"]
{
    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        MPABTestDesignerConnection *conn = weak_connection;

        MPVariant *variant = [conn sessionObjectForKey:kSessionVariantKey];//variant = _sessionn[@"session_variant"]
        if (!variant) {
            variant = [[MPVariant alloc] init];
            [conn setSessionObject:variant forKey:kSessionVariantKey];//_session[@"session_variant"] = variant
        }

        if ([[self payload][@"tweaks"] isKindOfClass:[NSArray class]]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [variant addTweaksFromJSONObject:[self payload][@"tweaks"] andExecute:YES];
            });
        }

        MPABTestDesignerTweakResponseMessage *changeResponseMessage = [MPABTestDesignerTweakResponseMessage message];
        changeResponseMessage.status = @"OK";
        [conn sendMessage:changeResponseMessage];
    }];

    return operation;
}

@end

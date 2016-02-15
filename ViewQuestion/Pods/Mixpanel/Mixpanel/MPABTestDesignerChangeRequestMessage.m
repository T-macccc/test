//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPABTestDesignerChangeRequestMessage.h"
#import "MPABTestDesignerChangeResponseMessage.h"
#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerSnapshotResponseMessage.h"
#import "MPVariant.h"

NSString *const MPABTestDesignerChangeRequestMessageType = @"change_request";

@implementation MPABTestDesignerChangeRequestMessage

+ (instancetype)message//self.type = @"change_request"
{
    return [[self alloc] initWithType:MPABTestDesignerChangeRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        MPABTestDesignerConnection *conn = weak_connection;

        MPVariant *variant = [connection sessionObjectForKey:kSessionVariantKey];//创建_session[@"session_variant"]这个key
        if (!variant) {
            variant = [[MPVariant alloc] init];
            [connection setSessionObject:variant forKey:kSessionVariantKey];
        }

        if ([[self payload][@"actions"] isKindOfClass:[NSArray class]]) {//_payload[@"action"]
            dispatch_sync(dispatch_get_main_queue(), ^{
                [variant addActionsFromJSONObject:[self payload][@"actions"] andExecute:YES];
            });
        }
        
        MPABTestDesignerChangeResponseMessage *changeResponseMessage = [MPABTestDesignerChangeResponseMessage message];//changeResponseMessage.type = @"change_response"
        changeResponseMessage.status = @"OK";
        [conn sendMessage:changeResponseMessage];
    }];

    return operation;
}

@end

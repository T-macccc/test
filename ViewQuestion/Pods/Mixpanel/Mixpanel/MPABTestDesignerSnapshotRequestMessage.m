//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerSnapshotRequestMessage.h"
#import "MPABTestDesignerSnapshotResponseMessage.h"
#import "MPApplicationStateSerializer.h"
#import "MPObjectIdentityProvider.h"
#import "MPObjectSerializerConfig.h"

NSString * const MPABTestDesignerSnapshotRequestMessageType = @"snapshot_request";

static NSString * const kSnapshotSerializerConfigKey = @"snapshot_class_descriptions";
static NSString * const kObjectIdentityProviderKey = @"object_identity_provider";

@implementation MPABTestDesignerSnapshotRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerSnapshotRequestMessageType];//self.type = @"snapshot_request"
}

- (MPObjectSerializerConfig *)configuration//_payload[@"config"]
{
    NSDictionary *config =
#if 1
    [self payloadObjectForKey:@"config"];
#else
    [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"snapshot_config" withExtension:@"json"]]
                                    options:0 error:nil];
#endif

    return config ? [[MPObjectSerializerConfig alloc] initWithDictionary:config] : nil;//enums,class
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection//MPApplicationStateSerializer有关，创建并初始化，获得截图并发生送
{
    __block MPObjectSerializerConfig *serializerConfig = self.configuration;
    __block NSString *imageHash = [self payloadObjectForKey:@"image_hash"];//_payload[@"image_hash"]

    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong MPABTestDesignerConnection *conn = weak_connection;

        // Update the class descriptions in the connection session if provided as part of the message.
        if (serializerConfig) {//更新serializerconfig(self.configuration)
            [connection setSessionObject:serializerConfig forKey:kSnapshotSerializerConfigKey];//_session[snapshot_class_description] = self.configuration
        } else if ([connection sessionObjectForKey:kSnapshotSerializerConfigKey]){//_session[snapshot_class_configuration]
            // Get the class descriptions from the connection session store.
            serializerConfig = [connection sessionObjectForKey:kSnapshotSerializerConfigKey];
        } else {
            // If neither place has a config, this is probably a stale message and we can't create a snapshot.
            return;
        }

        // Get the object identity provider from the connection's session store or create one if there is none already.
        MPObjectIdentityProvider *objectIdentityProvider = [connection sessionObjectForKey:kObjectIdentityProviderKey];//objectIdentityProvider = _session[@"object_identity_provider"]
        if (objectIdentityProvider == nil) {
            objectIdentityProvider = [[MPObjectIdentityProvider alloc] init];
            [connection setSessionObject:objectIdentityProvider forKey:kObjectIdentityProviderKey];//_session[object_identity_provider] = objectIdentityProvider
        }

        MPApplicationStateSerializer *serializer = [[MPApplicationStateSerializer alloc] initWithApplication:[UIApplication sharedApplication]
                                                                                               configuration:serializerConfig//self.configuration
                                                                                      objectIdentityProvider:objectIdentityProvider];

        MPABTestDesignerSnapshotResponseMessage *snapshotMessage = [MPABTestDesignerSnapshotResponseMessage message];
        __block UIImage *screenshot = nil;
        __block NSDictionary *serializedObjects = nil;

        dispatch_sync(dispatch_get_main_queue(), ^{
            screenshot = [serializer screenshotImageForWindowAtIndex:0];//获取当前快照
//            NSError *error;
//            
//            NSString *pathPNG = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.png"];
//            NSString *pathJPEG = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.jpg"];
//            [UIImageJPEGRepresentation(screenshot, 1) writeToFile:pathJPEG atomically:YES];
//            [UIImagePNGRepresentation(screenshot) writeToFile:pathPNG options:0 error:&error];
//            NSLog(@"pathJPG-%@",pathJPEG);
//            NSLog(@"pathPNG-%@",pathPNG);
//            
//            NSData *data = UIImageJPEGRepresentation(screenshot, 0.5);
//            NSLog(@"error:%@",error);
        });
        snapshotMessage.screenshot = screenshot;

        if (imageHash && [imageHash isEqualToString:snapshotMessage.imageHash]) {
            serializedObjects = [connection sessionObjectForKey:@"snapshot_hierarchy"];//hierarchy层次结构
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                serializedObjects = [serializer objectHierarchyForWindowAtIndex:0];//objects,rootObject
            });
            [connection setSessionObject:serializedObjects forKey:@"snapshot_hierarchy"];//_session[@"snapshot_hierachy"] = serializedObjects
        }

        snapshotMessage.serializedObjects = serializedObjects;
        [conn sendMessage:snapshotMessage];
    }];

    return operation;
}

@end

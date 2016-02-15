#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "MPLogger.h"
#import "MPNotification.h"

@interface MPNotification ()

- (instancetype)initWithID:(NSUInteger)ID messageID:(NSUInteger)messageID type:(NSString *)type title:(NSString *)title body:(NSString *)body callToAction:(NSString *)callToAction callToActionURL:(NSURL *)callToActionURL imageURL:(NSURL *)imageURL;

@end

@implementation MPNotification

NSString *const MPNotificationTypeMini = @"mini";
NSString *const MPNotificationTypeTakeover = @"takeover";

+ (MPNotification *)notificationWithJSONObject:(NSDictionary *)object
{//@"id",@"message_id",@"type",@"title"@"body",callToAction:@"cta",@"image_url",@"cta_url",url的处理
    if (object == nil) {
        MixpanelError(@"notif json object should not be nil");
        return nil;
    }

    NSNumber *ID = object[@"id"];
    if (!([ID isKindOfClass:[NSNumber class]] && [ID integerValue] > 0)) {
        MixpanelError(@"invalid notif id: %@", ID);
        return nil;
    }

    NSNumber *messageID = object[@"message_id"];
    if (!([messageID isKindOfClass:[NSNumber class]] && [messageID integerValue] > 0)) {
        MixpanelError(@"invalid notif message id: %@", messageID);
        return nil;
    }

    NSString *type = object[@"type"];
    if (![type isKindOfClass:[NSString class]]) {
        MixpanelError(@"invalid notif type: %@", type);
        return nil;
    }

    NSString *title = object[@"title"];
    if (![title isKindOfClass:[NSString class]]) {
        MixpanelError(@"invalid notif title: %@", title);
        return nil;
    }

    NSString *body = object[@"body"];
    if (![body isKindOfClass:[NSString class]]) {
        MixpanelError(@"invalid notif body: %@", body);
        return nil;
    }

    NSString *callToAction = object[@"cta"];
    if (![callToAction isKindOfClass:[NSString class]]) {
        MixpanelError(@"invalid notif cta: %@", callToAction);
        return nil;
    }

    NSURL *callToActionURL = nil;
    NSObject *URLString = object[@"cta_url"];
    if (URLString != nil && ![URLString isKindOfClass:[NSNull class]]) {
        if (![URLString isKindOfClass:[NSString class]] || [(NSString *)URLString length] == 0) {
            MixpanelError(@"invalid notif URL: %@", URLString);
            return nil;
        }

        callToActionURL = [NSURL URLWithString:(NSString *)URLString];
        if (callToActionURL == nil) {
            MixpanelError(@"invalid notif URL: %@", URLString);
            return nil;
        }
    }

    NSURL *imageURL = nil;
    NSString *imageURLString = object[@"image_url"];//获得对象中的url值.
    if (imageURLString != nil && ![imageURLString isKindOfClass:[NSNull class]]) {//错误类型筛选
        if (![imageURLString isKindOfClass:[NSString class]]) {
            MixpanelError(@"invalid notif image URL: %@", imageURLString);
            return nil;
        }

        NSString *escapedUrl = [imageURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//网址字符串utf-8编码
        imageURL = [NSURL URLWithString:escapedUrl];//转换成url
        if (imageURL == nil) {
            MixpanelError(@"invalid notif image URL: %@", imageURLString);
            return nil;
        }

        NSString *imagePath = imageURL.path;//获得编译前路径
        if ([type isEqualToString:MPNotificationTypeTakeover]) {//object[@"type"] == @"takeover"
            NSString *imageName = [imagePath stringByDeletingPathExtension];//获得文件名不带后缀
            NSString *extension = [imagePath pathExtension];//获得文件扩展类型
            imagePath = [[imageName stringByAppendingString:@"@2x"] stringByAppendingPathExtension:extension];//获得完整文件名
        }

        imagePath = [imagePath stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];//无损
        imageURL = [[NSURL alloc] initWithScheme:imageURL.scheme host:imageURL.host path:imagePath];

        if (imageURL == nil) {
            MixpanelError(@"invalid notif image URL: %@", imageURLString);
            return nil;
        }
    }

    NSArray *supportedOrientations = [[NSBundle mainBundle] infoDictionary][@"UISupportedInterfaceOrientations"];
    if (![supportedOrientations containsObject:@"UIInterfaceOrientationPortrait"] && [type isEqualToString:@"takeover"]) {//不是竖直状态
        MixpanelError(@"takeover notifications are not supported in landscape-only apps.");
        return nil;
    }

    return [[MPNotification alloc] initWithID:[ID unsignedIntegerValue]
                                    messageID:[messageID unsignedIntegerValue]
                                          type:type
                                         title:title
                                          body:body
                                           callToAction:callToAction
                                           callToActionURL:callToActionURL
                                      imageURL:imageURL];
}

- (instancetype)initWithID:(NSUInteger)ID messageID:(NSUInteger)messageID type:(NSString *)type title:(NSString *)title body:(NSString *)body callToAction:(NSString *)callToAction callToActionURL:(NSURL *)callToActionURL imageURL:(NSURL *)imageURL
{
    if (self = [super init]) {
        BOOL valid = YES;

        if (!(title && title.length > 0)) {
            valid = NO;
            MixpanelError(@"Notification title nil or empty: %@", title);
        }

        if (!(body && body.length > 0)) {
            valid = NO;
            MixpanelError(@"Notification body nil or empty: %@", body);
        }

        if (!([type isEqualToString:MPNotificationTypeTakeover] || [type isEqualToString:MPNotificationTypeMini])) {
            valid = NO;
            MixpanelError(@"Invalid notification type: %@, must be %@ or %@", type, MPNotificationTypeMini, MPNotificationTypeTakeover);
        }

        if (valid) {
            _ID = ID;
            _messageID = messageID;
            self.type = type;
            self.title = title;
            self.body = body;
            self.imageURL = imageURL;
            self.callToAction = callToAction;
            self.callToActionURL = callToActionURL;
            self.image = nil;
        } else {
            self = nil;
        }
    }

    return self;
}

- (NSData *)image
{
    if (_image == nil && _imageURL != nil) {
        NSError *error = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:_imageURL options:NSDataReadingMappedIfSafe error:&error];
        if (error || !imageData) {
            MixpanelError(@"image failed to load from URL: %@", _imageURL);
            return nil;
        }
        _image = imageData;
    }
    return _image;
}

@end

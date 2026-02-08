//
// © 2024-present https://github.com/cengiz-pz
//

#ifndef notification_data_h
#define notification_data_h

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

#include "core/object/class_db.h"

extern NSString * const NOTIFICATION_KEY_PREFIX;
extern NSString * const NOTIFICATION_SEQUENCE_DELIMITER;
extern NSString * const PENDING_NOTIFICATION_KEY;
extern NSString * const PENDING_ACTION_KEY;

@interface NotificationData : NSObject

@property (nonatomic, strong) NSString* notificationId;
@property (nonatomic, strong) NSString* channelId;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* content;
@property (nonatomic, strong) NSString* smallIconName;
@property (nonatomic) NSInteger delay;
@property (nonatomic, strong) NSString* deeplink;
@property (nonatomic) NSInteger interval;
@property (nonatomic) NSInteger badgeCount;
@property (nonatomic) BOOL restartApp;
@property (nonatomic, strong) NSDictionary* customData;
@property (nonatomic, strong) UNMutableNotificationContent* notificationContent;

- (instancetype) initWithGodotDictionary:(Dictionary) notificationData;
- (instancetype) initWithNsDictionary:(NSDictionary *) notificationData;
- (NSDictionary *) toNsDictionary;
- (Dictionary) toGodotDictionary;
- (NSString *) getKey;
- (NSString *)getIdWithSequence:(int) sequence;
- (BOOL) isSequenceOf:(NSString *) identifier;
- (void)isUNCPending:(void (^)(BOOL isPending))handler;
- (void)isUNCDelivered:(void (^)(BOOL isDelivered))handler;

+ (NSString *) toKey:(NSString *) identifier;
+ (NSString *) stripSequence:(NSString *) identifier;

@end

#endif /* notification_data_h */

//
// © 2024-present https://github.com/cengiz-pz
//

#import <UserNotifications/UserNotifications.h>

#import "notification_data.h"
#import "nsp_converter.h"

NSString *const NOTIFICATION_KEY_PREFIX = @"NSPNotification_";
NSString *const NOTIFICATION_SEQUENCE_DELIMITER = @"_NSPseq_";
NSString *const PENDING_NOTIFICATION_KEY = @"NSPPendingNotificationID";
NSString *const PENDING_ACTION_KEY = @"NSPPendingActionIdentifier";

static NSString *const NOTIFICATION_ID_KEY = @"notification_id";
static NSString *const NOTIFICATION_CHANNEL_ID_KEY = @"channel_id";
static NSString *const NOTIFICATION_TITLE_KEY = @"title";
static NSString *const NOTIFICATION_CONTENT_KEY = @"content";
static NSString *const NOTIFICATION_DELAY_KEY = @"delay";
static NSString *const NOTIFICATION_INTERVAL_KEY = @"interval";
static NSString *const NOTIFICATION_BADGE_COUNT_KEY = @"badge_count";
static NSString *const NOTIFICATION_SMALL_ICON_NAME_KEY = @"small_icon_name";
static NSString *const NOTIFICATION_BIG_PICTURE_NAME_KEY = @"big_picture_name";
static NSString *const NOTIFICATION_DEEPLINK_KEY = @"deeplink";
static NSString *const NOTIFICATION_CUSTOM_DATA_KEY = @"custom_data";

static NSString *const NOTIFICATION_RESTART_APP_KEY = @"restart_app";

static const String NOTIFICATION_ID_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_ID_KEY];
static const String NOTIFICATION_CHANNEL_ID_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_CHANNEL_ID_KEY];
static const String NOTIFICATION_TITLE_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_TITLE_KEY];
static const String NOTIFICATION_CONTENT_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_CONTENT_KEY];
static const String NOTIFICATION_DELAY_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_DELAY_KEY];
static const String NOTIFICATION_INTERVAL_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_INTERVAL_KEY];
static const String NOTIFICATION_BADGE_COUNT_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_BADGE_COUNT_KEY];
static const String NOTIFICATION_SMALL_ICON_NAME_PROPERTY =
		[NSPConverter toGodotString:NOTIFICATION_SMALL_ICON_NAME_KEY];
static const String NOTIFICATION_BIG_PICTURE_NAME_PROPERTY =
		[NSPConverter toGodotString:NOTIFICATION_BIG_PICTURE_NAME_KEY];
static const String NOTIFICATION_DEEPLINK_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_DEEPLINK_KEY];
static const String NOTIFICATION_CUSTOM_DATA_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_CUSTOM_DATA_KEY];
static const String NOTIFICATION_RESTART_APP_PROPERTY = [NSPConverter toGodotString:NOTIFICATION_RESTART_APP_KEY];

@interface NotificationData ()

+ (NSURL *)urlForImageResource:(NSString *)name;
- (UNNotificationAttachment *)createBigPictureAttachment;

@end

@implementation NotificationData

- (instancetype)initWithGodotDictionary:(Dictionary)notificationData {
	if ((self = [super init])) {
		self.notificationId = [[NSPConverter toNsNumber:notificationData[NOTIFICATION_ID_PROPERTY]] stringValue];
		self.channelId = [NSPConverter toNsString:(String)notificationData[NOTIFICATION_CHANNEL_ID_PROPERTY]];
		self.title = [NSPConverter toNsString:(String)notificationData[NOTIFICATION_TITLE_PROPERTY]];
		self.content = [NSPConverter toNsString:(String)notificationData[NOTIFICATION_CONTENT_PROPERTY]];
		self.smallIconName = [NSPConverter toNsString:(String)notificationData[NOTIFICATION_SMALL_ICON_NAME_PROPERTY]];
		if (notificationData.has(NOTIFICATION_DELAY_PROPERTY)) {
			self.delay = [NSPConverter toNsNumber:notificationData[NOTIFICATION_DELAY_PROPERTY]].integerValue;
		} else {
			self.delay = 0;
		}
		if (notificationData.has(NOTIFICATION_DEEPLINK_PROPERTY)) {
			self.deeplink = [NSPConverter toNsString:(String)notificationData[NOTIFICATION_DEEPLINK_PROPERTY]];
		}
		if (notificationData.has(NOTIFICATION_BIG_PICTURE_NAME_PROPERTY)) {
			self.bigPictureName =
					[NSPConverter toNsString:(String)notificationData[NOTIFICATION_BIG_PICTURE_NAME_PROPERTY]];
		}
		if (notificationData.has(NOTIFICATION_INTERVAL_PROPERTY)) {
			self.interval = [NSPConverter toNsNumber:notificationData[NOTIFICATION_INTERVAL_PROPERTY]].integerValue;
			// Ensure interval is valid
			if (self.interval > 0 && self.interval < 60) {
				NSLog(@"NotificationData: WARNING: Invalid interval %ld, setting to 0", (long)self.interval);
				self.interval = 0;
			}
		} else {
			self.interval = 0;
		}
		if (notificationData.has(NOTIFICATION_BADGE_COUNT_PROPERTY)) {
			self.badgeCount =
					[NSPConverter toNsNumber:notificationData[NOTIFICATION_BADGE_COUNT_PROPERTY]].integerValue;
		} else {
			self.badgeCount = 0;
		}
		if (notificationData.has(NOTIFICATION_CUSTOM_DATA_PROPERTY)) {
			self.customData = [NSPConverter toNsDictionary:notificationData[NOTIFICATION_CUSTOM_DATA_PROPERTY]];
		}
		if (notificationData.has(NOTIFICATION_RESTART_APP_PROPERTY)) {
			self.restartApp = YES;
		} else {
			self.restartApp = NO;
		}
		// Initialize UNMutableNotificationContent
		self.notificationContent = [[UNMutableNotificationContent alloc] init];
		self.notificationContent.title = self.title;
		self.notificationContent.body = self.content;
		self.notificationContent.categoryIdentifier = self.channelId;
		self.notificationContent.sound = [UNNotificationSound defaultSound];
		self.notificationContent.badge = @(self.badgeCount);

		if (self.bigPictureName.length > 0) {
			UNNotificationAttachment *attachment = [self createBigPictureAttachment];
			if (attachment) {
				self.notificationContent.attachments = @[ attachment ];
			}
		}
	}
	return self;
}

- (instancetype)initWithNsDictionary:(NSDictionary *)nsDict {
	if ((self = [super init])) {
		self.notificationId = nsDict[NOTIFICATION_ID_KEY];
		self.title = nsDict[NOTIFICATION_TITLE_KEY];
		self.content = nsDict[NOTIFICATION_CONTENT_KEY];
		self.channelId = nsDict[NOTIFICATION_CHANNEL_ID_KEY];
		self.delay = [nsDict[NOTIFICATION_DELAY_KEY] integerValue];
		self.interval = [nsDict[NOTIFICATION_INTERVAL_KEY] integerValue];
		self.badgeCount = [nsDict[NOTIFICATION_BADGE_COUNT_KEY] integerValue];
		self.deeplink = nsDict[NOTIFICATION_DEEPLINK_KEY];
		self.customData = nsDict[NOTIFICATION_CUSTOM_DATA_KEY];
		self.bigPictureName = nsDict[NOTIFICATION_BIG_PICTURE_NAME_KEY];
		// Unsupported fields
		self.smallIconName = nsDict[NOTIFICATION_SMALL_ICON_NAME_KEY];
		self.restartApp = nsDict[NOTIFICATION_RESTART_APP_KEY];
	}
	return self;
}

- (Dictionary)toGodotDictionary {
	Dictionary dict = Dictionary();

	dict[NOTIFICATION_ID_PROPERTY] = [self.notificationId intValue];
	if (self.channelId) {
		dict[NOTIFICATION_CHANNEL_ID_PROPERTY] = [NSPConverter toGodotString:self.channelId];
	}
	if (self.title) {
		dict[NOTIFICATION_TITLE_PROPERTY] = [NSPConverter toGodotString:self.title];
	}
	if (self.content) {
		dict[NOTIFICATION_CONTENT_PROPERTY] = [NSPConverter toGodotString:self.content];
	}
	if (self.delay != 0) {
		dict[NOTIFICATION_DELAY_PROPERTY] = (int)self.delay;
	}
	if (self.interval != 0) {
		dict[NOTIFICATION_INTERVAL_PROPERTY] = (int)self.interval;
	}
	if (self.badgeCount != 0) {
		dict[NOTIFICATION_BADGE_COUNT_PROPERTY] = (int)self.badgeCount;
	}
	if (self.deeplink) {
		dict[NOTIFICATION_DEEPLINK_PROPERTY] = [NSPConverter toGodotString:self.deeplink];
	}
	if (self.customData) {
		dict[NOTIFICATION_CUSTOM_DATA_PROPERTY] = [NSPConverter toGodotDictionary:self.customData];
	}
	if (self.bigPictureName) {
		dict[NOTIFICATION_BIG_PICTURE_NAME_PROPERTY] = [NSPConverter toGodotString:self.bigPictureName];
	}
	// Unsupported fields
	if (self.smallIconName) {
		dict[NOTIFICATION_SMALL_ICON_NAME_PROPERTY] = [NSPConverter toGodotString:self.smallIconName];
	}
	if (self.restartApp) {
		dict[NOTIFICATION_RESTART_APP_PROPERTY] = YES;
	}

	return dict;
}

- (NSDictionary *)toNsDictionary {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	dict[NOTIFICATION_ID_KEY] = self.notificationId;
	if (self.channelId) {
		dict[NOTIFICATION_CHANNEL_ID_KEY] = self.channelId;
	}
	if (self.title) {
		dict[NOTIFICATION_TITLE_KEY] = self.title;
	}
	if (self.content) {
		dict[NOTIFICATION_CONTENT_KEY] = self.content;
	}
	if (self.delay != 0) {
		dict[NOTIFICATION_DELAY_KEY] = @(self.delay);
	}
	if (self.interval != 0) {
		dict[NOTIFICATION_INTERVAL_KEY] = @(self.interval);
	}
	if (self.badgeCount != 0) {
		dict[NOTIFICATION_BADGE_COUNT_KEY] = @(self.badgeCount);
	}
	// Optional fields that were in the Godot init
	if (self.smallIconName) {
		dict[NOTIFICATION_SMALL_ICON_NAME_KEY] = self.smallIconName;
	}
	if (self.deeplink) {
		dict[NOTIFICATION_DEEPLINK_KEY] = self.deeplink;
	}
	if (self.customData) {
		dict[NOTIFICATION_CUSTOM_DATA_KEY] = self.customData;
	}
	if (self.bigPictureName) {
		dict[NOTIFICATION_BIG_PICTURE_NAME_KEY] = self.bigPictureName;
	}
	if (self.restartApp) {
		dict[NOTIFICATION_RESTART_APP_KEY] = @(YES);
	}

	return [dict copy];
}

- (NSString *)getKey {
	return [NSString stringWithFormat:@"%@%@", NOTIFICATION_KEY_PREFIX, self.notificationId];
}

- (NSString *)getIdWithSequence:(int)sequence {
	return [NSString stringWithFormat:@"%@%@%d", self.notificationId, NOTIFICATION_SEQUENCE_DELIMITER, sequence];
}

- (BOOL)isSequenceOf:(NSString *)identifier {
	return [[NotificationData stripSequence:identifier] compare:self.notificationId] == NSOrderedSame;
}

- (void)isUNCPending:(void (^)(BOOL isPending))handler {
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	[center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *_Nonnull requests) {
		BOOL found = NO;
		for (UNNotificationRequest *request in requests) {
			if ([request.identifier isEqualToString:self.notificationId]) {
				found = YES;
				break;
			}
		}
		if (handler) {
			handler(found);
		}
	}];
}

- (void)isUNCDelivered:(void (^)(BOOL isDelivered))handler {
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	[center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *_Nonnull notifications) {
		BOOL found = NO;
		for (UNNotification *notification in notifications) {
			if ([notification.request.identifier isEqualToString:self.notificationId]) {
				found = YES;
				break;
			}
		}
		if (handler) {
			handler(found);
		}
	}];
}

+ (NSString *)toKey:(NSString *)identifier {
	return [NSString stringWithFormat:@"%@%@", NOTIFICATION_KEY_PREFIX, identifier];
}

+ (NSString *)stripSequence:(NSString *)identifier {
	// Find the range of the substring
	NSRange range = [identifier rangeOfString:NOTIFICATION_SEQUENCE_DELIMITER];

	NSString *resultString = identifier;

	// If found, remove from substring to the end
	if (range.location != NSNotFound) {
		resultString = [identifier substringToIndex:range.location];
	}

	return resultString;
}

#pragma mark - Big picture

// Resolves a resource name (e.g. "my_big_picture" or "my_big_picture.png") to a bundled file
// URL. Names without an extension are matched against common image extensions.
+ (NSURL *)urlForImageResource:(NSString *)name {
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *path = nil;

	NSString *extension = [name pathExtension];
	if (extension.length > 0) {
		path = [bundle pathForResource:[name stringByDeletingPathExtension] ofType:extension];
	}

	if (!path) {
		for (NSString *candidateExtension in @[ @"png", @"jpg", @"jpeg", @"heic", @"gif" ]) {
			path = [bundle pathForResource:name ofType:candidateExtension];
			if (path) {
				break;
			}
		}
	}

	return path ? [NSURL fileURLWithPath:path] : nil;
}

// Builds a UNNotificationAttachment from `bigPictureName` so it's shown as an expanded image
// when the notification is presented (the closest iOS equivalent of Android's BigPictureStyle).
// Returns nil (and logs a warning) if the image can't be found or the attachment can't be
// created; the notification is still delivered without the image in that case.
- (UNNotificationAttachment *)createBigPictureAttachment {
	NSURL *imageUrl = [NotificationData urlForImageResource:self.bigPictureName];
	if (!imageUrl) {
		NSLog(@"NotificationData: WARNING: Could not find a bundled image named '%@' for big picture",
				self.bigPictureName);
		return nil;
	}

	// UNNotificationAttachment takes ownership of (and may move) the file at the given URL, so
	// copy the bundled (read-only) resource into a private, writable temporary location first.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *uniqueDirectory =
			[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];

	NSError *error = nil;
	if (![fileManager createDirectoryAtPath:uniqueDirectory
				withIntermediateDirectories:YES
								 attributes:nil
									  error:&error]) {
		NSLog(@"NotificationData: WARNING: Could not create temp directory for big picture attachment: %@",
				error.localizedDescription);
		return nil;
	}

	NSURL *destinationUrl =
			[NSURL fileURLWithPath:[uniqueDirectory stringByAppendingPathComponent:imageUrl.lastPathComponent]];

	error = nil;
	if (![fileManager copyItemAtURL:imageUrl toURL:destinationUrl error:&error]) {
		NSLog(@"NotificationData: WARNING: Could not copy big picture image '%@' for attachment: %@",
				self.bigPictureName, error.localizedDescription);
		return nil;
	}

	NSString *identifier = [NSString stringWithFormat:@"big_picture_%@", self.notificationId];
	error = nil;
	UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:identifier
																						  URL:destinationUrl
																					  options:nil
																						error:&error];
	if (!attachment) {
		NSLog(@"NotificationData: WARNING: Could not create attachment for big picture '%@': %@", self.bigPictureName,
				error.localizedDescription);
	}

	return attachment;
}

@end

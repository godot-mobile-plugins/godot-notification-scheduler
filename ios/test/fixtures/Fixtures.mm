//
// © 2024-present https://github.com/cengiz-pz
//

#import "Fixtures.h"

// ---------------------------------------------------------------------------
// Notification constants
// ---------------------------------------------------------------------------
NSString *const NSPFixtureNotificationId  = @"42";
NSString *const NSPFixtureChannelId       = @"test_channel";
NSString *const NSPFixtureTitle           = @"Test Notification Title";
NSString *const NSPFixtureContent         = @"Test notification body text.";
NSString *const NSPFixtureSmallIconName   = @"ic_notification";
NSString *const NSPFixtureDeeplink        = @"myapp://screen/home";
const NSInteger NSPFixtureDelay           = 30;
const NSInteger NSPFixtureInterval        = 3600; // 1 hour — well above the 60 s minimum
const NSInteger NSPFixtureBadgeCount      = 5;

// ---------------------------------------------------------------------------
// Channel constants
// ---------------------------------------------------------------------------
NSString *const NSPFixtureChannelName        = @"Test Channel";
NSString *const NSPFixtureChannelDescription = @"A test notification channel.";
const NSInteger NSPFixtureChannelImportance  = 3;

// ---------------------------------------------------------------------------
// Factory implementations
// ---------------------------------------------------------------------------
@implementation NSPTestFixtures

+ (NSDictionary *)fullNotificationNsDictionary {
	return @{
		@"notification_id":  NSPFixtureNotificationId,
		@"channel_id":       NSPFixtureChannelId,
		@"title":            NSPFixtureTitle,
		@"content":          NSPFixtureContent,
		@"small_icon_name":  NSPFixtureSmallIconName,
		@"delay":            @(NSPFixtureDelay),
		@"interval":         @(NSPFixtureInterval),
		@"badge_count":      @(NSPFixtureBadgeCount),
		@"deeplink":         NSPFixtureDeeplink,
	};
}

+ (NSDictionary *)minimalNotificationNsDictionary {
	return @{
		@"notification_id":  NSPFixtureNotificationId,
		@"channel_id":       NSPFixtureChannelId,
		@"title":            NSPFixtureTitle,
		@"content":          NSPFixtureContent,
		@"small_icon_name":  NSPFixtureSmallIconName,
	};
}

+ (NSDictionary *)notificationWithCustomDataNsDictionary {
	return @{
		@"notification_id": NSPFixtureNotificationId,
		@"channel_id":      NSPFixtureChannelId,
		@"title":           NSPFixtureTitle,
		@"content":         NSPFixtureContent,
		@"small_icon_name": NSPFixtureSmallIconName,
		@"custom_data": @{
			@"campaign_id": @"summer_sale",
			@"promo_code":  @"SAVE20",
			@"version":     @(7),
		},
	};
}

+ (NSDictionary *)notificationWithRestartAppNsDictionary {
	return @{
		@"notification_id": NSPFixtureNotificationId,
		@"channel_id":      NSPFixtureChannelId,
		@"title":           NSPFixtureTitle,
		@"content":         NSPFixtureContent,
		@"small_icon_name": NSPFixtureSmallIconName,
		@"restart_app":     @(YES),
	};
}

+ (NSDictionary *)fullChannelNsDictionary {
	return @{
		@"channel_id":          NSPFixtureChannelId,
		@"channel_name":        NSPFixtureChannelName,
		@"channel_description": NSPFixtureChannelDescription,
		@"channel_importance":  @(NSPFixtureChannelImportance),
	};
}

+ (NSDictionary *)minimalChannelNsDictionary {
	return @{
		@"channel_id":   NSPFixtureChannelId,
		@"channel_name": NSPFixtureChannelName,
	};
}

@end

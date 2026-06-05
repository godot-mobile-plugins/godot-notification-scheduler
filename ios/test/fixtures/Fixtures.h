//
// © 2024-present https://github.com/cengiz-pz
//
// NSPTestFixtures
// Shared test constants and NSDictionary factory methods used across all
// iOS Notification Scheduler Plugin unit tests.
//
// All NSDictionary factories produce the same key/value layout that Godot
// GDScript would pass across the plugin boundary, letting every test start
// from a known, correct state without duplicating fixture setup inline.
//

#pragma once
#import <Foundation/Foundation.h>

// ---------------------------------------------------------------------------
// Notification fixture values (extern so every .mm file shares one copy)
// ---------------------------------------------------------------------------
extern NSString *const NSPFixtureNotificationId;       ///< @"42"
extern NSString *const NSPFixtureChannelId;            ///< @"test_channel"
extern NSString *const NSPFixtureTitle;                ///< @"Test Notification Title"
extern NSString *const NSPFixtureContent;              ///< @"Test notification body text."
extern NSString *const NSPFixtureSmallIconName;        ///< @"ic_notification"
extern NSString *const NSPFixtureDeeplink;             ///< @"myapp://screen/home"
extern const NSInteger NSPFixtureDelay;                ///< 30   (seconds)
extern const NSInteger NSPFixtureInterval;             ///< 3600 (seconds; >= 60 — valid repeating)
extern const NSInteger NSPFixtureBadgeCount;           ///< 5

// ---------------------------------------------------------------------------
// Channel fixture values
// ---------------------------------------------------------------------------
extern NSString *const NSPFixtureChannelName;          ///< @"Test Channel"
extern NSString *const NSPFixtureChannelDescription;   ///< @"A test notification channel."
extern const NSInteger NSPFixtureChannelImportance;    ///< 3

// ---------------------------------------------------------------------------
// NSPTestFixtures factory class
// ---------------------------------------------------------------------------

/// Provides pre-built NSDictionary instances matching what Godot GDScript
/// passes over the plugin boundary. Use these to drive -initWithNsDictionary:
/// and to build expected round-trip results.
@interface NSPTestFixtures : NSObject

/// Fully populated notification dictionary — all optional fields present
/// (delay, interval, badge_count, deeplink, small_icon_name).
+ (NSDictionary *)fullNotificationNsDictionary;

/// Minimal notification dictionary — required fields only;
/// delay/interval/badge_count/deeplink are absent.
+ (NSDictionary *)minimalNotificationNsDictionary;

/// Notification dictionary carrying a nested custom_data payload.
+ (NSDictionary *)notificationWithCustomDataNsDictionary;

/// Notification dictionary with restart_app set to YES.
+ (NSDictionary *)notificationWithRestartAppNsDictionary;

/// Fully populated channel dictionary — all optional fields present
/// (channel_description, channel_importance).
+ (NSDictionary *)fullChannelNsDictionary;

/// Minimal channel dictionary — channel_id + channel_name only.
+ (NSDictionary *)minimalChannelNsDictionary;

@end

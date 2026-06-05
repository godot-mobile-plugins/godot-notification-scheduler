//
// © 2024-present https://github.com/cengiz-pz
//
// NotificationDataTests
//
// Covers the full public surface of NotificationData:
//
//   -initWithNsDictionary:       — field mapping from NSDictionary
//   -initWithGodotDictionary:    — field mapping from Godot Dictionary,
//                                  interval coercion, UNMutableNotificationContent setup
//   -toNsDictionary              — serialisation; omission of zero-valued fields
//   -toGodotDictionary           — serialisation to Godot Dictionary
//   -getKey                      — NSPNotification_<id> format
//   -getIdWithSequence:          — <id>_NSPseq_<n> format
//   -isSequenceOf:               — prefix-match logic
//   +toKey:                      — class-level key construction
//   +stripSequence:              — sequence-suffix removal
//   -isUNCPending:               — async check against UNUserNotificationCenter
//   -isUNCDelivered:             — async check against UNUserNotificationCenter
//

#import <XCTest/XCTest.h>

// Godot core types — transitively available via class_db.h
#include "core/object/class_db.h"

#import "notification_data.h"
#import "nsp_converter.h"
#import "Fixtures.h"

// ---------------------------------------------------------------------------
// Internal helper — minimal Godot Dictionary for -initWithGodotDictionary: tests.
// Only required fields are populated; callers add optional fields as needed.
// ---------------------------------------------------------------------------
static Dictionary makeMinimalGodotNotifDict(int notifId) {
	Dictionary d;
	d[String("notification_id")] = Variant(notifId);
	d[String("channel_id")]      = Variant(String("test_channel"));
	d[String("title")]           = Variant(String("Fixture Title"));
	d[String("content")]         = Variant(String("Fixture Body"));
	d[String("small_icon_name")] = Variant(String("ic_stat_notify"));
	return d;
}

@interface NotificationDataTests : XCTestCase
@end

@implementation NotificationDataTests

// ===========================================================================
#pragma mark - initWithNsDictionary: — full fixture
// ===========================================================================

- (void)test_initWithNsDictionary_setsNotificationId {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects(sut.notificationId, NSPFixtureNotificationId);
}

- (void)test_initWithNsDictionary_setsChannelId {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects(sut.channelId, NSPFixtureChannelId);
}

- (void)test_initWithNsDictionary_setsTitle {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects(sut.title, NSPFixtureTitle);
}

- (void)test_initWithNsDictionary_setsContent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects(sut.content, NSPFixtureContent);
}

- (void)test_initWithNsDictionary_setsDelay {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqual(sut.delay, NSPFixtureDelay);
}

- (void)test_initWithNsDictionary_setsInterval {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqual(sut.interval, NSPFixtureInterval);
}

- (void)test_initWithNsDictionary_setsBadgeCount {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqual(sut.badgeCount, NSPFixtureBadgeCount);
}

- (void)test_initWithNsDictionary_setsDeeplink {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects(sut.deeplink, NSPFixtureDeeplink);
}

- (void)test_initWithNsDictionary_setsSmallIconName {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects(sut.smallIconName, NSPFixtureSmallIconName);
}

// ===========================================================================
#pragma mark - initWithNsDictionary: — optional fields
// ===========================================================================

- (void)test_initWithNsDictionary_setsCustomData {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures notificationWithCustomDataNsDictionary]];
	XCTAssertNotNil(sut.customData);
	XCTAssertEqualObjects(sut.customData[@"campaign_id"], @"summer_sale");
	XCTAssertEqualObjects(sut.customData[@"promo_code"],  @"SAVE20");
}

- (void)test_initWithNsDictionary_setsRestartApp_whenPresent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures notificationWithRestartAppNsDictionary]];
	XCTAssertTrue(sut.restartApp);
}

// ===========================================================================
#pragma mark - initWithNsDictionary: — absent optional fields default correctly
// ===========================================================================

- (void)test_initWithNsDictionary_delayDefaultsToZero_whenAbsent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertEqual(sut.delay, 0);
}

- (void)test_initWithNsDictionary_intervalDefaultsToZero_whenAbsent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertEqual(sut.interval, 0);
}

- (void)test_initWithNsDictionary_badgeCountDefaultsToZero_whenAbsent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertEqual(sut.badgeCount, 0);
}

- (void)test_initWithNsDictionary_restartAppDefaultsToFalse_whenAbsent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertFalse(sut.restartApp);
}

- (void)test_initWithNsDictionary_customDataIsNil_whenAbsent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertNil(sut.customData);
}

- (void)test_initWithNsDictionary_deeplinkIsNil_whenAbsent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertNil(sut.deeplink);
}

// ===========================================================================
#pragma mark - toNsDictionary — serialisation
// ===========================================================================

- (void)test_toNsDictionary_includesNotificationId {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects([sut toNsDictionary][@"notification_id"], NSPFixtureNotificationId);
}

- (void)test_toNsDictionary_includesChannelId {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects([sut toNsDictionary][@"channel_id"], NSPFixtureChannelId);
}

- (void)test_toNsDictionary_includesTitle {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects([sut toNsDictionary][@"title"], NSPFixtureTitle);
}

- (void)test_toNsDictionary_includesContent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects([sut toNsDictionary][@"content"], NSPFixtureContent);
}

- (void)test_toNsDictionary_includesDelay_whenNonZero {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects([sut toNsDictionary][@"delay"], @(NSPFixtureDelay));
}

- (void)test_toNsDictionary_omitsDelay_whenZero {
	// A zero delay has no meaning on iOS (it is treated as "now"); the impl
	// omits it from the serialised dictionary to keep the payload minimal.
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertNil([sut toNsDictionary][@"delay"]);
}

- (void)test_toNsDictionary_includesInterval_whenNonZero {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects([sut toNsDictionary][@"interval"], @(NSPFixtureInterval));
}

- (void)test_toNsDictionary_omitsInterval_whenZero {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertNil([sut toNsDictionary][@"interval"]);
}

- (void)test_toNsDictionary_includesBadgeCount_whenNonZero {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects([sut toNsDictionary][@"badge_count"], @(NSPFixtureBadgeCount));
}

- (void)test_toNsDictionary_omitsBadgeCount_whenZero {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertNil([sut toNsDictionary][@"badge_count"]);
}

- (void)test_toNsDictionary_includesDeeplink_whenPresent {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures fullNotificationNsDictionary]];
	XCTAssertEqualObjects([sut toNsDictionary][@"deeplink"], NSPFixtureDeeplink);
}

- (void)test_toNsDictionary_includesCustomData {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures notificationWithCustomDataNsDictionary]];
	NSDictionary *custom = [sut toNsDictionary][@"custom_data"];
	XCTAssertNotNil(custom);
	XCTAssertEqualObjects(custom[@"campaign_id"], @"summer_sale");
	XCTAssertEqualObjects(custom[@"promo_code"],  @"SAVE20");
}

- (void)test_toNsDictionary_fullRoundTrip_preservesEveryField {
	NSDictionary *input   = [NSPTestFixtures fullNotificationNsDictionary];
	NotificationData *sut = [[NotificationData alloc] initWithNsDictionary:input];
	NSDictionary *output  = [sut toNsDictionary];

	for (NSString *key in input) {
		XCTAssertEqualObjects(output[key], input[key],
				@"Round-trip mismatch for key '%@': expected %@ got %@",
				key, input[key], output[key]);
	}
}

// ===========================================================================
#pragma mark - getKey
// ===========================================================================

- (void)test_getKey_hasNotificationKeyPrefixFormat {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	NSString *expected = [NSString stringWithFormat:@"NSPNotification_%@", NSPFixtureNotificationId];
	XCTAssertEqualObjects(sut.getKey, expected);
}

- (void)test_getKey_usesStringFormOfId {
	// Verifies the key is formed from the raw string ID stored in notificationId,
	// not by converting notificationId's integer value back to a string.
	NSDictionary *dict = @{
		@"notification_id": @"007",
		@"channel_id": @"c", @"title": @"T", @"content": @"B"
	};
	NotificationData *sut = [[NotificationData alloc] initWithNsDictionary:dict];
	XCTAssertEqualObjects(sut.getKey, @"NSPNotification_007");
}

// ===========================================================================
#pragma mark - getIdWithSequence:
// ===========================================================================

- (void)test_getIdWithSequence_appendsDelimiterAndIndex {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	NSString *expected = [NSString stringWithFormat:@"%@_NSPseq_3", NSPFixtureNotificationId];
	XCTAssertEqualObjects([sut getIdWithSequence:3], expected);
}

- (void)test_getIdWithSequence_atIndexZero_appendsZero {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	NSString *expected = [NSString stringWithFormat:@"%@_NSPseq_0", NSPFixtureNotificationId];
	XCTAssertEqualObjects([sut getIdWithSequence:0], expected);
}

- (void)test_getIdWithSequence_atCount63_matchesScheduleRepeatingUpperBound {
	// schedule_repeating_sequence schedules 64 items (indices 0–63); verify
	// the last index is formatted correctly.
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	NSString *expected = [NSString stringWithFormat:@"%@_NSPseq_63", NSPFixtureNotificationId];
	XCTAssertEqualObjects([sut getIdWithSequence:63], expected);
}

// ===========================================================================
#pragma mark - isSequenceOf:
// ===========================================================================

- (void)test_isSequenceOf_withMatchingSequenceIdentifier_returnsYES {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	NSString *seqId = [sut getIdWithSequence:5];
	XCTAssertTrue([sut isSequenceOf:seqId]);
}

- (void)test_isSequenceOf_withBareMatchingId_returnsYES {
	// A bare (non-sequenced) identifier that equals the notification's own ID
	// must also be considered a match.
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertTrue([sut isSequenceOf:NSPFixtureNotificationId]);
}

- (void)test_isSequenceOf_withDifferentSequencedId_returnsNO {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertFalse([sut isSequenceOf:@"999_NSPseq_0"]);
}

- (void)test_isSequenceOf_withDifferentBareId_returnsNO {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertFalse([sut isSequenceOf:@"9999"]);
}

- (void)test_isSequenceOf_withEmptyString_returnsNO {
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertFalse([sut isSequenceOf:@""]);
}

// ===========================================================================
#pragma mark - toKey: (class method)
// ===========================================================================

- (void)test_toKey_classMethod_prependsNotificationKeyPrefix {
	XCTAssertEqualObjects([NotificationData toKey:@"7"], @"NSPNotification_7");
}

- (void)test_toKey_classMethod_withFixtureId_matchesInstanceGetKey {
	// +toKey: and -getKey must produce identical strings for the same base ID
	// since the plugin uses both to locate cached data.
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	XCTAssertEqualObjects([NotificationData toKey:NSPFixtureNotificationId], sut.getKey);
}

- (void)test_toKey_classMethod_withDifferentIds_producesDifferentKeys {
	XCTAssertNotEqualObjects([NotificationData toKey:@"1"], [NotificationData toKey:@"2"]);
}

// ===========================================================================
#pragma mark - stripSequence: (class method)
// ===========================================================================

- (void)test_stripSequence_withSequenceSuffix_removesFromFirstDelimiter {
	XCTAssertEqualObjects([NotificationData stripSequence:@"42_NSPseq_3"], @"42");
}

- (void)test_stripSequence_withoutSequenceSuffix_returnsIdentifierUnchanged {
	XCTAssertEqualObjects([NotificationData stripSequence:@"42"], @"42");
}

- (void)test_stripSequence_withDoubleSequence_stripsFromFirstOccurrence {
	// rangeOfString: finds the FIRST delimiter; everything from there is stripped.
	XCTAssertEqualObjects([NotificationData stripSequence:@"42_NSPseq_3_NSPseq_5"], @"42");
}

- (void)test_stripSequence_withEmptyString_returnsEmptyString {
	XCTAssertEqualObjects([NotificationData stripSequence:@""], @"");
}

- (void)test_stripSequence_sequenceZeroIndex_stripsCorrectly {
	XCTAssertEqualObjects([NotificationData stripSequence:@"42_NSPseq_0"], @"42");
}

- (void)test_stripSequence_roundTrip_strippedIdMatchesOriginalId {
	// Stripping the sequenced form produced by getIdWithSequence: must give back
	// the original notification ID so handle_completion can locate cached data.
	NotificationData *sut = [[NotificationData alloc]
			initWithNsDictionary:[NSPTestFixtures minimalNotificationNsDictionary]];
	NSString *sequenced = [sut getIdWithSequence:7];
	NSString *stripped  = [NotificationData stripSequence:sequenced];
	XCTAssertEqualObjects(stripped, NSPFixtureNotificationId);
}

// ===========================================================================
#pragma mark - initWithGodotDictionary: — interval coercion
// iOS requires a minimum repeat interval of 60 s.  Any value in (0, 60) must
// be coerced to 0 (non-repeating) with a warning log.
// ===========================================================================

- (void)test_initWithGodotDictionary_intervalBelowMinimum_isCoercedToZero {
	Dictionary d = makeMinimalGodotNotifDict(1);
	d[String("interval")] = Variant(30); // 0 < 30 < 60 → invalid; must become 0
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqual(sut.interval, 0,
			@"Interval 1–59 must be coerced to 0 (iOS minimum repeating interval is 60 s)");
}

- (void)test_initWithGodotDictionary_intervalAtMinimum60_isPreserved {
	Dictionary d = makeMinimalGodotNotifDict(2);
	d[String("interval")] = Variant(60); // exactly at the limit → kept
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqual(sut.interval, 60);
}

- (void)test_initWithGodotDictionary_intervalAboveMinimum_isPreserved {
	Dictionary d = makeMinimalGodotNotifDict(3);
	d[String("interval")] = Variant(3600);
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqual(sut.interval, 3600);
}

- (void)test_initWithGodotDictionary_intervalZero_isNotCoerced {
	// Zero means one-shot (non-repeating); the condition is > 0 AND < 60,
	// so 0 must pass through unchanged.
	Dictionary d = makeMinimalGodotNotifDict(4);
	d[String("interval")] = Variant(0);
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqual(sut.interval, 0);
}

- (void)test_initWithGodotDictionary_intervalAbsent_defaultsToZero {
	Dictionary d = makeMinimalGodotNotifDict(5);
	// No interval key added.
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqual(sut.interval, 0);
}

- (void)test_initWithGodotDictionary_intervalOfOne_isCoercedToZero {
	Dictionary d = makeMinimalGodotNotifDict(6);
	d[String("interval")] = Variant(1); // minimum invalid value
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqual(sut.interval, 0);
}

- (void)test_initWithGodotDictionary_intervalOf59_isCoercedToZero {
	Dictionary d = makeMinimalGodotNotifDict(7);
	d[String("interval")] = Variant(59); // maximum invalid value
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqual(sut.interval, 0);
}

// ===========================================================================
#pragma mark - initWithGodotDictionary: — UNMutableNotificationContent population
// ===========================================================================

- (void)test_initWithGodotDictionary_populatesNotificationContentTitle {
	Dictionary d = makeMinimalGodotNotifDict(10);
	d[String("title")]   = Variant(String("My Alert Title"));
	d[String("content")] = Variant(String("My Alert Body"));
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];

	XCTAssertNotNil(sut.notificationContent);
	XCTAssertEqualObjects(sut.notificationContent.title, @"My Alert Title");
}

- (void)test_initWithGodotDictionary_populatesNotificationContentBody {
	Dictionary d = makeMinimalGodotNotifDict(11);
	d[String("content")] = Variant(String("Body text here"));
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];

	XCTAssertEqualObjects(sut.notificationContent.body, @"Body text here");
}

- (void)test_initWithGodotDictionary_populatesNotificationContentCategoryIdentifier {
	Dictionary d = makeMinimalGodotNotifDict(12);
	d[String("channel_id")] = Variant(String("promo_channel"));
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];

	XCTAssertEqualObjects(sut.notificationContent.categoryIdentifier, @"promo_channel");
}

- (void)test_initWithGodotDictionary_populatesNotificationContentBadge {
	Dictionary d = makeMinimalGodotNotifDict(13);
	d[String("badge_count")] = Variant(4);
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];

	XCTAssertEqualObjects(sut.notificationContent.badge, @(4));
}

- (void)test_initWithGodotDictionary_notificationContentHasDefaultSound {
	Dictionary d = makeMinimalGodotNotifDict(14);
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	// The impl always assigns [UNNotificationSound defaultSound].
	XCTAssertNotNil(sut.notificationContent.sound);
}

// ===========================================================================
#pragma mark - initWithGodotDictionary: — optional field mapping
// ===========================================================================

- (void)test_initWithGodotDictionary_setsDeeplink_whenPresent {
	Dictionary d = makeMinimalGodotNotifDict(20);
	d[String("deeplink")] = Variant(String("myapp://home"));
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqualObjects(sut.deeplink, @"myapp://home");
}

- (void)test_initWithGodotDictionary_deeplinkIsNil_whenAbsent {
	Dictionary d = makeMinimalGodotNotifDict(21);
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertNil(sut.deeplink);
}

- (void)test_initWithGodotDictionary_setsCustomData_whenPresent {
	Dictionary custom;
	custom[String("source")] = Variant(String("push"));
	Dictionary d = makeMinimalGodotNotifDict(22);
	d[String("custom_data")] = Variant(custom);
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertNotNil(sut.customData);
}

- (void)test_initWithGodotDictionary_notificationIdIsStringOfInt {
	// The Godot side passes notification_id as an INT; the impl converts it via
	// -[NSNumber stringValue], so sut.notificationId must be the decimal string.
	Dictionary d = makeMinimalGodotNotifDict(99);
	NotificationData *sut = [[NotificationData alloc] initWithGodotDictionary:d];
	XCTAssertEqualObjects(sut.notificationId, @"99");
}

// ===========================================================================
#pragma mark - isUNCPending: (async)
// ===========================================================================

- (void)test_isUNCPending_withFreshId_returnsFalse {
	// UNUserNotificationCenter.getPendingNotificationRequestsWithCompletionHandler:
	// requires UserNotifications entitlements and an active UIApplication
	// notification session.  On iOS 26, unit-test worker processes lack both,
	// causing SIGABRT when currentNotificationCenter is accessed.
	// Move this assertion to an integration test that runs inside the full
	// Godot app host where entitlements and the notification session are present.
	XCTSkip(@"Requires UserNotifications entitlements — run as integration test");
}

// ===========================================================================
#pragma mark - isUNCDelivered: (async)
// ===========================================================================

- (void)test_isUNCDelivered_withFreshId_returnsFalse {
	// Same constraint as isUNCPending: getDeliveredNotificationsWithCompletionHandler:
	// requires UserNotifications entitlements unavailable in unit-test workers.
	XCTSkip(@"Requires UserNotifications entitlements — run as integration test");
}

@end

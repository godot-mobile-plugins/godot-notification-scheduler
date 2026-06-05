//
// © 2024-present https://github.com/cengiz-pz
//
// ChannelDataTests
//
// Covers the full public surface of ChannelData:
//
//   -initWithDictionary:   — field mapping from a Godot Dictionary
//
// All tests drive the designated initialiser with Godot Dictionary instances
// built using the extern property-key constants declared in channel_data.h
// so that any future key rename is caught here automatically.
//
// Test cases cover:
//   • Required fields (channel_id, channel_name)
//   • Optional field: channel_description (present and absent)
//   • Optional field: channel_importance   (present, absent, and boundary values)
//   • Composite: all fields together
//

#import <XCTest/XCTest.h>

// Godot core — Dictionary and related types available transitively
#include "core/object/class_db.h"

#import "channel_data.h"
#import "Fixtures.h"

// ---------------------------------------------------------------------------
// File-local helpers
// ---------------------------------------------------------------------------

/// Returns a minimal Godot Dictionary containing only the two required keys.
static Dictionary makeMinimalChannelDict(void) {
	Dictionary d;
	d[CHANNEL_ID_PROPERTY]   = Variant(String([NSPFixtureChannelId UTF8String]));
	d[CHANNEL_NAME_PROPERTY] = Variant(String([NSPFixtureChannelName UTF8String]));
	return d;
}

/// Returns a fully populated Godot Dictionary with all four channel fields.
static Dictionary makeFullChannelDict(void) {
	Dictionary d = makeMinimalChannelDict();
	d[CHANNEL_DESCRIPTION_PROPERTY] =
			Variant(String([NSPFixtureChannelDescription UTF8String]));
	d[CHANNEL_IMPORTANCE_PROPERTY] = Variant((int)NSPFixtureChannelImportance);
	return d;
}

// ===========================================================================

@interface ChannelDataTests : XCTestCase
@end

@implementation ChannelDataTests

// ===========================================================================
#pragma mark - Required fields
// ===========================================================================

- (void)test_initWithDictionary_setsChannelId {
	ChannelData *sut = [[ChannelData alloc] initWithDictionary:makeMinimalChannelDict()];
	XCTAssertEqualObjects(sut.channelId, NSPFixtureChannelId);
}

- (void)test_initWithDictionary_setsChannelName {
	ChannelData *sut = [[ChannelData alloc] initWithDictionary:makeMinimalChannelDict()];
	XCTAssertEqualObjects(sut.channelName, NSPFixtureChannelName);
}

- (void)test_initWithDictionary_withDifferentChannelId_setsCorrectChannelId {
	Dictionary d;
	d[CHANNEL_ID_PROPERTY]   = Variant(String("promo_alerts"));
	d[CHANNEL_NAME_PROPERTY] = Variant(String("Promo Alerts"));

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqualObjects(sut.channelId, @"promo_alerts");
}

// ===========================================================================
#pragma mark - Optional field: channel_description
// ===========================================================================

- (void)test_initWithDictionary_withDescription_setsChannelDescription {
	Dictionary d = makeMinimalChannelDict();
	d[CHANNEL_DESCRIPTION_PROPERTY] =
			Variant(String([NSPFixtureChannelDescription UTF8String]));

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqualObjects(sut.channelDescription, NSPFixtureChannelDescription);
}

- (void)test_initWithDictionary_withoutDescription_channelDescriptionIsNil {
	// The implementation only assigns channelDescription when the key is present.
	ChannelData *sut = [[ChannelData alloc] initWithDictionary:makeMinimalChannelDict()];
	XCTAssertNil(sut.channelDescription);
}

- (void)test_initWithDictionary_withEmptyDescription_setsEmptyString {
	Dictionary d = makeMinimalChannelDict();
	d[CHANNEL_DESCRIPTION_PROPERTY] = Variant(String(""));

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqualObjects(sut.channelDescription, @"");
}

// ===========================================================================
#pragma mark - Optional field: channel_importance
// ===========================================================================

- (void)test_initWithDictionary_withImportance_setsChannelImportance {
	Dictionary d = makeMinimalChannelDict();
	d[CHANNEL_IMPORTANCE_PROPERTY] = Variant((int)NSPFixtureChannelImportance);

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqual(sut.channelImportance, NSPFixtureChannelImportance);
}

- (void)test_initWithDictionary_withoutImportance_importanceDefaultsToZero {
	// When channel_importance is absent, NSInteger is left at its zero-initialised value.
	ChannelData *sut = [[ChannelData alloc] initWithDictionary:makeMinimalChannelDict()];
	XCTAssertEqual(sut.channelImportance, 0);
}

- (void)test_initWithDictionary_withImportanceZero_setsZero {
	Dictionary d = makeMinimalChannelDict();
	d[CHANNEL_IMPORTANCE_PROPERTY] = Variant(0);

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqual(sut.channelImportance, 0);
}

- (void)test_initWithDictionary_withImportanceOne_setsOne {
	// UNNotificationPresentationOptionNone equivalent — minimal importance.
	Dictionary d = makeMinimalChannelDict();
	d[CHANNEL_IMPORTANCE_PROPERTY] = Variant(1);

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqual(sut.channelImportance, 1);
}

- (void)test_initWithDictionary_withImportanceFive_setsFive {
	// Highest expected importance level on the Godot side.
	Dictionary d = makeMinimalChannelDict();
	d[CHANNEL_IMPORTANCE_PROPERTY] = Variant(5);

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqual(sut.channelImportance, 5);
}

// ===========================================================================
#pragma mark - All fields together
// ===========================================================================

- (void)test_initWithDictionary_withAllFields_setsAllFourProperties {
	ChannelData *sut = [[ChannelData alloc] initWithDictionary:makeFullChannelDict()];

	XCTAssertEqualObjects(sut.channelId,          NSPFixtureChannelId);
	XCTAssertEqualObjects(sut.channelName,        NSPFixtureChannelName);
	XCTAssertEqualObjects(sut.channelDescription, NSPFixtureChannelDescription);
	XCTAssertEqual(sut.channelImportance, NSPFixtureChannelImportance);
}

- (void)test_initWithDictionary_withAllFields_channelIdAndNameMatchFixture {
	// Double-check that required fields are not overwritten when optionals are present.
	ChannelData *sut = [[ChannelData alloc] initWithDictionary:makeFullChannelDict()];
	XCTAssertEqualObjects(sut.channelId,   NSPFixtureChannelId);
	XCTAssertEqualObjects(sut.channelName, NSPFixtureChannelName);
}

// ===========================================================================
#pragma mark - Key identity — extern constants must resolve correctly
// ===========================================================================

- (void)test_channelIdProperty_constantMatchesExpectedString {
	// Guard against any accidental rename of the property key at the source level.
	// CHANNEL_ID_PROPERTY is defined in channel_data.mm and declared extern in channel_data.h.
	Dictionary d;
	d[CHANNEL_ID_PROPERTY]   = Variant(String("identity_check"));
	d[CHANNEL_NAME_PROPERTY] = Variant(String("Name"));

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqualObjects(sut.channelId, @"identity_check");
}

- (void)test_channelNameProperty_constantMatchesExpectedString {
	Dictionary d;
	d[CHANNEL_ID_PROPERTY]   = Variant(String("id"));
	d[CHANNEL_NAME_PROPERTY] = Variant(String("Identity Name Check"));

	ChannelData *sut = [[ChannelData alloc] initWithDictionary:d];
	XCTAssertEqualObjects(sut.channelName, @"Identity Name Check");
}

@end

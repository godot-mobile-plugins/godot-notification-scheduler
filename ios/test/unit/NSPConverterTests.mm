//
// © 2024-present https://github.com/cengiz-pz
//
// NSPConverterTests
//
// Covers every public method of NSPConverter:
//   + toNsString:           String   → NSString
//   + toNsNumber:           Variant  → NSNumber  (INT / FLOAT / BOOL)
//   + toNsDictionary:       Dictionary → NSDictionary
//   + toGodotString:        NSString → String
//   + toGodotDictionary:    NSDictionary → Dictionary
//   + nsUrlToGodotDictionary: NSURL  → Dictionary
//
// All Godot types (String, Variant, Dictionary) are created directly without
// requiring a running Godot engine — they are standalone C++ value types that
// live entirely on the stack/heap.
//

#import <XCTest/XCTest.h>

// Godot core — pulled in transitively through class_db.h → object.h → variant.h
#include "core/object/class_db.h"

#import "nsp_converter.h"

@interface NSPConverterTests : XCTestCase
@end

@implementation NSPConverterTests

// ===========================================================================
#pragma mark - toNsString:
// ===========================================================================

- (void)test_toNsString_withASCIIInput_returnsEqualNSString {
	NSString *result = [NSPConverter toNsString:String("hello world")];
	XCTAssertEqualObjects(result, @"hello world");
}

- (void)test_toNsString_withEmptyInput_returnsEmptyNSString {
	NSString *result = [NSPConverter toNsString:String()];
	XCTAssertEqualObjects(result, @"");
}

- (void)test_toNsString_withUnicodeInput_preservesCharacters {
	// String(const char*) copies each byte as a raw char32_t; use String::utf8()
	// which parses the multibyte sequences into the correct Unicode codepoints.
	NSString *result = [NSPConverter toNsString:String::utf8("こんにちは")];
	XCTAssertEqualObjects(result, @"こんにちは");
}

- (void)test_toNsString_withSpecialCharacters_preservesAll {
	NSString *result = [NSPConverter toNsString:String("Hello & <World> \"quoted\" 'single'")];
	XCTAssertEqualObjects(result, @"Hello & <World> \"quoted\" 'single'");
}

- (void)test_toNsString_withDeeplinkUrl_preservesUrlIntact {
	// Deeplinks are a primary value the plugin serialises; ensure nothing is escaped.
	NSString *result = [NSPConverter toNsString:String("myapp://screen/detail?id=42&ref=push")];
	XCTAssertEqualObjects(result, @"myapp://screen/detail?id=42&ref=push");
}

- (void)test_toNsString_withEmojiCharacters_preservesContent {
	// Emoji are 4-byte UTF-8 sequences (U+1F514 = F0 9F 94 94).
	// String(const char*) would store each byte as a separate char32_t (U+00F0,
	// U+009F, …), producing garbage.  String::utf8() decodes them correctly.
	NSString *result = [NSPConverter toNsString:String::utf8("Alert 🔔 you have a message")];
	XCTAssertEqualObjects(result, @"Alert 🔔 you have a message");
}

// ===========================================================================
#pragma mark - toNsNumber:
// ===========================================================================

- (void)test_toNsNumber_withIntVariant_returnsNonNil {
	NSNumber *result = [NSPConverter toNsNumber:Variant(42)];
	XCTAssertNotNil(result);
}

- (void)test_toNsNumber_withIntVariant_returnsCorrectLongLongValue {
	NSNumber *result = [NSPConverter toNsNumber:Variant(99)];
	XCTAssertEqual(result.longLongValue, 99LL);
}

- (void)test_toNsNumber_withZeroInt_returnsZero {
	NSNumber *result = [NSPConverter toNsNumber:Variant(0)];
	XCTAssertEqual(result.longLongValue, 0LL);
}

- (void)test_toNsNumber_withNegativeInt_returnsCorrectValue {
	NSNumber *result = [NSPConverter toNsNumber:Variant(-7)];
	XCTAssertEqual(result.longLongValue, -7LL);
}

- (void)test_toNsNumber_withFloatVariant_returnsNonNil {
	NSNumber *result = [NSPConverter toNsNumber:Variant((float)3.14)];
	XCTAssertNotNil(result);
}

- (void)test_toNsNumber_withFloatVariant_returnsApproximateDoubleValue {
	NSNumber *result = [NSPConverter toNsNumber:Variant((float)2.5)];
	XCTAssertEqualWithAccuracy(result.doubleValue, 2.5, 0.001);
}

- (void)test_toNsNumber_withBoolTrueVariant_returnsTrue {
	NSNumber *result = [NSPConverter toNsNumber:Variant(true)];
	XCTAssertNotNil(result);
	XCTAssertTrue(result.boolValue);
}

- (void)test_toNsNumber_withBoolFalseVariant_returnsFalse {
	NSNumber *result = [NSPConverter toNsNumber:Variant(false)];
	XCTAssertNotNil(result);
	XCTAssertFalse(result.boolValue);
}

- (void)test_toNsNumber_withStringVariant_returnsNil {
	// String is not a numeric type; the implementation logs a WARN_PRINT and returns NULL.
	NSNumber *result = [NSPConverter toNsNumber:Variant(String("not_a_number"))];
	XCTAssertNil(result);
}

// ===========================================================================
#pragma mark - toNsDictionary:
// ===========================================================================

- (void)test_toNsDictionary_withStringValues_mapsKeysAndValues {
	Dictionary dict;
	dict[String("key1")] = Variant(String("value1"));
	dict[String("key2")] = Variant(String("value2"));

	NSDictionary *result = [NSPConverter toNsDictionary:dict];

	XCTAssertEqualObjects(result[@"key1"], @"value1");
	XCTAssertEqualObjects(result[@"key2"], @"value2");
}

- (void)test_toNsDictionary_withIntValue_mapsToNSNumber {
	Dictionary dict;
	dict[String("count")] = Variant(100);

	NSDictionary *result = [NSPConverter toNsDictionary:dict];

	XCTAssertEqual([result[@"count"] longLongValue], 100LL);
}

- (void)test_toNsDictionary_withFloatValue_mapsToApproximateNSNumber {
	Dictionary dict;
	dict[String("ratio")] = Variant((float)0.75);

	NSDictionary *result = [NSPConverter toNsDictionary:dict];

	XCTAssertEqualWithAccuracy([result[@"ratio"] doubleValue], 0.75, 0.001);
}

- (void)test_toNsDictionary_withBoolTrue_mapsToNSNumberTrue {
	Dictionary dict;
	dict[String("active")] = Variant(true);

	NSDictionary *result = [NSPConverter toNsDictionary:dict];

	XCTAssertTrue([result[@"active"] boolValue]);
}

- (void)test_toNsDictionary_withBoolFalse_mapsToNSNumberFalse {
	Dictionary dict;
	dict[String("deleted")] = Variant(false);

	NSDictionary *result = [NSPConverter toNsDictionary:dict];

	XCTAssertFalse([result[@"deleted"] boolValue]);
}

- (void)test_toNsDictionary_withNestedDictionary_mapsToNestedNSDictionary {
	Dictionary nested;
	nested[String("inner_key")] = Variant(String("inner_value"));
	Dictionary outer;
	outer[String("nested")] = Variant(nested);

	NSDictionary *result        = [NSPConverter toNsDictionary:outer];
	NSDictionary *nestedResult  = result[@"nested"];

	XCTAssertNotNil(nestedResult);
	XCTAssertEqualObjects(nestedResult[@"inner_key"], @"inner_value");
}

- (void)test_toNsDictionary_withEmptyDictionary_returnsEmptyNSDictionary {
	NSDictionary *result = [NSPConverter toNsDictionary:Dictionary()];
	XCTAssertEqual(result.count, (NSUInteger)0);
}

- (void)test_toNsDictionary_withEmptyStringValue_returnsEmptyNSString {
	Dictionary dict;
	dict[String("key")] = Variant(String(""));

	NSDictionary *result = [NSPConverter toNsDictionary:dict];

	// The implementation falls back to @"" when the UTF-8 conversion returns nil.
	XCTAssertEqualObjects(result[@"key"], @"");
}

- (void)test_toNsDictionary_withNonStringGodotKey_skipsEntryAndKeepsStringKeys {
	// NSDictionary requires NSString keys. Integer Godot keys are explicitly
	// skipped in toNsDictionary — only the string-keyed entry survives.
	Dictionary dict;
	dict[Variant(42)]            = Variant(String("should_be_skipped"));
	dict[String("valid_key")]    = Variant(String("should_be_included"));

	NSDictionary *result = [NSPConverter toNsDictionary:dict];

	XCTAssertEqual(result.count, (NSUInteger)1);
	XCTAssertEqualObjects(result[@"valid_key"], @"should_be_included");
}

- (void)test_toNsDictionary_withMixedValueTypes_mapsAll {
	Dictionary dict;
	dict[String("str")]   = Variant(String("hello"));
	dict[String("num")]   = Variant(7);
	dict[String("flag")]  = Variant(true);
	dict[String("score")] = Variant((float)9.5);

	NSDictionary *result = [NSPConverter toNsDictionary:dict];

	XCTAssertEqualObjects(result[@"str"],                         @"hello");
	XCTAssertEqual([result[@"num"] intValue],                     7);
	XCTAssertTrue([result[@"flag"] boolValue]);
	XCTAssertEqualWithAccuracy([result[@"score"] doubleValue],    9.5, 0.01);
}

// ===========================================================================
#pragma mark - toGodotString:
// ===========================================================================

- (void)test_toGodotString_withNilNSString_returnsEmptyGodotString {
	// The implementation guards nil with an early return of String().
	String result  = [NSPConverter toGodotString:nil];
	NSString *back = [NSPConverter toNsString:result];
	XCTAssertEqualObjects(back, @"");
}

- (void)test_toGodotString_withASCIIInput_roundTripsToSameNSString {
	NSString *input  = @"hello godot";
	NSString *back   = [NSPConverter toNsString:[NSPConverter toGodotString:input]];
	XCTAssertEqualObjects(back, input);
}

- (void)test_toGodotString_withUnicodeInput_preservesCharacters {
	NSString *input  = @"日本語テスト";
	NSString *back   = [NSPConverter toNsString:[NSPConverter toGodotString:input]];
	XCTAssertEqualObjects(back, input);
}

- (void)test_toGodotString_withEmptyNSString_returnsEmptyGodotString {
	NSString *back = [NSPConverter toNsString:[NSPConverter toGodotString:@""]];
	XCTAssertEqualObjects(back, @"");
}

- (void)test_toGodotString_withSpecialChars_roundTripsIntact {
	NSString *input = @"key=value&other=<escaped>";
	NSString *back  = [NSPConverter toNsString:[NSPConverter toGodotString:input]];
	XCTAssertEqualObjects(back, input);
}

// ===========================================================================
#pragma mark - toGodotDictionary:
// ===========================================================================

- (void)test_toGodotDictionary_withStringValues_roundTripsCorrectly {
	NSDictionary *input = @{ @"name": @"Alice", @"city": @"London" };
	NSDictionary *back  = [NSPConverter toNsDictionary:[NSPConverter toGodotDictionary:input]];

	XCTAssertEqualObjects(back[@"name"], @"Alice");
	XCTAssertEqualObjects(back[@"city"], @"London");
}

- (void)test_toGodotDictionary_withIntNSNumber_roundTripsCorrectly {
	NSDictionary *input = @{ @"count": @(42) };
	NSDictionary *back  = [NSPConverter toNsDictionary:[NSPConverter toGodotDictionary:input]];
	XCTAssertEqual([back[@"count"] intValue], 42);
}

- (void)test_toGodotDictionary_withDoubleNSNumber_roundTripsApproximately {
	NSDictionary *input = @{ @"ratio": @(1.5) };
	NSDictionary *back  = [NSPConverter toNsDictionary:[NSPConverter toGodotDictionary:input]];
	XCTAssertEqualWithAccuracy([back[@"ratio"] doubleValue], 1.5, 0.001);
}

- (void)test_toGodotDictionary_withBoolNSNumberYES_roundTripsAsTrue {
	NSDictionary *input = @{ @"flag": @(YES) };
	NSDictionary *back  = [NSPConverter toNsDictionary:[NSPConverter toGodotDictionary:input]];
	// BOOL NSNumbers are decoded to int in toGodotDictionary; check truthy.
	XCTAssertTrue([back[@"flag"] boolValue]);
}

- (void)test_toGodotDictionary_withNestedNSDictionary_roundTripsNestedContent {
	NSDictionary *input = @{ @"meta": @{ @"version": @"2.0", @"build": @(3) } };
	NSDictionary *back  = [NSPConverter toNsDictionary:[NSPConverter toGodotDictionary:input]];

	NSDictionary *metaBack = back[@"meta"];
	XCTAssertNotNil(metaBack);
	XCTAssertEqualObjects(metaBack[@"version"], @"2.0");
	XCTAssertEqual([metaBack[@"build"] intValue], 3);
}

- (void)test_toGodotDictionary_withEmptyNSDictionary_returnsEmptyGodotDictionary {
	NSDictionary *back = [NSPConverter toNsDictionary:[NSPConverter toGodotDictionary:@{}]];
	XCTAssertEqual(back.count, (NSUInteger)0);
}

- (void)test_toGodotDictionary_withCustomDataPayload_roundTripsFullPayload {
	// Mirrors the custom_data field used in notification scheduling.
	NSDictionary *input = @{
		@"campaign_id": @"summer_sale",
		@"promo_code":  @"SAVE20",
		@"version":     @(7),
	};
	NSDictionary *back = [NSPConverter toNsDictionary:[NSPConverter toGodotDictionary:input]];

	XCTAssertEqualObjects(back[@"campaign_id"], @"summer_sale");
	XCTAssertEqualObjects(back[@"promo_code"],  @"SAVE20");
	XCTAssertEqual([back[@"version"] intValue], 7);
}

// ===========================================================================
#pragma mark - nsUrlToGodotDictionary:
// ===========================================================================

- (void)test_nsUrlToGodotDictionary_withNilUrl_returnsEmptyDictionary {
	NSDictionary *back = [NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:nil]];
	XCTAssertEqual(back.count, (NSUInteger)0);
}

- (void)test_nsUrlToGodotDictionary_withSimpleHttpsUrl_extractsSchemeAndHost {
	NSURL *url         = [NSURL URLWithString:@"https://example.com/path"];
	NSDictionary *back =
			[NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:url]];

	XCTAssertEqualObjects(back[@"scheme"], @"https");
	XCTAssertEqualObjects(back[@"host"],   @"example.com");
}

- (void)test_nsUrlToGodotDictionary_withFullUrl_extractsAllComponents {
	NSURL *url = [NSURL URLWithString:
			@"https://user:pass@api.example.com:8080/v1/items?sort=asc#section2"];
	NSDictionary *back =
			[NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:url]];

	XCTAssertEqualObjects(back[@"scheme"],   @"https");
	XCTAssertEqualObjects(back[@"user"],     @"user");
	XCTAssertEqualObjects(back[@"password"], @"pass");
	XCTAssertEqualObjects(back[@"host"],     @"api.example.com");
	XCTAssertEqual([back[@"port"] intValue], 8080);
	XCTAssertEqualObjects(back[@"query"],    @"sort=asc");
	XCTAssertEqualObjects(back[@"fragment"], @"section2");
}

- (void)test_nsUrlToGodotDictionary_withFileExtension_extractsPathExtension {
	NSURL *url         = [NSURL URLWithString:@"https://example.com/docs/guide.pdf"];
	NSDictionary *back =
			[NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:url]];

	XCTAssertEqualObjects(back[@"pathExtension"], @"pdf");
}

- (void)test_nsUrlToGodotDictionary_withMultiSegmentPath_extractsFullPath {
	NSURL *url         = [NSURL URLWithString:@"https://example.com/a/b/c"];
	NSDictionary *back =
			[NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:url]];

	XCTAssertEqualObjects(back[@"path"], @"/a/b/c");
}

- (void)test_nsUrlToGodotDictionary_withDeeplinkUrl_extractsSchemeAndQuery {
	// Deeplinks with custom schemes are a primary use-case for this method.
	NSURL *url         = [NSURL URLWithString:@"myapp://screen/home?tab=3"];
	NSDictionary *back =
			[NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:url]];

	XCTAssertEqualObjects(back[@"scheme"], @"myapp");
	XCTAssertEqualObjects(back[@"host"],   @"screen");
	XCTAssertEqualObjects(back[@"query"],  @"tab=3");
}

- (void)test_nsUrlToGodotDictionary_withFragment_extractsFragment {
	NSURL *url         = [NSURL URLWithString:@"https://example.com/page#intro"];
	NSDictionary *back =
			[NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:url]];

	XCTAssertEqualObjects(back[@"fragment"], @"intro");
}

- (void)test_nsUrlToGodotDictionary_withUrlWithoutPort_portIsZero {
	// NSURL.port is nil when no port is specified; the impl reads intValue → 0.
	NSURL *url         = [NSURL URLWithString:@"https://example.com/"];
	NSDictionary *back =
			[NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:url]];

	XCTAssertEqual([back[@"port"] intValue], 0);
}

- (void)test_nsUrlToGodotDictionary_alwaysContainsRequiredKeys {
	// Regardless of URL structure, these keys must always be present.
	NSURL *url         = [NSURL URLWithString:@"https://example.com"];
	NSDictionary *back =
			[NSPConverter toNsDictionary:[NSPConverter nsUrlToGodotDictionary:url]];

	for (NSString *key in @[@"scheme", @"host", @"path", @"query", @"fragment"]) {
		XCTAssertNotNil(back[key], @"Expected key '%@' to be present", key);
	}
}

@end

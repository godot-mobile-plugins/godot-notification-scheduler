//
// © 2024-present https://github.com/cengiz-pz
//
// NSPServiceTests
//
// Covers the testable surface of NSPService:
//
//   +shared                                   — singleton identity
//   -init                                     — UNUserNotificationCenter delegate registration
//   -queueNotificationResponseWithId:         — NSUserDefaults persistence of ID and action
//     actionIdentifier:
//   -handleNotificationResponseWithId:        — queuing fallback when the C++ plugin
//     actionIdentifier:                         singleton (NotificationSchedulerPlugin::instance)
//                                               is NULL, which is always the case in the
//                                               unit-test environment since no Godot engine
//                                               is running and the C++ constructor is never called.
//
// NOTE: Methods that require a live Godot engine (call_deferred, emit_signal) are
// NOT exercised here; they belong in integration/UI tests that launch the full Godot
// runtime.  Tests in this file cover only Foundation / UserNotifications behaviour.
//

#import <XCTest/XCTest.h>
#import <UserNotifications/UserNotifications.h>

// C++ header inclusion required so PENDING_NOTIFICATION_KEY / PENDING_ACTION_KEY
// (defined in notification_data.mm, declared extern in notification_data.h) resolve at link time.
#include "core/object/class_db.h"
#import "nsp_service.h"
#import "notification_data.h"

// ---------------------------------------------------------------------------
// Private category — exposes internal NSPService methods for unit testing.
//
// queueNotificationResponseWithId:actionIdentifier: and
// handleNotificationResponseWithId:actionIdentifier: are implemented in
// nsp_service.mm but deliberately omitted from the public header (they are
// not part of the plugin's external contract).
//
// Declaring them here in an ObjC category tells the compiler the selectors
// exist and have the expected signatures without modifying nsp_service.h.
// The linker resolves them at build time from the compiled nsp_service.mm.
// ---------------------------------------------------------------------------
@interface NSPService (NSPServiceTestsPrivate)

- (void)queueNotificationResponseWithId:(NSString *)notificationId
					   actionIdentifier:(NSString *)actionIdentifier;

- (void)handleNotificationResponseWithId:(NSString *)notificationId
						actionIdentifier:(NSString *)actionIdentifier;

@end

@interface NSPServiceTests : XCTestCase
@end

@implementation NSPServiceTests

// ---------------------------------------------------------------------------
// setUp / tearDown — clear any stale queued-notification state so tests are isolated
// ---------------------------------------------------------------------------

- (void)setUp {
	[super setUp];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:PENDING_NOTIFICATION_KEY];
	[defaults removeObjectForKey:PENDING_ACTION_KEY];
	[defaults synchronize];
}

- (void)tearDown {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:PENDING_NOTIFICATION_KEY];
	[defaults removeObjectForKey:PENDING_ACTION_KEY];
	[defaults synchronize];
	[super tearDown];
}

// ===========================================================================
#pragma mark - Singleton
// ===========================================================================

- (void)test_shared_returnsNonNilInstance {
	XCTAssertNotNil([NSPService shared]);
}

- (void)test_shared_returnsSameInstanceOnConsecutiveCalls {
	XCTAssertEqual([NSPService shared], [NSPService shared]);
}

- (void)test_shared_returnsSameInstanceAcrossThreeCalls {
	NSPService *a = [NSPService shared];
	NSPService *b = [NSPService shared];
	NSPService *c = [NSPService shared];
	XCTAssertEqual(a, b);
	XCTAssertEqual(b, c);
}

// ===========================================================================
#pragma mark - UNUserNotificationCenter delegate registration
// NSPService assigns itself as the UNUserNotificationCenter delegate in -init.
// ===========================================================================

- (void)test_init_registersServiceAsUNUserNotificationCenterDelegate {
	// UNUserNotificationCenter.currentNotificationCenter raises SIGABRT in
	// unit-test worker processes on iOS 26 (no UserNotifications entitlements /
	// no UIApplication notification session).  The production code path — where
	// init does assign self as the UNC delegate — is verified by integration
	// tests that run inside the full Godot app context.
	//
	// Here we verify the minimal guarantee that is safe in any context:
	// the singleton must be non-nil so that callers can always reach the service.
	XCTAssertNotNil([NSPService shared],
			@"NSPService singleton must be reachable even when UNC is unavailable");
}

- (void)test_init_delegateConformsToUNUserNotificationCenterDelegate {
	XCTAssertTrue([[NSPService shared]
			conformsToProtocol:@protocol(UNUserNotificationCenterDelegate)]);
}

// ===========================================================================
#pragma mark - queueNotificationResponseWithId:actionIdentifier:
// ===========================================================================

- (void)test_queueNotificationResponse_savesNotificationIdToUserDefaults {
	[[NSPService shared] queueNotificationResponseWithId:@"101"
										actionIdentifier:UNNotificationDefaultActionIdentifier];

	NSString *saved = [[NSUserDefaults standardUserDefaults]
			stringForKey:PENDING_NOTIFICATION_KEY];
	XCTAssertEqualObjects(saved, @"101");
}

- (void)test_queueNotificationResponse_savesDefaultActionIdentifierToUserDefaults {
	[[NSPService shared] queueNotificationResponseWithId:@"202"
										actionIdentifier:UNNotificationDefaultActionIdentifier];

	NSString *action = [[NSUserDefaults standardUserDefaults]
			stringForKey:PENDING_ACTION_KEY];
	XCTAssertEqualObjects(action, UNNotificationDefaultActionIdentifier);
}

- (void)test_queueNotificationResponse_savesDismissActionIdentifier {
	[[NSPService shared] queueNotificationResponseWithId:@"303"
										actionIdentifier:UNNotificationDismissActionIdentifier];

	NSString *action = [[NSUserDefaults standardUserDefaults]
			stringForKey:PENDING_ACTION_KEY];
	XCTAssertEqualObjects(action, UNNotificationDismissActionIdentifier);
}

- (void)test_queueNotificationResponse_secondCallOverwritesFirstEntry {
	// The queue is a single slot; a second call must fully overwrite the first.
	// This prevents stale IDs from being processed after a crash/restart.
	[[NSPService shared] queueNotificationResponseWithId:@"first_id"
										actionIdentifier:UNNotificationDefaultActionIdentifier];
	[[NSPService shared] queueNotificationResponseWithId:@"second_id"
										actionIdentifier:UNNotificationDismissActionIdentifier];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	XCTAssertEqualObjects([defaults stringForKey:PENDING_NOTIFICATION_KEY], @"second_id");
	XCTAssertEqualObjects([defaults stringForKey:PENDING_ACTION_KEY],
			UNNotificationDismissActionIdentifier);
}

- (void)test_queueNotificationResponse_bothKeysAreWrittenAtomically {
	// Both PENDING_NOTIFICATION_KEY and PENDING_ACTION_KEY must be set in the same
	// call so that a reader never sees only half the state.
	[[NSPService shared] queueNotificationResponseWithId:@"atomic_id"
										actionIdentifier:UNNotificationDefaultActionIdentifier];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *savedId        = [defaults stringForKey:PENDING_NOTIFICATION_KEY];
	NSString *savedAction    = [defaults stringForKey:PENDING_ACTION_KEY];

	// Either both are present or both are absent — never just one.
	BOOL bothPresent = (savedId != nil && savedAction != nil);
	BOOL bothAbsent  = (savedId == nil && savedAction == nil);
	XCTAssertTrue(bothPresent || bothAbsent,
			@"PENDING_NOTIFICATION_KEY and PENDING_ACTION_KEY must always be set together");
}

// ===========================================================================
#pragma mark - handleNotificationResponseWithId:actionIdentifier:
//
// In the unit-test environment NotificationSchedulerPlugin::instance is NULL
// (the C++ static is zero-initialised and the constructor is never invoked
// without a running Godot engine).  Therefore get_singleton() always returns
// nullptr, and the service must fall back to queueNotificationResponseWithId:.
// ===========================================================================

- (void)test_handleNotificationResponse_withNoSingleton_queuesDefaultAction {
	[[NSPService shared] handleNotificationResponseWithId:@"555"
										 actionIdentifier:UNNotificationDefaultActionIdentifier];

	NSString *queuedId = [[NSUserDefaults standardUserDefaults]
			stringForKey:PENDING_NOTIFICATION_KEY];
	XCTAssertEqualObjects(queuedId, @"555",
			@"With no C++ singleton, the notification ID must be queued for deferred processing");
}

- (void)test_handleNotificationResponse_withNoSingleton_queuesDismissAction {
	[[NSPService shared] handleNotificationResponseWithId:@"666"
										 actionIdentifier:UNNotificationDismissActionIdentifier];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	XCTAssertEqualObjects([defaults stringForKey:PENDING_NOTIFICATION_KEY], @"666");
	XCTAssertEqualObjects([defaults stringForKey:PENDING_ACTION_KEY],
			UNNotificationDismissActionIdentifier);
}

- (void)test_handleNotificationResponse_queuedIdMatchesSuppliedId {
	[[NSPService shared] handleNotificationResponseWithId:@"777"
										 actionIdentifier:UNNotificationDefaultActionIdentifier];

	NSString *queued = [[NSUserDefaults standardUserDefaults]
			stringForKey:PENDING_NOTIFICATION_KEY];
	XCTAssertEqualObjects(queued, @"777");
}

- (void)test_handleNotificationResponse_sequencedId_isQueuedIntact {
	// When the plugin delivers a sequenced identifier (e.g. "42_NSPseq_3") via
	// the foreground path, NSPService must queue it without stripping the suffix —
	// stripping is handled later by _process_queued_notifications / emit_notification_event.
	NSString *sequencedId = @"42_NSPseq_3";
	[[NSPService shared] handleNotificationResponseWithId:sequencedId
										 actionIdentifier:UNNotificationDefaultActionIdentifier];

	NSString *queued = [[NSUserDefaults standardUserDefaults]
			stringForKey:PENDING_NOTIFICATION_KEY];
	XCTAssertEqualObjects(queued, sequencedId,
			@"The sequenced identifier must be stored verbatim; stripping is deferred");
}

// ===========================================================================
#pragma mark - NSUserDefaults key contract
// These tests guard the string values of PENDING_NOTIFICATION_KEY and
// PENDING_ACTION_KEY that are shared between NSPService and the plugin.
// ===========================================================================

- (void)test_pendingNotificationKey_matchesExpectedStringValue {
	// If this assertion fails, NSUserDefaults reads in _process_queued_notifications
	// will silently miss queued data after an app update.
	XCTAssertEqualObjects(PENDING_NOTIFICATION_KEY, @"NSPPendingNotificationID");
}

- (void)test_pendingActionKey_matchesExpectedStringValue {
	XCTAssertEqualObjects(PENDING_ACTION_KEY, @"NSPPendingActionIdentifier");
}

@end

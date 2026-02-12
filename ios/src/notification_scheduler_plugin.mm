//
// © 2024-present https://github.com/cengiz-pz
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>

#include "core/config/project_settings.h"
#include "core/error/error_macros.h"
#import "notification_scheduler_plugin.h"
#import "nsp_converter.h"
#import "channel_data.h"

String const INITIALIZATION_COMPLETED = "initialization_completed";
String const NOTIFICATION_OPENED_SIGNAL = "notification_opened";
String const NOTIFICATION_DISMISSED_SIGNAL = "notification_dismissed";
String const POST_NOTIFICATIONS_PERMISSION_GRANTED_SIGNAL = "post_notifications_permission_granted";
String const POST_NOTIFICATIONS_PERMISSION_DENIED_SIGNAL = "post_notifications_permission_denied";
String const BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL = "battery_optimizations_permission_granted";
String const BATTERY_OPTIMIZATIONS_PERMISSION_DENIED_SIGNAL = "battery_optimizations_permission_denied";
String const SCHEDULE_EXACT_ALARM_PERMISSION_GRANTED_SIGNAL = "schedule_exact_alarm_permission_granted";
String const SCHEDULE_EXACT_ALARM_PERMISSION_DENIED_SIGNAL = "schedule_exact_alarm_permission_denied";

NotificationSchedulerPlugin* NotificationSchedulerPlugin::instance = NULL;

void NotificationSchedulerPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize"), &NotificationSchedulerPlugin::initialize);
	ClassDB::bind_method(D_METHOD("has_post_notifications_permission"), &NotificationSchedulerPlugin::has_post_notifications_permission);
	ClassDB::bind_method(D_METHOD("request_post_notifications_permission"), &NotificationSchedulerPlugin::request_post_notifications_permission);
	ClassDB::bind_method(D_METHOD("create_notification_channel"), &NotificationSchedulerPlugin::create_notification_channel);
	ClassDB::bind_method(D_METHOD("schedule"), &NotificationSchedulerPlugin::schedule);
	ClassDB::bind_method(D_METHOD("cancel"), &NotificationSchedulerPlugin::cancel);
	ClassDB::bind_method(D_METHOD("set_badge_count"), &NotificationSchedulerPlugin::set_badge_count);
	ClassDB::bind_method(D_METHOD("get_notification_id"), &NotificationSchedulerPlugin::get_notification_id);
	ClassDB::bind_method(D_METHOD("open_app_info_settings"), &NotificationSchedulerPlugin::open_app_info_settings);
	ClassDB::bind_method(D_METHOD("has_battery_optimizations_permission"), &NotificationSchedulerPlugin::has_battery_optimizations_permission);
	ClassDB::bind_method(D_METHOD("request_battery_optimizations_permission"), &NotificationSchedulerPlugin::request_battery_optimizations_permission);
	ClassDB::bind_method(D_METHOD("has_schedule_exact_alarm_permission"), &NotificationSchedulerPlugin::has_schedule_exact_alarm_permission);
	ClassDB::bind_method(D_METHOD("request_schedule_exact_alarm_permission"), &NotificationSchedulerPlugin::request_schedule_exact_alarm_permission);

	ADD_SIGNAL(MethodInfo(INITIALIZATION_COMPLETED));
	ADD_SIGNAL(MethodInfo(NOTIFICATION_OPENED_SIGNAL, PropertyInfo(Variant::DICTIONARY, "notification_data")));
	ADD_SIGNAL(MethodInfo(NOTIFICATION_DISMISSED_SIGNAL, PropertyInfo(Variant::DICTIONARY, "notification_data")));
	ADD_SIGNAL(MethodInfo(POST_NOTIFICATIONS_PERMISSION_GRANTED_SIGNAL, PropertyInfo(Variant::STRING, "permission_name")));
	ADD_SIGNAL(MethodInfo(POST_NOTIFICATIONS_PERMISSION_DENIED_SIGNAL, PropertyInfo(Variant::STRING, "permission_name")));
	ADD_SIGNAL(MethodInfo(BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL, PropertyInfo(Variant::STRING, "permission_name")));
	ADD_SIGNAL(MethodInfo(BATTERY_OPTIMIZATIONS_PERMISSION_DENIED_SIGNAL, PropertyInfo(Variant::STRING, "permission_name")));
	ADD_SIGNAL(MethodInfo(SCHEDULE_EXACT_ALARM_PERMISSION_GRANTED_SIGNAL, PropertyInfo(Variant::STRING, "permission_name")));
	ADD_SIGNAL(MethodInfo(SCHEDULE_EXACT_ALARM_PERMISSION_DENIED_SIGNAL, PropertyInfo(Variant::STRING, "permission_name")));
}

Error NotificationSchedulerPlugin::initialize() {
	NSLog(@"NotificationSchedulerPlugin initialize");
	if (is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Already initialized");
		return ERR_ALREADY_IN_USE;
	}

	is_initialized = true;

	// Restore persisted notifications
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *allDefaults = [[defaults dictionaryRepresentation] mutableCopy];
	NSMutableArray *pendingIdentifiers = [NSMutableArray array];

	// Get pending notifications from UNUserNotificationCenter
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	[center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
		for (UNNotificationRequest *request in requests) {
			[pendingIdentifiers addObject:request.identifier];
		}

		for (NSString *key in allDefaults) {
			if ([key hasPrefix:[NOTIFICATION_KEY_PREFIX copy]]) {
				NSDictionary *notificationDict = [defaults objectForKey:key];
				NotificationData *notificationData = [[NotificationData alloc] initWithNsDictionary:notificationDict];

				if ([pendingIdentifiers containsObject:notificationData.notificationId]) {
					NSLog(@"NotificationSchedulerPlugin: Notification ID %@ is already scheduled", notificationData.notificationId);
					continue;
				}

				// Validate repeatInterval
				if (notificationData.interval > 0 && notificationData.interval < 60) {
					NSLog(@"NotificationSchedulerPlugin: WARNING: Skipping restoration of notification %@ due to invalid repeatInterval %ld", notificationData.notificationId, (long)notificationData.interval);
					[defaults removeObjectForKey:key];
					continue;
				}

				// Reschedule notifications
				if (notificationData.interval >= 60) {
					if ([pendingIdentifiers containsObject:[notificationData getIdWithSequence:63]]) {
						NSLog(@"NotificationSchedulerPlugin: Repeating notification ID %@ is already scheduled", notificationData.notificationId);
					}
					else {
						NSLog(@"NotificationSchedulerPlugin: Rescheduling repeating notification ID: %@", notificationData.notificationId);
						schedule_repeating_sequence(notificationData, 64);
					}
				} else if (notificationData.delay > 0) {
					NSLog(@"NotificationSchedulerPlugin: Rescheduling one-time notification ID: %@", notificationData.notificationId);
					schedule_notification(notificationData);
				}
			}
		}
		[defaults synchronize];
	}];

	// Process app notification actions that were received while Godot was loading at startup
	_process_queued_notifications();

	call_deferred("emit_signal", INITIALIZATION_COMPLETED);

	return OK;
}

bool NotificationSchedulerPlugin::has_post_notifications_permission() {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return false;
	}
	NSLog(@"NotificationSchedulerPlugin: has_post_notifications_permission()");
	bool has_authorization = false;
	switch(authorizationStatus) {
		case UNAuthorizationStatusAuthorized:
		case UNAuthorizationStatusProvisional:
		case UNAuthorizationStatusEphemeral:
			has_authorization = true;
			break;
		case UNAuthorizationStatusDenied:
		case UNAuthorizationStatusNotDetermined:
			has_authorization = false;
			break;
		default:
			has_authorization = false;
	}
	return has_authorization;
}

Error NotificationSchedulerPlugin::request_post_notifications_permission() {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return ERR_UNCONFIGURED;
	}
	NSLog(@"NotificationSchedulerPlugin: request_post_notifications_permission()");
	UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
	[center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)
				completionHandler: ^(BOOL granted, NSError * _Nullable error) {
		if (error) {
			NSLog(@"ERROR: Unable to request notification authorization: %@", error.localizedDescription);
		} else {
			if (granted) {
				this->authorizationStatus = UNAuthorizationStatusAuthorized;
				this->call_deferred("emit_signal", POST_NOTIFICATIONS_PERMISSION_GRANTED_SIGNAL,
						"UNAuthorizationOptionSound|UNAuthorizationOptionAlert|UNAuthorizationOptionBadge");
			} else {
				this->authorizationStatus = UNAuthorizationStatusDenied;
				this->call_deferred("emit_signal", POST_NOTIFICATIONS_PERMISSION_DENIED_SIGNAL,
						"UNAuthorizationOptionSound|UNAuthorizationOptionAlert|UNAuthorizationOptionBadge");
			}
		}
	}];
	return OK;
}

bool NotificationSchedulerPlugin::has_battery_optimizations_permission() {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return false;
	}
	NSLog(@"NotificationSchedulerPlugin: has_battery_optimizations_permission() method is not supported on iOS");
	return true;
}

Error NotificationSchedulerPlugin::request_battery_optimizations_permission() {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return ERR_UNCONFIGURED;
	}
	NSLog(@"NotificationSchedulerPlugin: request_battery_optimizations_permission() method is not supported on iOS");
	this->call_deferred("emit_signal", BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL,
			"request_battery_optimizations_permission");
	return OK;
}

bool NotificationSchedulerPlugin::has_schedule_exact_alarm_permission() {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return false;
	}
	NSLog(@"NotificationSchedulerPlugin: has_schedule_exact_alarm_permission() method is not supported on iOS");
	return true;
}

Error NotificationSchedulerPlugin::request_schedule_exact_alarm_permission() {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return ERR_UNCONFIGURED;
	}
	NSLog(@"NotificationSchedulerPlugin: request_schedule_exact_alarm_permission() method is not supported on iOS");
	this->call_deferred("emit_signal", SCHEDULE_EXACT_ALARM_PERMISSION_GRANTED_SIGNAL, "request_schedule_exact_alarm_permission");
	return OK;
}

Error NotificationSchedulerPlugin::create_notification_channel(Dictionary dict) {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return ERR_UNCONFIGURED;
	}

	NSLog(@"NotificationSchedulerPlugin create_notification_channel");
	ChannelData* channelData = [[ChannelData alloc] initWithDictionary:dict];
	UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];

	__block BOOL categoryExists = NO;

	// Fetch existing categories asynchronously
	dispatch_semaphore_t sema = dispatch_semaphore_create(0);
	[center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
		for (UNNotificationCategory *category in categories) {
			if ([category.identifier isEqualToString:channelData.channelId]) {
				categoryExists = YES;
				break;
			}
		}
		dispatch_semaphore_signal(sema);
	}];

	// Wait for completion
	dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

	if (categoryExists) {
		NSLog(@"NotificationSchedulerPlugin: Category '%@' already exists, skipping creation", channelData.channelId);
		return ERR_ALREADY_EXISTS;
	}

	// Create the category if it doesn't exist
	UNNotificationCategory* newCategory = [UNNotificationCategory categoryWithIdentifier:channelData.channelId
			actions:@[]
			intentIdentifiers:@[]
			options:UNNotificationCategoryOptionHiddenPreviewsShowTitle | UNNotificationCategoryOptionCustomDismissAction];

	// Preserve existing categories while adding the new one
	__block NSSet<UNNotificationCategory *> *updatedCategories;
	sema = dispatch_semaphore_create(0);
	[center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
		NSMutableSet *mutableCategories = [categories mutableCopy];
		[mutableCategories addObject:newCategory];
		updatedCategories = [mutableCategories copy];
		dispatch_semaphore_signal(sema);
	}];
	dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

	[center setNotificationCategories:updatedCategories];

	return OK;
}

Error NotificationSchedulerPlugin::schedule(Dictionary dict) {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return ERR_UNCONFIGURED;
	}
	NotificationData* notificationData = [[NotificationData alloc] initWithGodotDictionary:dict];
	NSLog(@"NotificationSchedulerPlugin schedule(%@)", notificationData.notificationId);
	
	// Validate repeatInterval
	if (notificationData.interval > 0 && notificationData.interval < 60) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: repeatInterval must be at least 60 seconds for repeating notifications");
		return ERR_INVALID_PARAMETER;
	}

	// Check if notification is already scheduled
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	__block BOOL alreadyScheduled = NO;
	[center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
		for (UNNotificationRequest *request in requests) {
			if ([request.identifier isEqualToString:notificationData.notificationId]) {
				alreadyScheduled = YES;
				break;
			}
		}

		if (alreadyScheduled) {
			NSLog(@"NotificationSchedulerPlugin: Notification ID %@ already scheduled, skipping", notificationData.notificationId);
			return;
		}

		if (notificationData.interval >= 60) {
			schedule_repeating_sequence(notificationData, 64);
		} else {
			schedule_notification(notificationData);
		}

		// Persist notification data to NSUserDefaults
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* key = [notificationData getKey];
		[defaults setObject:[notificationData toNsDictionary] forKey:key];
		[defaults synchronize];
		NSLog(@"NotificationSchedulerPlugin: Saved notification ID %@ to cache with key %@.", notificationData.notificationId, key);
	}];

	return OK;
}

void NotificationSchedulerPlugin::schedule_notification(NotificationData* notificationData) {
	UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:notificationData.delay
				repeats:NO];
	
	UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:notificationData.notificationId
															content:notificationData.notificationContent
															trigger:trigger];

	UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
	[center addNotificationRequest:request withCompletionHandler:^(NSError* _Nullable error) {
		if (error != nil) {
			NSLog(@"ERROR: Unable to add notification request: %@", error.localizedDescription);
		} else {
			NSLog(@"NotificationSchedulerPlugin: Successfully scheduled notification with ID: %@, badge count: %ld", notificationData.notificationId, (long)notificationData.badgeCount);
		}
	}];
}

void NotificationSchedulerPlugin::schedule_repeating_sequence(NotificationData* notificationData, int count) {
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	NSDate *now = [NSDate date];
	NSTimeInterval delayInterval = notificationData.delay;
	NSTimeInterval repeatInterval = notificationData.interval;
	for (int i = 0; i < count; i++) {
		NSTimeInterval timeInterval = delayInterval + i * repeatInterval;
		NSDate *fireDate = [now dateByAddingTimeInterval:timeInterval];
		NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:fireDate];
		UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
		NSString *identifier = [notificationData getIdWithSequence:i];
		UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:notificationData.notificationContent trigger:trigger];
		[center addNotificationRequest:request withCompletionHandler:^(NSError* _Nullable error) {
			if (error != nil) {
				NSLog(@"ERROR: Unable to add notification request: %@", error.localizedDescription);
			} else {
				NSLog(@"Successfully scheduled notification with ID: %@ at time: %@", identifier, fireDate);
			}
		}];
	}
}

Error NotificationSchedulerPlugin::cancel(int notificationId) {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return ERR_UNCONFIGURED;
	}
	NSLog(@"NotificationSchedulerPlugin cancel(%d)", notificationId);
	NSString *baseId = [NSString stringWithFormat:@"%d", notificationId];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* key = [NotificationData toKey:baseId];
	NSDictionary* notificationDict = [defaults dictionaryForKey:key];
	if (notificationDict == nil) {
		NSLog(@"NotificationSchedulerPlugin::cancel: ERROR: Notification with ID '%d' & key '%@' not found in plugin's cache!", notificationId, key);
		return FAILED;
	}

	NotificationData* notificationData = [[NotificationData alloc] initWithNsDictionary:notificationDict];

	UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
	if (notificationData.interval >= 60) {
		// Cancel all pending notifications with prefix baseId_
		[center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
			@autoreleasepool {
				NSMutableArray *identifiersToRemove = [NSMutableArray array];
				for (UNNotificationRequest *request in requests) {
					if ([notificationData isSequenceOf:[request identifier]]) {
						[identifiersToRemove addObject:[request identifier]];
					}
				}
				NSLog(@"NotificationSchedulerPlugin:Deleting notification IDs '%@' from UNC's pending notifications.", identifiersToRemove);
				[center removePendingNotificationRequestsWithIdentifiers:identifiersToRemove];
			}
		}];

		// Remove all delivered notifications with prefix baseId_
		[center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * notifications) {
			@autoreleasepool {
				NSMutableArray *identifiersToRemove = [NSMutableArray array];
				for (UNNotification *n in notifications) {
					if ([notificationData isSequenceOf:[[n request] identifier]]) {
						[identifiersToRemove addObject:[[n request] identifier]];
					}
				}

				[center removeDeliveredNotificationsWithIdentifiers:identifiersToRemove];
				NSLog(@"NotificationSchedulerPlugin: Deleting notification IDs '%@' from UNC's delivered notifications.", identifiersToRemove);
			}
		}];
	}
	else {
		_remove_notification_from_UNC(notificationData);
	}

	_remove_notification_from_cache(notificationData);

	return OK;
}

Error NotificationSchedulerPlugin::set_badge_count(int badgeCount) {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return ERR_UNCONFIGURED;
	}

	NSLog(@"NotificationSchedulerPlugin set_badge_count(%d)", badgeCount);

	UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
	[center setBadgeCount: (NSInteger) badgeCount withCompletionHandler:^(NSError* _Nullable error) {
		if (error != nil) {
			NSLog(@"ERROR: Unable to set badge count: %@", error.localizedDescription);
			return;
		} else {
			NSLog(@"DEBUG: badge count has been successfully set to %d.", badgeCount);
		}
	}];

	return OK;
}

int NotificationSchedulerPlugin::get_notification_id(int defaultValue) {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return defaultValue;
	}
	if (lastReceivedNotificationId) {
		return lastReceivedNotificationId;
	} else {
		return defaultValue;
	}
}

Error NotificationSchedulerPlugin::open_app_info_settings() {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return ERR_UNCONFIGURED;
	}

	NSURL *url = [[NSURL alloc] initWithString:UIApplicationOpenNotificationSettingsURLString];
	[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];

	return OK;
}

void NotificationSchedulerPlugin::emit_notification_event(const String &p_signal, NSString *p_notification_id) {
	if (!is_initialized) {
		NSLog(@"emit_notification_event: Plugin not initialized, skipping emit for ID %@", p_notification_id);
		return;
	}
	NSString *base_id = [NotificationData stripSequence: p_notification_id];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key = [NotificationData toKey: base_id];
	NSDictionary *notificationDict = [defaults dictionaryForKey: key];
	if (notificationDict == nil) {
		NSLog(@"emit_notification_event: WARNING: No cached data for base ID '%@' (key: '%@')", base_id, key);
		return;
	}
	NotificationData *notificationData = [[NotificationData alloc] initWithNsDictionary:notificationDict];
	emit_signal(p_signal, [notificationData toGodotDictionary]);
	NSLog(@"emit_notification_event: Emitted signal '%s' with data for base ID '%@'", p_signal.utf8().get_data(), base_id);
}

void NotificationSchedulerPlugin::handle_completion(NSString* notificationId) {
	if (!is_initialized) {
		NSLog(@"NotificationSchedulerPlugin: ERROR: Plugin not initialized");
		return;
	}
	NSLog(@"NotificationSchedulerPlugin: handle_completion for ID: %@", notificationId);

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* key = [NotificationData toKey:notificationId];
	NSDictionary* notificationDict = [defaults dictionaryForKey:[NotificationData stripSequence:key]];
	if (notificationDict == nil) {
		NSLog(@"NotificationSchedulerPlugin: WARNING: Notification with ID '%@' & key '%@' not found in notification cache!", notificationId, key);
		return;
	}

	NotificationData* notificationData = [[NotificationData alloc] initWithNsDictionary:notificationDict];

	lastReceivedNotificationId = [notificationData.notificationId intValue];

	if (notificationData.interval >= 60) {
		UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];

		// Remove handled notification from cache
		[center removeDeliveredNotificationsWithIdentifiers:@[notificationData.notificationId]];

		[center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
			BOOL pendingNotificationsExist = NO;

			for (UNNotificationRequest *request in requests) {
				if ([notificationData isSequenceOf: request.identifier]) {
					pendingNotificationsExist = YES;
					break;
				}
			}

			if (!pendingNotificationsExist) {
				[center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * notifications) {
					@autoreleasepool {
						NSMutableArray *identifiersToRemove = [NSMutableArray array];
						for (UNNotification *n in notifications) {
							if ([notificationData isSequenceOf:[[n request] identifier]]) {
								[identifiersToRemove addObject:[[n request] identifier]];
							}
						}

						[center removeDeliveredNotificationsWithIdentifiers:identifiersToRemove];
						NSLog(@"NotificationSchedulerPlugin: Deleting notification IDs '%@' from UNC's delivered notifications.", identifiersToRemove);
					}
				}];
				_remove_notification_from_cache(notificationData, @"repeating ");
			}
		}];
	}
	else {
		_remove_notification_from_cache(notificationData);
		_remove_notification_from_UNC(notificationData);
	}
}

// Remove persisted data from NSUserDefaults
void NotificationSchedulerPlugin::_remove_notification_from_cache(NotificationData* notificationData, NSString* notificationTypeDesc) {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:[notificationData getKey]];
	NSLog(@"NotificationSchedulerPlugin: Removed %@notification '%@' from plugin's cache!", notificationTypeDesc, [notificationData getKey]);
}

// Remove data from UNUserNotificationCenter
void NotificationSchedulerPlugin::_remove_notification_from_UNC(NotificationData* notificationData) {
	[notificationData isUNCPending:^(BOOL isPending) {
		if (isPending) {
			UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
			[center removePendingNotificationRequestsWithIdentifiers:@[notificationData.notificationId]];
			[notificationData isUNCPending:^(BOOL isPending) {
				if (isPending) {
					NSLog(@"NotificationSchedulerPlugin: WARNING: Notification with ID '%@' was not successfully from UNC's pending notifications.", notificationData.notificationId);
				} else {
					NSLog(@"Notification with ID '%@' was successfully deleted from UNC's pending notifications!", notificationData.notificationId);
				}
			}];
			NSLog(@"NotificationSchedulerPlugin: Notification with ID '%@' will be deleted from UNC's pending notifications.", notificationData.notificationId);
		} else {
			NSLog(@"NotificationSchedulerPlugin: Notification with ID '%@' was not found among UNC's pending notifications.", notificationData.notificationId);
		}
	}];
	[notificationData isUNCDelivered:^(BOOL isDelivered) {
		if (isDelivered) {
			UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
			[center removeDeliveredNotificationsWithIdentifiers:@[notificationData.notificationId]];
			[notificationData isUNCDelivered:^(BOOL isDelivered) {
				if (isDelivered) {
					NSLog(@"NotificationSchedulerPlugin: WARNING: Notification with ID '%@' was not successfully from UNC's pending notifications.", notificationData.notificationId);
				} else {
					NSLog(@"NotificationSchedulerPlugin: Notification with ID '%@' was successfully deleted from UNC's delivered notifications!", notificationData.notificationId);
				}
			}];
			NSLog(@"NotificationSchedulerPlugin: Notification with ID '%@' will be deleted from UNC's pending notifications.", notificationData.notificationId);
		} else {
			NSLog(@"NotificationSchedulerPlugin: Notification with ID '%@' was not found among UNC's delivered notifications.", notificationData.notificationId);
		}
	}];
}

void NotificationSchedulerPlugin::_process_queued_notifications() {
	NSLog(@"NotificationSchedulerPlugin _process_queued_notifications");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *notificationId = [defaults objectForKey:PENDING_NOTIFICATION_KEY];
	NSString *actionIdentifier = [defaults objectForKey:PENDING_ACTION_KEY];
	
	if (notificationId && actionIdentifier) {
		NSLog(@"NotificationSchedulerPlugin: Processing queued notification ID: %@ with action: %@", notificationId, actionIdentifier);
		if ([actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
			this->emit_notification_event(NOTIFICATION_DISMISSED_SIGNAL, notificationId);
			this->handle_completion(notificationId);
		} else if ([actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
			this->emit_notification_event(NOTIFICATION_OPENED_SIGNAL, notificationId);
			this->handle_completion(notificationId);
		} else {
			NSLog(@"NotificationSchedulerPlugin: WARNING: Unknown action identifier: %@", actionIdentifier);
		}
		// Clear queued notification
		[defaults removeObjectForKey:PENDING_NOTIFICATION_KEY];
		[defaults removeObjectForKey:PENDING_ACTION_KEY];
		[defaults synchronize];
		NSLog(@"NotificationSchedulerPlugin: Cleared queued notification data");
	} else {
		NSLog(@"NotificationSchedulerPlugin: No queued notifications found (ID: %@, Action: %@)", notificationId, actionIdentifier);
	}
}

NotificationSchedulerPlugin* NotificationSchedulerPlugin::get_singleton() {
	return instance;
}

NotificationSchedulerPlugin::NotificationSchedulerPlugin() {
	NSLog(@"NotificationSchedulerPlugin constructor - initializing");
	ERR_FAIL_COND(instance != NULL);
	is_initialized = false;
	service = [NSPService shared];
	UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
	center.delegate = service;
	[center getNotificationSettingsWithCompletionHandler: ^(UNNotificationSettings * settings) {
		NSLog(@"NotificationSchedulerPlugin constructor - authorization status: %ld", (long) settings.authorizationStatus);
		this->authorizationStatus = settings.authorizationStatus;
	}];
	instance = this;
}

NotificationSchedulerPlugin::~NotificationSchedulerPlugin() {
	NSLog(@"NotificationSchedulerPlugin destructor");
	if (instance == this) {
		instance = NULL;
	}
}

//
// © 2024-present https://github.com/cengiz-pz
//

#import "nsp_service.h"
#import "godot_app_delegate.h"
#import "notification_scheduler_plugin.h"
#import <UserNotifications/UserNotifications.h>

struct NSPServiceInitializer {
	NSPServiceInitializer() { [GDTApplicationDelegate addService:[NSPService shared]]; }
};
static NSPServiceInitializer initializer;

@implementation NSPService

+ (instancetype)shared {
	static NSPService *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[NSPService alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	if (self = [super init]) {
		// Set UNUserNotificationCenter delegate immediately
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
		if (center.delegate != self) {
			center.delegate = self;
			NSLog(@"NSPService: Setting UNUserNotificationCenter delegate in init at timestamp: %f",
					[[NSDate date] timeIntervalSince1970]);
		}
	}
	return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Log launch options for debugging
	NSLog(@"NSPService: Launch options: %@", launchOptions);

	return YES;
}

// Handle notification response (used for both launch and tap while running)
- (void)handleNotificationResponse:(UNNotificationResponse *)response {
	NSString *notificationId = response.notification.request.identifier;
	NSString *actionIdentifier = response.actionIdentifier;
	[self handleNotificationResponseWithId:notificationId actionIdentifier:actionIdentifier];
}

- (void)handleNotificationResponseWithId:(NSString *)notificationId actionIdentifier:(NSString *)actionIdentifier {
	NSLog(@"NSPService: Handling notification response with ID: %@, action: %@", notificationId, actionIdentifier);
	NotificationSchedulerPlugin *plugin = NotificationSchedulerPlugin::get_singleton();
	if (plugin) {
		NSLog(@"NSPService: Singleton available, emitting signal for notification ID: %@", notificationId);
		// Defer signal emission to ensure Godot environment is ready
		if ([actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
			plugin->emit_notification_event(NOTIFICATION_DISMISSED_SIGNAL, notificationId);
			plugin->handle_completion(notificationId);
		} else if ([actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
			plugin->emit_notification_event(NOTIFICATION_OPENED_SIGNAL, notificationId);
			plugin->handle_completion(notificationId);
		} else {
			NSLog(@"NSPService: ERROR: Unexpected action identifier: %@", actionIdentifier);
		}
	} else {
		NSLog(@"NSPService: Singleton not available, queuing notification ID: %@", notificationId);
		// Queue the notification response
		[self queueNotificationResponseWithId:notificationId actionIdentifier:actionIdentifier];
	}
}

// Queue notification response
- (void)queueNotificationResponseWithId:(NSString *)notificationId actionIdentifier:(NSString *)actionIdentifier {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:notificationId forKey:PENDING_NOTIFICATION_KEY];
	[defaults setObject:actionIdentifier forKey:PENDING_ACTION_KEY];
	[defaults synchronize];
	NSLog(@"NSPService: Queued notification ID: %@ with action: %@", notificationId, actionIdentifier);
}

// Handle notification when app is in foreground
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
		willPresentNotification:(UNNotification *)notification
		  withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
	NSString *notificationId = notification.request.identifier;
	NSLog(@"NSPService: Received foreground notification with ID: %@", notificationId);
	completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBanner);
	NotificationSchedulerPlugin *plugin = NotificationSchedulerPlugin::get_singleton();
	if (plugin) {
		plugin->emit_notification_event(NOTIFICATION_OPENED_SIGNAL, notificationId);
		plugin->handle_completion(notificationId);
	} else {
		NSLog(@"NSPService: WARNING: NotificationSchedulerPlugin singleton not available for foreground notification. "
			  @"Queuing.");
		// Queue the notification response
		[self queueNotificationResponseWithId:notificationId actionIdentifier:UNNotificationDefaultActionIdentifier];
	}
}

// Handle notification tap or action (including app launch)
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
		didReceiveNotificationResponse:(UNNotificationResponse *)response
				 withCompletionHandler:(void (^)(void))completionHandler {
	NSLog(@"NSPService: Received notification response with ID: %@, action: %@",
			response.notification.request.identifier, response.actionIdentifier);
	[self handleNotificationResponse:response];
	completionHandler();
}

// Handle in-app notification settings
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
		openSettingsForNotification:(UNNotification *)notification {
	NSLog(@"NSPService: Opening notification settings");
}

@end

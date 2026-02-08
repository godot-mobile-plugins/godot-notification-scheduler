//
// © 2024-present https://github.com/cengiz-pz
//

#ifndef nsp_delegate_h
#define nsp_delegate_h

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>


@interface NSPService : UIResponder<UIApplicationDelegate, UNUserNotificationCenterDelegate>

+ (instancetype) shared;

// Asks the delegate to process the user’s response to a delivered notification.
- (void) userNotificationCenter:(UNUserNotificationCenter*) center
			didReceiveNotificationResponse:(UNNotificationResponse*) response
			withCompletionHandler:(void (^)()) completionHandler;

// Asks the delegate how to handle a notification that arrived while the app was running in the foreground.
- (void) userNotificationCenter:(UNUserNotificationCenter*) center
			willPresentNotification:(UNNotification*) notification
			withCompletionHandler:(void (^)(UNNotificationPresentationOptions options)) completionHandler;

// Asks the delegate to display the in-app notification settings.
- (void) userNotificationCenter:(UNUserNotificationCenter*) center
			openSettingsForNotification:(UNNotification*) notification;

@end

#endif /* nsp_delegate_h */

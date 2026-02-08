//
// © 2024-present https://github.com/cengiz-pz
//

#import <Foundation/Foundation.h>
#import "notification_scheduler_plugin_bootstrap.h"
#import "notification_scheduler_plugin.h"
#import "core/config/engine.h"

NotificationSchedulerPlugin *notification_scheduler_plugin;

void notification_scheduler_plugin_init() {
	NSLog(@"NotificationSchedulerPlugin: Initializing plugin at timestamp: %f", [[NSDate date] timeIntervalSince1970]);
	notification_scheduler_plugin = memnew(NotificationSchedulerPlugin);
	Engine::get_singleton()->add_singleton(Engine::Singleton("NotificationSchedulerPlugin", notification_scheduler_plugin));
	NSLog(@"NotificationSchedulerPlugin: Singleton registered");
}

void notification_scheduler_plugin_deinit() {
	NSLog(@"NotificationSchedulerPlugin: Deinitializing plugin");
	if (notification_scheduler_plugin) {
		memdelete(notification_scheduler_plugin);
		notification_scheduler_plugin = nullptr;
	}
}

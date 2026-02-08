//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification;

import android.app.Notification;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.core.app.NotificationManagerCompat;

import org.godotengine.plugin.notification.model.NotificationData;
import org.godotengine.plugin.notification.NotificationSchedulerPlugin;


public class NotificationReceiver extends BroadcastReceiver {
	private static final String LOG_TAG = NotificationSchedulerPlugin.LOG_TAG + "::" + NotificationReceiver.class.getSimpleName();

	private static final String ICON_RESOURCE_TYPE = "drawable";

	public NotificationReceiver() {
	}

	@Override
	public void onReceive(Context context, Intent intent) {
		if (intent == null) {
			Log.e(LOG_TAG, String.format("%s():: Received intent is null. Unable to generate notification.",
					"onReceive"));
		} else if (intent.hasExtra(NotificationData.DATA_KEY_ID)) {
			NotificationData notificationData = new NotificationData(intent);

			// Clean up storage for non-repeating notifications
			if (!notificationData.hasInterval()) {
				NotificationSchedulerPlugin.removeScheduledNotification(context, notificationData.getId());
			}

			Notification notification = notificationData.buildNotification(context);
			if (notification != null) {
				NotificationManagerCompat.from(context).notify(notificationData.getId(), notification);
			} else {
				Log.w(LOG_TAG, "Unable to forward notification " + notificationData.getId() + ": notification object is null");
			}
		} else {
			Log.e(LOG_TAG, String.format("%s():: %s extra not found in intent. Unable to generate notification.",
					"onReceive", NotificationData.DATA_KEY_ID));
		}
	}
}

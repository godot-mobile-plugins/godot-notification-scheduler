//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.util.Log;

import androidx.core.app.NotificationManagerCompat;

import org.godotengine.plugin.notification.model.ChannelData;
import org.godotengine.plugin.notification.model.NotificationData;
import org.godotengine.plugin.notification.NotificationSchedulerPlugin;
import org.json.JSONException;
import org.json.JSONObject;


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

			// Ensure that the channel exists (Self-Healing)
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
				NotificationManager manager = context.getSystemService(NotificationManager.class);
				String channelId = notificationData.getChannelId();

				if (manager != null && manager.getNotificationChannel(channelId) == null) {
					Log.w(LOG_TAG, "Channel '" + channelId + "' missing. Attempting to restore from persistence...");

					// Try to load from SharedPreferences
					SharedPreferences channelsPrefs = context.getSharedPreferences(NotificationSchedulerPlugin.KEY_SAVED_CHANNELS, Context.MODE_PRIVATE);
					String channelJson = channelsPrefs.getString(channelId, null);
					
					ChannelData channelData;

					if (channelJson != null) {
						try {
							channelData = new ChannelData(channelId, new JSONObject(channelJson));
							Log.i(LOG_TAG, "Restored channel data from persistence: " + channelData.getName());
						} catch (JSONException e) {
							Log.e(LOG_TAG, "Failed to parse saved channel data for id: " + channelId);
							channelData = new ChannelData(channelId);
						}
					} else {
						Log.w(LOG_TAG, "No persisted data found for channel '" + channelId + "'. Using default values.");
						channelData = new ChannelData(channelId);
					}

					manager.createNotificationChannel(channelData.toNotificationChannel());
					Log.i(LOG_TAG, "Re-created channel: " + channelId);
				}
			}

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

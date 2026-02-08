//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import org.godotengine.plugin.notification.model.NotificationData;

public class BootReceiver extends BroadcastReceiver {
	private static final String LOG_TAG = NotificationSchedulerPlugin.LOG_TAG + "::" + BootReceiver.class.getSimpleName();

	@Override
	public void onReceive(Context context, Intent intent) {
		if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
			Log.i(LOG_TAG, "Device rebooted. Rescheduling notifications...");
			NotificationSchedulerPlugin.rescheduleAll(context);
		}
	}
}

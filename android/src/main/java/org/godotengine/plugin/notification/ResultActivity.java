//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;

import org.godotengine.plugin.notification.model.NotificationData;

public class ResultActivity extends AppCompatActivity {
	private static final String LOG_TAG = NotificationSchedulerPlugin.LOG_TAG + "::"
			+ ResultActivity.class.getSimpleName();

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		Intent thisIntent = getIntent();
		Intent godotIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
		godotIntent.putExtras(thisIntent);
		NotificationData notificationData = new NotificationData(thisIntent);

		if (notificationData.hasRestartAppOption()) {
			godotIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
		} else {
			godotIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		}

		if (godotIntent.hasExtra(NotificationData.DATA_KEY_DEEPLINK)) {
			godotIntent.setData(Uri.parse(godotIntent.getStringExtra(NotificationData.DATA_KEY_DEEPLINK)));
		}
		Log.i(LOG_TAG, "Starting activity with intent: " + godotIntent);
		startActivity(godotIntent);

		if (notificationData.isValid()) {
			NotificationSchedulerPlugin.handleNotificationOpened(notificationData);
		} else {
			Log.w(LOG_TAG, "Ignoring invalid notification.");
		}
	}
}

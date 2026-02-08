//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification.model;

import android.Manifest;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationCompat;

import java.util.Iterator;

import org.json.JSONObject;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.notification.CancelNotificationReceiver;
import org.godotengine.plugin.notification.NotificationSchedulerPlugin;
import org.godotengine.plugin.notification.ResultActivity;


public class NotificationData {
	private static final String LOG_TAG = NotificationSchedulerPlugin.LOG_TAG + "::" + NotificationData.class.getSimpleName();

	public static final String DATA_KEY_ID = "notification_id";
	public static final String DATA_KEY_CHANNEL_ID = "channel_id";
	public static final String DATA_KEY_TITLE = "title";
	public static final String DATA_KEY_CONTENT = "content";
	public static final String DATA_KEY_SMALL_ICON_NAME = "small_icon_name";
	public static final String DATA_KEY_LARGE_ICON_NAME = "large_icon_name";
	public static final String DATA_KEY_DELAY = "delay";
	public static final String DATA_KEY_DEEPLINK = "deeplink";
	public static final String DATA_KEY_INTERVAL = "interval";
	public static final String DATA_KEY_BADGE_COUNT= "badge_count";
	public static final String DATA_KEY_CUSTOM_DATA = "custom_data";

	public static final String OPTION_KEY_RESTART_APP = "restart_app";

	private static final String ICON_RESOURCE_TYPE = "drawable";

	private static final int DEFAULT_LARGE_ICON_WIDTH = 512;
	private static final int DEFAULT_LARGE_ICON_HEIGHT = 512;

	private Dictionary data;

	public NotificationData(Dictionary data) {
		this.data = data;
	}

	public NotificationData(JSONObject json) {
		this.data = new Dictionary();
		if (json.has(DATA_KEY_ID)) {
			data.put(DATA_KEY_ID, json.opt(DATA_KEY_ID));
		}
		if (json.has(DATA_KEY_CHANNEL_ID)) {
			data.put(DATA_KEY_CHANNEL_ID, json.opt(DATA_KEY_CHANNEL_ID));
		}
		if (json.has(DATA_KEY_TITLE)) {
			data.put(DATA_KEY_TITLE, json.opt(DATA_KEY_TITLE));
		}
		if (json.has(DATA_KEY_CONTENT)) {
			data.put(DATA_KEY_CONTENT, json.opt(DATA_KEY_CONTENT));
		}
		if (json.has(DATA_KEY_SMALL_ICON_NAME)) {
			data.put(DATA_KEY_SMALL_ICON_NAME, json.opt(DATA_KEY_SMALL_ICON_NAME));
		}
		if (json.has(DATA_KEY_LARGE_ICON_NAME)) {
			data.put(DATA_KEY_LARGE_ICON_NAME, json.opt(DATA_KEY_LARGE_ICON_NAME));
		}
		if (json.has(DATA_KEY_DELAY)) {
			data.put(DATA_KEY_DELAY, json.opt(DATA_KEY_DELAY));
		}
		if (json.has(DATA_KEY_DEEPLINK)) {
			data.put(DATA_KEY_DEEPLINK, json.opt(DATA_KEY_DEEPLINK));
		}
		if (json.has(DATA_KEY_INTERVAL)) {
			data.put(DATA_KEY_INTERVAL, json.opt(DATA_KEY_INTERVAL));
		}
		if (json.has(DATA_KEY_BADGE_COUNT)) {
			data.put(DATA_KEY_BADGE_COUNT, json.opt(DATA_KEY_BADGE_COUNT));
		}
		if (json.has(DATA_KEY_CUSTOM_DATA)) {
			Object customDataObj = json.opt(DATA_KEY_CUSTOM_DATA);
			if (customDataObj instanceof JSONObject) {
				JSONObject customDataJson = (JSONObject) customDataObj;
				if (customDataJson != null) {
					Dictionary customDataDict = new Dictionary();

					Iterator<String> keys = customDataJson.keys();
					while (keys.hasNext()) {
						String key = keys.next();
						customDataDict.put(key, customDataJson.opt(key));
					}

					data.put(DATA_KEY_CUSTOM_DATA, customDataDict);
				} else {
					Log.w(LOG_TAG, "Custom data bundle is null. Skipping.");
				}
			} else {
				Log.w(LOG_TAG, "Unexpected custom data type (" + customDataObj.getClass().getName() + "). Skipping.");
			}
		}
		if (json.has(OPTION_KEY_RESTART_APP)) {
			data.put(OPTION_KEY_RESTART_APP, json.opt(OPTION_KEY_RESTART_APP));
		}
	}

	public NotificationData(Intent intent) {
		this.data = new Dictionary();
		if (intent.hasExtra(DATA_KEY_ID)) {
			data.put(DATA_KEY_ID, intent.getIntExtra(DATA_KEY_ID, -1));
		}
		if (intent.hasExtra(DATA_KEY_CHANNEL_ID)) {
			data.put(DATA_KEY_CHANNEL_ID, intent.getStringExtra(DATA_KEY_CHANNEL_ID));
		}
		if (intent.hasExtra(DATA_KEY_TITLE)) {
			data.put(DATA_KEY_TITLE, intent.getStringExtra(DATA_KEY_TITLE));
		}
		if (intent.hasExtra(DATA_KEY_CONTENT)) {
			data.put(DATA_KEY_CONTENT, intent.getStringExtra(DATA_KEY_CONTENT));
		}
		if (intent.hasExtra(DATA_KEY_SMALL_ICON_NAME)) {
			data.put(DATA_KEY_SMALL_ICON_NAME, intent.getStringExtra(DATA_KEY_SMALL_ICON_NAME));
		}
		if (intent.hasExtra(DATA_KEY_LARGE_ICON_NAME)) {
			data.put(DATA_KEY_LARGE_ICON_NAME, intent.getStringExtra(DATA_KEY_LARGE_ICON_NAME));
		}
		if (intent.hasExtra(DATA_KEY_DELAY)) {
			data.put(DATA_KEY_DELAY, intent.getIntExtra(DATA_KEY_DELAY, -1));
		}
		if (intent.hasExtra(DATA_KEY_DEEPLINK)) {
			data.put(DATA_KEY_DEEPLINK, intent.getStringExtra(DATA_KEY_DEEPLINK));
		}
		if (intent.hasExtra(DATA_KEY_INTERVAL)) {
			data.put(DATA_KEY_INTERVAL, intent.getIntExtra(DATA_KEY_INTERVAL, -1));
		}
		if (intent.hasExtra(DATA_KEY_BADGE_COUNT)) {
			data.put(DATA_KEY_BADGE_COUNT, intent.getIntExtra(DATA_KEY_BADGE_COUNT, -1));
		}
		if (intent.hasExtra(DATA_KEY_CUSTOM_DATA)) {
			Bundle bundle = intent.getBundleExtra(DATA_KEY_CUSTOM_DATA);
			if (bundle != null) {
				Dictionary dict = new Dictionary();

				for (String key : bundle.keySet()) {
					@SuppressWarnings("deprecation")
					Object value = bundle.get(key);
					dict.put(key, value);
				}

				data.put(DATA_KEY_CUSTOM_DATA, dict);
			} else {
				Log.w(LOG_TAG, "Custom data bundle is null. Skipping.");
			}
		}
		if (intent.hasExtra(OPTION_KEY_RESTART_APP)) {
			data.put(OPTION_KEY_RESTART_APP, intent.getBooleanExtra(OPTION_KEY_RESTART_APP, true));
		}
	}

	public Integer getId() {
		return (Integer) data.get(DATA_KEY_ID);
	}

	public String getChannelId() {
		return (String) data.get(DATA_KEY_CHANNEL_ID);
	}

	public String getTitle() {
		return (String) data.get(DATA_KEY_TITLE);
	}

	public String getContent() {
		return (String) data.get(DATA_KEY_CONTENT);
	}

	public String getSmallIconName() {
		return (String) data.get(DATA_KEY_SMALL_ICON_NAME);
	}

	public boolean hasLargeIconName() {
		return data.containsKey(DATA_KEY_LARGE_ICON_NAME);
	}

	public String getLargeIconName() {
		return (String) data.get(DATA_KEY_LARGE_ICON_NAME);
	}

	/**
	 * How many seconds from now to schedule first notification
	 */
	public Integer getDelay() {
		return (Integer) data.get(DATA_KEY_DELAY);
	}

	public boolean hasDeeplink() {
		return data.containsKey(DATA_KEY_DEEPLINK);
	}

	/**
	 * URI to process as app link when notification opened
	 */
	public String getDeeplink() {
		return (String) data.get(DATA_KEY_DEEPLINK);
	}

	public boolean hasInterval() {
		return data.containsKey(DATA_KEY_INTERVAL);
	}

	/**
	 * Interval in seconds between each repeating notification
	 */
	public Integer getInterval() {
		return (Integer) data.get(DATA_KEY_INTERVAL);
	}

	public boolean hasBadgeCount() {
		return data.containsKey(DATA_KEY_BADGE_COUNT);
	}

	public Integer getBadgeCount() {
		return (data.containsKey(DATA_KEY_BADGE_COUNT)) ? (Integer) data.get(DATA_KEY_BADGE_COUNT) : (Integer) 0;
	}

	public boolean hasCustomData() {
		return data.containsKey(DATA_KEY_CUSTOM_DATA);
	}

	public Bundle getCustomDataBundle() {
		Bundle bundle = new Bundle();
		Object customDataObj = data.get(DATA_KEY_CUSTOM_DATA);

		if (customDataObj instanceof Dictionary) {
			Dictionary dict = (Dictionary) customDataObj;

			for (Object rawKey : dict.keySet()) {
				// Ensure key is a String
				if (!(rawKey instanceof String)) {
					Log.w(LOG_TAG, "Skipping entry: key is not a String (" +
							(rawKey != null ? rawKey.getClass().getName() : "null") + ")");
					continue;
				}

				String key = (String) rawKey;
				Object value = dict.get(key);

				if (value == null) {
					Log.w(LOG_TAG, "Skipping entry for key '" + key + "': value is null");
					continue;
				}

				// Accept supported types
				if (value instanceof Boolean) {
					bundle.putBoolean(key, (Boolean) value);
				} else if (value instanceof Integer) {
					bundle.putInt(key, (Integer) value);
				} else if (value instanceof Long) {
					bundle.putLong(key, (Long) value);
				} else if (value instanceof Float) {
					bundle.putFloat(key, (Float) value);
				} else if (value instanceof Double) {
					bundle.putDouble(key, (Double) value);
				} else if (value instanceof String) {
					bundle.putString(key, (String) value);
				} else {
					Log.w(LOG_TAG, "Skipping key '" + key + "': unsupported value type " + value.getClass().getName());
				}
			}
		}

		return bundle;
	}

	/**
	 * If enabled, app will be restarted when notification is opened
	 */
	public boolean hasRestartAppOption() {
		return data.containsKey(OPTION_KEY_RESTART_APP);
	}

	public void populateIntent(Intent intent) {
		intent.putExtra(DATA_KEY_ID, this.getId());
		intent.putExtra(DATA_KEY_CHANNEL_ID, this.getChannelId());
		intent.putExtra(DATA_KEY_TITLE, this.getTitle());
		intent.putExtra(DATA_KEY_CONTENT, this.getContent());
		intent.putExtra(DATA_KEY_DELAY, this.getDelay());
		intent.putExtra(DATA_KEY_SMALL_ICON_NAME, this.getSmallIconName());

		if (this.hasLargeIconName()) {
			intent.putExtra(DATA_KEY_LARGE_ICON_NAME, this.getLargeIconName());
		}

		if (this.hasInterval()) {
			intent.putExtra(DATA_KEY_INTERVAL, this.getInterval());
		}

		if (this.hasDeeplink()) {
			intent.putExtra(DATA_KEY_DEEPLINK, this.getDeeplink());
		}

		if (this.getBadgeCount() > 0) {
			intent.putExtra(DATA_KEY_BADGE_COUNT, this.getBadgeCount());
		}

		if (this.hasCustomData()) {
			intent.putExtra(DATA_KEY_CUSTOM_DATA, this.getCustomDataBundle());
		}

		if (this.hasRestartAppOption()) {
			intent.putExtra(OPTION_KEY_RESTART_APP, true);
		}
	}

	public boolean isValid() {
		return data.containsKey(DATA_KEY_ID) &&
				data.containsKey(DATA_KEY_CHANNEL_ID) &&
				data.containsKey(DATA_KEY_TITLE) &&
				data.containsKey(DATA_KEY_CONTENT) &&
				data.containsKey(DATA_KEY_SMALL_ICON_NAME) &&
				data.containsKey(DATA_KEY_DELAY);
	}

	public Notification buildNotification(Context context) {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
			Log.w(LOG_TAG, "buildNotification():: unable to process notification as current SDK is " +
					Build.VERSION.SDK_INT + " and required SDK is " + Build.VERSION_CODES.M);
			return null;
		}

		if (Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU &&
				ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
			Log.w(LOG_TAG, "buildNotification():: unable to build notification as " + Manifest.permission.POST_NOTIFICATIONS
					+ " permission is not granted");
			return null;
		}

		Intent notificationActionIntent = new Intent(context, ResultActivity.class);
		notificationActionIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NO_HISTORY);
		this.populateIntent(notificationActionIntent);

		Intent onDismissIntent = new Intent(context, CancelNotificationReceiver.class);
		this.populateIntent(onDismissIntent);
		PendingIntent onDismissPendingIntent = PendingIntent.getBroadcast(context, 0, onDismissIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
		Log.i(LOG_TAG, String.format("%s():: received notification id:'%d' - channel id:%s - title:'%s' - content:'%s' - small icon name:'%s",
				"onReceive", this.getId(), this.getChannelId(), this.getTitle(), this.getContent(), this.getSmallIconName()));

		PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, notificationActionIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

		Resources resources = context.getResources();
		NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(context, this.getChannelId())
				.setSmallIcon(resources.getIdentifier(this.getSmallIconName(), ICON_RESOURCE_TYPE, context.getPackageName()))
				.setContentTitle(this.getTitle())
				.setContentText(this.getContent())
				.setPriority(NotificationCompat.PRIORITY_DEFAULT)
				.setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
				.setContentIntent(pendingIntent)
				.setDeleteIntent(onDismissPendingIntent)
				.setAutoCancel(true);

		if (this.hasLargeIconName()) {
			int largeIconId = resources.getIdentifier(this.getLargeIconName(), ICON_RESOURCE_TYPE, context.getPackageName());
			
			if (largeIconId != 0) {
				// Use Context to load the drawable (supports Vectors correctly)
				Drawable drawable = null;
				try {
					drawable = context.getDrawable(largeIconId);
				} catch (Resources.NotFoundException e) {
					Log.w(LOG_TAG, "Resource not found for large icon: " + this.getLargeIconName());
				}

				if (drawable != null) {
					Bitmap largeIconBitmap = drawableToBitmap(drawable);
					notificationBuilder.setLargeIcon(largeIconBitmap);
				} else {
					Log.w(LOG_TAG, "Could not load drawable for large icon: " + this.getLargeIconName());
				}
			} else {
				Log.w(LOG_TAG, "Large icon resource ID not found for name: " + this.getLargeIconName());
			}
		}

		if (this.hasBadgeCount()) {
			notificationBuilder.setNumber(this.getBadgeCount());
		}

		return notificationBuilder.build();
	}

	private Bitmap drawableToBitmap(Drawable drawable) {
		if (drawable instanceof BitmapDrawable) {
			return ((BitmapDrawable) drawable).getBitmap();
		}

		// Handle VectorDrawables and other XML drawables
		int width = drawable.getIntrinsicWidth();
		int height = drawable.getIntrinsicHeight();
		
		// Default to a square if intrinsic size is missing (edge case for some XML shapes)
		if (width <= 0 || height <= 0) {
			width = DEFAULT_LARGE_ICON_WIDTH; 
			height = DEFAULT_LARGE_ICON_HEIGHT;
		}

		Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
		Canvas canvas = new Canvas(bitmap);
		drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
		drawable.draw(canvas);
		return bitmap;
	}

	public Dictionary getRawData() {
		return data;
	}
}

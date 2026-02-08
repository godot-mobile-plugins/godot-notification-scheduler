//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification;

import static android.content.Context.ALARM_SERVICE;
import static android.content.Context.NOTIFICATION_SERVICE;

import android.Manifest;
import android.app.Activity;
import android.app.AlarmManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.icu.util.Calendar;
import android.os.Build;
import android.os.PowerManager;
import android.util.Log;
import android.view.View;
import android.provider.Settings;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.collection.ArraySet;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationManagerCompat;

import org.godotengine.godot.Dictionary;
import org.godotengine.godot.Godot;
import org.godotengine.godot.error.Error;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import org.godotengine.plugin.notification.model.ChannelData;
import org.godotengine.plugin.notification.model.NotificationData;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

public class NotificationSchedulerPlugin extends GodotPlugin {
	public static final String CLASS_NAME = NotificationSchedulerPlugin.class.getSimpleName();
	public static final String LOG_TAG = "godot::" + CLASS_NAME;

	static NotificationSchedulerPlugin instance;

	private static final SignalInfo INITIALIZATION_COMPLETED_SIGNAL = new SignalInfo("initialization_completed");
	private static final SignalInfo POST_NOTIFICATIONS_PERMISSION_GRANTED_SIGNAL = new SignalInfo("post_notifications_permission_granted", String.class);
	private static final SignalInfo POST_NOTIFICATIONS_PERMISSION_DENIED_SIGNAL = new SignalInfo("post_notifications_permission_denied", String.class);
	private static final SignalInfo BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL = new SignalInfo("battery_optimizations_permission_granted", String.class);
	private static final SignalInfo BATTERY_OPTIMIZATIONS_PERMISSION_DENIED_SIGNAL = new SignalInfo("battery_optimizations_permission_denied", String.class);
	private static final SignalInfo NOTIFICATION_OPENED_SIGNAL = new SignalInfo("notification_opened", Dictionary.class);
	private static final SignalInfo NOTIFICATION_DISMISSED_SIGNAL = new SignalInfo("notification_dismissed", Dictionary.class);

	private static final String PREF_NAME = CLASS_NAME + "_prefs";
	private static final String KEY_PENDING_DISMISSED = "pending_dismissed_ids";
	private static final String KEY_SCHEDULED_NOTIFICATIONS = "scheduled_notifications";
	private static final String DATA_KEY_FIRE_TIME = "fire_time_ms"; // Internal key for absolute time

	private static final int POST_NOTIFICATIONS_PERMISSION_REQUEST_CODE = 11803;
	private static final int BATTERY_OPTIMIZATIONS_PERMISSION_REQUEST_CODE = 11804;

	private static final List<NotificationData> pendingOpenedNotifications = new ArrayList<>();

	// Record of IDs we have already handled to prevent duplicates (using a Set ensures O(1) lookup time)
	private static final Set<Integer> processedNotificationIds = new HashSet<>();

	private Activity activity;
	private boolean isInitialized;

	public NotificationSchedulerPlugin(Godot godot) {
		super(godot);
		isInitialized = false;
	}

	/**
	 * Initializes plugin.
	 */
	@UsedByGodot
	public void initialize() {
		isInitialized = true;

		// Nothing to do on Android version (implemented for platform parity)
		emitSignal(getGodot(), getPluginName(), INITIALIZATION_COMPLETED_SIGNAL);
	}

	/**
	 * Creates a notification channel with given ID. If a channel already exists with the given ID,
	 * then the call will be ignored.
	 *
	 * @param data dictionary containing channel ID, channel name, and channel description
	 */
	@RequiresApi(api = Build.VERSION_CODES.O)
	@UsedByGodot
	public int create_notification_channel(Dictionary data) {
		if (!isInitialized) {
			Log.e(LOG_TAG, "create_notification_channel(): plugin is not initialized!");
			return Error.ERR_UNCONFIGURED.toNativeValue();
		}

		ChannelData channelData = new ChannelData(data);
		if (channelData.isValid()) {
			NotificationManager manager = (NotificationManager) activity.getSystemService(NOTIFICATION_SERVICE);

			// Check if channel already exists
			if (manager.getNotificationChannel(channelData.getId()) == null) {
				NotificationChannel channel = new NotificationChannel(channelData.getId(), channelData.getName(),
						channelData.getImportance());
				channel.setDescription(channelData.getDescription());
				channel.setShowBadge(channelData.getBadgeEnabled());
				manager.createNotificationChannel(channel);
				Log.d(LOG_TAG, String.format("%s():: channel id: %s, name: %s, description: %s",
						"create_notification_channel", channelData.getId(), channelData.getName(), channelData.getDescription()));
			} else {
				Log.d(LOG_TAG, String.format("%s():: channel id: %s already exists",
						"create_notification_channel", channelData.getId()));
				return Error.ERR_ALREADY_EXISTS.toNativeValue();
			}
		} else {
			Log.e(LOG_TAG, "create_notification_channel(): invalid channel data object");
			return Error.ERR_INVALID_DATA.toNativeValue();
		}

		return Error.OK.toNativeValue();
	}

	/**
	 * Schedule single, non-repeating notification
	 *
	 * @param data dictionary containing notification data, including delaySeconds that specifies
	 *				how many seconds from now to schedule the notification.
	*/
	@UsedByGodot
	public int schedule(Dictionary data) {
		if (!isInitialized) {
			Log.e(LOG_TAG, "schedule(): plugin is not initialized!");
			return Error.ERR_UNCONFIGURED.toNativeValue();
		}

		NotificationData notificationData = new NotificationData(data);
		Log.d(LOG_TAG, "schedule():: notification id: " + notificationData.getId());

		if (notificationData.isValid()) {
			// Calculate absolute fire time for persistence
			long fireTime = calculateTimeAfterDelay(notificationData.getDelay());
			
			// Persist the notification data
			saveScheduledNotification(activity, notificationData, fireTime);

			// Schedule the alarm
			if (notificationData.hasInterval()) {
				scheduleRepeatingNotification(activity, notificationData, fireTime);
			} else {
				scheduleNotification(activity, notificationData, fireTime);
			}
		} else {
			Log.e(LOG_TAG, "schedule(): invalid notification data object");
			return Error.ERR_INVALID_DATA.toNativeValue();
		}

		return Error.OK.toNativeValue();
	}

	/**
	 * Cancel notification with given ID
	 *
	 * @param notificationId ID of notification to cancel
	 */
	@UsedByGodot
	public int cancel(int notificationId) {
		if (!isInitialized) {
			Log.e(LOG_TAG, "cancel(): plugin is not initialized!");
			return Error.ERR_UNCONFIGURED.toNativeValue();
		}

		// Remove from persistence
		removeScheduledNotification(activity, notificationId);
		
		// Cancel alarm
		cancelNotification(activity, notificationId);
		Log.d(LOG_TAG, "cancel():: notification id: " + notificationId);

		return Error.OK.toNativeValue();
	}

	@UsedByGodot
	public int set_badge_count(int badgeCount) {
		if (!isInitialized) {
			Log.e(LOG_TAG, "set_badge_count(): plugin is not initialized!");
			return Error.ERR_UNCONFIGURED.toNativeValue();
		}

		Log.e(LOG_TAG, "set_badge_count(): method not supported on Android");
		return Error.ERR_UNAVAILABLE.toNativeValue();
	}

	/**
	 * Return notification ID if it exists in current intent, else return {@code defaultValue}
	 *
	 * @param defaultValue value to return if notification ID does not exist
	 */
	@UsedByGodot
	public int get_notification_id(int defaultValue) {
		if (!isInitialized) {
			Log.e(LOG_TAG, "get_notification_id(): plugin is not initialized!");
			return defaultValue;
		}

		int notificationId = defaultValue;
		Activity activity = getActivity();
		if (activity != null) {
			Intent intent = getActivity().getIntent();
			if (intent.hasExtra(NotificationData.DATA_KEY_ID)) {
				notificationId = intent.getIntExtra(NotificationData.DATA_KEY_ID, defaultValue);
				Log.i(LOG_TAG, "get_notification_id():: intent with notification id: " + notificationId);
			} else {
				Log.i(LOG_TAG, "get_notification_id():: notification id not found");
			}
		}
		return notificationId;
	}

	/**
	 * Returns true if app has already been granted POST_NOTIFICATIONS permissions
	 */
	@UsedByGodot
	public boolean has_post_notifications_permission() {
		if (!isInitialized) {
			Log.e(LOG_TAG, "has_post_notifications_permission(): plugin is not initialized!");
			return false;
		}

		boolean result = false;
		if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
			if (NotificationManagerCompat.from(activity.getApplicationContext()).areNotificationsEnabled()) {
				result = true;
			}
		} else {
			result = true;
			Log.d(LOG_TAG, "has_post_notifications_permission():: API level is " + Build.VERSION.SDK_INT);
		}
		return result;
	}

	/**
	 * Sends a request to acquire POST_NOTIFICATIONS permission for the app
	 */
	@UsedByGodot
	public int request_post_notifications_permission() {
		if (!isInitialized) {
			Log.e(LOG_TAG, "request_post_notifications_permission(): plugin is not initialized!");
			return Error.ERR_UNCONFIGURED.toNativeValue();
		}

		try {
			if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
				ActivityCompat.requestPermissions(activity, new String[]{ Manifest.permission.POST_NOTIFICATIONS },
						POST_NOTIFICATIONS_PERMISSION_REQUEST_CODE);
			} else {
				Log.i(LOG_TAG, "request_post_notifications_permission():: can't request permission, because SDK version is " + Build.VERSION.SDK_INT);
			}
		} catch (Exception e) {
			Log.e(LOG_TAG, "request_post_notifications_permission():: Failed to request permission due to " + e.getMessage());
		}

		return Error.OK.toNativeValue();
	}

	/**
	 * Checks if the app is already on the battery optimization whitelist.
	 */
	@UsedByGodot
	public boolean is_ignoring_battery_optimizations() {
		if (!isInitialized) {
			Log.e(LOG_TAG, "is_ignoring_battery_optimizations(): plugin is not initialized!");
			return false;
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			PowerManager powerManager = (PowerManager) activity.getSystemService(Context.POWER_SERVICE);
			return powerManager.isIgnoringBatteryOptimizations(activity.getPackageName());
		} else {
			Log.i(LOG_TAG, "is_ignoring_battery_optimizations():: can't check permission, because SDK version is " + Build.VERSION.SDK_INT);
		}
		return true;
	}

	/**
	 * Requests the user to disable battery optimizations for this app.
	 * Triggers a system dialog.
	 */
	@UsedByGodot
	public int request_ignore_battery_optimizations_permission() {
		if (!isInitialized) {
			Log.e(LOG_TAG, "request_ignore_battery_optimizations_permission(): plugin is not initialized!");
			return Error.ERR_UNCONFIGURED.toNativeValue();
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			if (is_ignoring_battery_optimizations()) {
				// Already granted
				emitSignal(getGodot(), getPluginName(), BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL);
				return Error.OK.toNativeValue();
			}

			try {
				Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
				intent.setData(Uri.parse("package:" + activity.getPackageName()));
				activity.startActivityForResult(intent, BATTERY_OPTIMIZATIONS_PERMISSION_REQUEST_CODE);
			} catch (Exception e) {
				Log.e(LOG_TAG, "request_ignore_battery_optimizations_permission():: Failed due to " + e.getMessage());
				return Error.FAILED.toNativeValue();
			}
		} else {
			// Not applicable on older Android versions, effectively granted
			emitSignal(getGodot(), getPluginName(), BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL);
		}

		return Error.OK.toNativeValue();
	}

	/**
	 * Opens APP INFO settings screen
	 */
	@UsedByGodot
	public int open_app_info_settings() {
		if (!isInitialized) {
			Log.e(LOG_TAG, "open_app_info_settings(): plugin is not initialized!");
			return Error.ERR_UNCONFIGURED.toNativeValue();
		}

		Log.d(LOG_TAG, "open_app_info_settings()");

		try {
			Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			Uri uri = Uri.fromParts("package", activity.getPackageName(), null);
			intent.setData(uri);
			activity.startActivity(intent);
		} catch (Exception e) {
			Log.e(LOG_TAG, "open_app_info_settings():: Failed due to "+ e.getMessage());
		}

		return Error.OK.toNativeValue();
	}

	@NonNull
	@Override
	public String getPluginName() {
		return this.getClass().getSimpleName();
	}

	@NonNull
	@Override
	public Set<SignalInfo> getPluginSignals() {
		Set<SignalInfo> signals = new ArraySet<>();
		signals.add(INITIALIZATION_COMPLETED_SIGNAL);
		signals.add(NOTIFICATION_OPENED_SIGNAL);
		signals.add(NOTIFICATION_DISMISSED_SIGNAL);
		signals.add(POST_NOTIFICATIONS_PERMISSION_GRANTED_SIGNAL);
		signals.add(POST_NOTIFICATIONS_PERMISSION_DENIED_SIGNAL);
		signals.add(BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL);
		signals.add(BATTERY_OPTIMIZATIONS_PERMISSION_DENIED_SIGNAL);
		return signals;
	}

	@Nullable
	@Override
	public View onMainCreate(Activity activity) {
		this.activity = activity;
		instance = this;
		return super.onMainCreate(activity);
	}

	@Override
	public void onGodotSetupCompleted() {
		super.onGodotSetupCompleted();

		if (this.activity != null) {
			if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
				if (NotificationManagerCompat.from(this.activity.getApplicationContext()).areNotificationsEnabled()) {
					Log.i(LOG_TAG, "onGodotSetupCompleted():: POST_NOTIFICATIONS permission has already been granted");
				}
			}

			// Flush pending OPENED notifications
			if (!pendingOpenedNotifications.isEmpty()) {
				for (NotificationData data : pendingOpenedNotifications) {
					emitSignal(getGodot(), getPluginName(), NOTIFICATION_OPENED_SIGNAL, data.getRawData());
					processedNotificationIds.add(data.getId()); // Mark as processed
					Log.i(LOG_TAG, "onGodotSetupCompleted():: Flushed queued OPEN event for ID: " + data.getId());
				}
				pendingOpenedNotifications.clear();
			}

			Context context = activity.getApplicationContext();
			SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
			
			// Retrieve the set of JSON strings
			Set<String> dismissedJsonSet = prefs.getStringSet(KEY_PENDING_DISMISSED, new HashSet<>());
			if (!dismissedJsonSet.isEmpty()) {
				Log.i(LOG_TAG, "Found " + dismissedJsonSet.size() + " dismissed notifications in storage.");

				for (String notificationJson : dismissedJsonSet) {
					try {
						Log.d(LOG_TAG, "Processing JSON dismissed notification data: " + notificationJson);

						// Convert JSON String back to Godot Dictionary
						JSONObject jsonObject = new JSONObject(notificationJson);
						NotificationData dismissedData = new NotificationData(jsonObject);
						emitSignal(getGodot(), getPluginName(), NOTIFICATION_DISMISSED_SIGNAL, dismissedData.getRawData());

						// Mark ID as processed
						processedNotificationIds.add(dismissedData.getId()); 
						
						Log.i(LOG_TAG, "Emitted signal for stored dismissed ID: " + dismissedData.getId());
						
					} catch (JSONException e) {
						Log.e(LOG_TAG, "Failed to parse stored JSON for dismissed notification.", e);
					}
				}

				// Clear the storage
				prefs.edit().remove(KEY_PENDING_DISMISSED).apply();
			}

			// Check the launch ("cold start") Intent
			NotificationData intentData = new NotificationData(this.activity.getIntent());

			if (intentData.isValid()) {
				int id = intentData.getId();
				
				// Check if we already processed this ID from the pending queue
				if (!processedNotificationIds.contains(id)) {
					// It's a new one (likely the app was launched directly by the intent, not the receiver)
					handleNotificationOpened(intentData); 
					Log.i(LOG_TAG, "onGodotSetupCompleted():: Processed Intent data for ID: " + id);
				} else {
					Log.i(LOG_TAG, "onGodotSetupCompleted():: Skipping Intent data for ID: " + id + " (Already processed via queue)");
				}
			}
		} else {
			Log.e(LOG_TAG, "onGodotSetupCompleted():: activity is null!");
		}
	}

	@Override
	public void onMainDestroy() {
		instance = null;
		processedNotificationIds.clear();
		pendingOpenedNotifications.clear();
		super.onMainDestroy();
	}

	// Handle the result of the system dialog
	@Override
	public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
		super.onMainActivityResult(requestCode, resultCode, data);

		if (requestCode == BATTERY_OPTIMIZATIONS_PERMISSION_REQUEST_CODE) {
			// Check the state again to be sure, as resultCode can sometimes be misleading for this specific intent
			if (is_ignoring_battery_optimizations()) {
				Log.d(LOG_TAG, "onMainActivityResult():: battery optimization permission granted");
				emitSignal(getGodot(), getPluginName(), BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL,
						Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
			} else {
				Log.d(LOG_TAG, "onMainActivityResult():: battery optimization permission denied");
				emitSignal(getGodot(), getPluginName(), BATTERY_OPTIMIZATIONS_PERMISSION_DENIED_SIGNAL,
						Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
			}
		}
	}

	@Override
	public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
		super.onMainRequestPermissionsResult(requestCode, permissions, grantResults);

		if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
			if (requestCode == POST_NOTIFICATIONS_PERMISSION_REQUEST_CODE) {
				// If request is cancelled, the result arrays are empty.
				if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
					Log.d(LOG_TAG, "onMainRequestPermissionsResult():: permission request granted");
					emitSignal(getGodot(), getPluginName(), POST_NOTIFICATIONS_PERMISSION_GRANTED_SIGNAL, Manifest.permission.POST_NOTIFICATIONS);
				} else {
					Log.d(LOG_TAG, "onMainRequestPermissionsResult():: permission request denied");
					emitSignal(getGodot(), getPluginName(), POST_NOTIFICATIONS_PERMISSION_DENIED_SIGNAL, Manifest.permission.POST_NOTIFICATIONS);
				}
			}
		} else {
			Log.e(LOG_TAG, "onMainRequestPermissionsResult():: can't check permission result, because SDK version is " + Build.VERSION.SDK_INT);
		}
	}

	static void handleNotificationOpened(NotificationData notificationData) {
		if (instance != null) {
			// Plugin is ready, emit immediately
			instance.emitSignal(instance.getGodot(), instance.getPluginName(), NOTIFICATION_OPENED_SIGNAL, notificationData.getRawData());
			// Mark as processed so we don't handle it again from the Intent
			processedNotificationIds.add(notificationData.getId());
		} else {
			// Plugin not ready, queue it
			Log.i(LOG_TAG, "handleNotificationOpened():: Plugin not ready, queueing event ID: " + notificationData.getId());
			pendingOpenedNotifications.add(notificationData);
		}
	}

	static void handleNotificationDismissed(Context context, NotificationData notificationData) {
		if (instance != null) {
			instance.emitSignal(instance.getGodot(), instance.getPluginName(), NOTIFICATION_DISMISSED_SIGNAL, notificationData.getRawData());
		} else {
			// App is not running or not ready. Persist the full object to disk.
			Log.i(LOG_TAG, "Plugin not ready. Persisting full dismissed data for ID: " + notificationData.getId());
			saveDismissedDataToPrefs(context, notificationData);
		}
	}

	/**
	 * Saves the notification data to SharedPreferences so it can be restored on reboot.
	 */
	private static void saveScheduledNotification(Context context, NotificationData data, long fireTime) {
		try {
			SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
			JSONObject json = new JSONObject(data.getRawData());
			
			// Inject the absolute fire time into the JSON so we know when it was supposed to fire
			json.put(DATA_KEY_FIRE_TIME, fireTime);

			String jsonString = json.toString();
			
			// Store in a separate shared prefs map: key=ID, value=JSON
			SharedPreferences schedulePrefs = context.getSharedPreferences(KEY_SCHEDULED_NOTIFICATIONS, Context.MODE_PRIVATE);
			schedulePrefs.edit().putString(String.valueOf(data.getId()), jsonString).apply();
			
			Log.d(LOG_TAG, "Persisted notification " + data.getId() + " for reboot handling.");
		} catch (JSONException e) {
			Log.e(LOG_TAG, "Failed to save scheduled notification: " + e.getMessage());
		}
	}

	/**
	 * Removes a notification from persistence (called when cancelled or fired).
	 */
	public static void removeScheduledNotification(Context context, int notificationId) {
		SharedPreferences schedulePrefs = context.getSharedPreferences(KEY_SCHEDULED_NOTIFICATIONS, Context.MODE_PRIVATE);
		if (schedulePrefs.contains(String.valueOf(notificationId))) {
			schedulePrefs.edit().remove(String.valueOf(notificationId)).apply();
			Log.d(LOG_TAG, "Removed notification " + notificationId + " from persistence.");
		}
	}

	/**
	 * Called by BootReceiver to restore alarms.
	 */
	public static void rescheduleAll(Context context) {
		SharedPreferences schedulePrefs = context.getSharedPreferences(KEY_SCHEDULED_NOTIFICATIONS, Context.MODE_PRIVATE);
		Map<String, ?> allEntries = schedulePrefs.getAll();

		if (allEntries.isEmpty()) {
			Log.i(LOG_TAG, "No scheduled notifications to restore.");
			return;
		}

		for (Map.Entry<String, ?> entry : allEntries.entrySet()) {
			try {
				String jsonString = (String) entry.getValue();
				JSONObject json = new JSONObject(jsonString);
				
				// Extract the absolute fire time we saved earlier
				long fireTime = json.optLong(DATA_KEY_FIRE_TIME, -1);
				
				// Reconstruct data
				NotificationData data = new NotificationData(json);
				
				if (!data.isValid() || fireTime == -1) {
					// Cleanup invalid data
					removeScheduledNotification(context, Integer.parseInt(entry.getKey()));
					continue;
				}

				if (data.hasInterval()) {
					scheduleRepeatingNotification(context, data, fireTime);
				} else {
					// Check if the time has already passed for a one-time notification
					if (System.currentTimeMillis() > fireTime) {
						Log.w(LOG_TAG, "Notification " + data.getId() + " expired while device was off. Firing immediately.");
						// Standard behavior for missed alarms is to fire immediately or discard. 
						// setExact/set calls with past time usually trigger immediately.
					}
					scheduleNotification(context, data, fireTime);
				}

				Log.i(LOG_TAG, "Restored notification: " + data.getId());

			} catch (Exception e) {
				Log.e(LOG_TAG, "Failed to restore notification: " + e.getMessage());
			}
		}
	}

	/**
	 * Saves the full NotificationData as a JSON string to SharedPreferences.
	 */
	public static void saveDismissedDataToPrefs(Context context, NotificationData notificationData) {
		try {
			// Convert Dictionary (Map) to JSONObject
			JSONObject jsonObject = new JSONObject(notificationData.getRawData());
			String notificationJson = jsonObject.toString();

			SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);

			// Use a Set to store multiple JSON strings (for multiple pending dismissals)
			Set<String> dismissedData = prefs.getStringSet(KEY_PENDING_DISMISSED, new HashSet<>());

			Set<String> newSet = new HashSet<>(dismissedData);
			newSet.add(notificationJson);

			prefs.edit().putStringSet(KEY_PENDING_DISMISSED, newSet).apply();
			Log.d(LOG_TAG, "Saved full dismissed data to prefs: " + notificationJson);
		} catch (Exception e) {
			Log.e(LOG_TAG, "Failed to save NotificationData to SharedPreferences", e);
		}
	}

	private static long calculateTimeAfterDelay(int delaySeconds) {
		Calendar calendar = Calendar.getInstance();
		calendar.add(Calendar.SECOND, delaySeconds);
		return calendar.getTimeInMillis();
	}

	private static void scheduleNotification(Context context, NotificationData notificationData, long fireTime) {
		int notificationId = notificationData.getId();

		Intent intent = new Intent(context, NotificationReceiver.class);
		notificationData.populateIntent(intent);

		AlarmManager alarmManager = (AlarmManager) context.getSystemService(ALARM_SERVICE);
		
		PendingIntent pendingIntent = PendingIntent.getBroadcast(context, notificationId, intent,
						PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireTime, pendingIntent);
		} else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
			alarmManager.setExact(AlarmManager.RTC_WAKEUP, fireTime, pendingIntent);
		} else {
			alarmManager.set(AlarmManager.RTC_WAKEUP, fireTime, pendingIntent);
		}
		Log.i(LOG_TAG, String.format("Scheduled notification '%d' to be delivered at %d.", notificationId, fireTime));
	}

	private static void scheduleRepeatingNotification(Context context, NotificationData notificationData, long fireTime) {
		int notificationId = notificationData.getId();

		Intent intent = new Intent(context, NotificationReceiver.class);
		notificationData.populateIntent(intent);

		AlarmManager alarmManager = (AlarmManager) context.getSystemService(ALARM_SERVICE);
		
		int intervalSeconds = notificationData.getInterval();

		alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, fireTime, intervalSeconds * 1000L,
				PendingIntent.getBroadcast(context, notificationId, intent,
						PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));

		Log.i(LOG_TAG, String.format("Scheduled notification '%d' to be delivered at %d with %ds interval.", notificationId, fireTime, intervalSeconds));
	}

	private void cancelNotification(Activity activity, int notificationId) {
		Context context = activity.getApplicationContext();
		// cancel alarm
		AlarmManager alarmManager = (AlarmManager) activity.getSystemService(ALARM_SERVICE);
		Intent intent = new Intent(context, NotificationReceiver.class);
		intent.putExtra(NotificationData.DATA_KEY_ID, notificationId);
		alarmManager.cancel(PendingIntent.getBroadcast(activity.getApplicationContext(), notificationId, intent,
				PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));

		// cancel notification
		NotificationManagerCompat.from(context).cancel(notificationId);
	}

}

//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification.model;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Intent;
import android.os.Build;

import androidx.annotation.RequiresApi;

import org.godotengine.godot.Dictionary;

import org.godotengine.plugin.notification.NotificationSchedulerPlugin;

import org.json.JSONException;
import org.json.JSONObject;

public class ChannelData {
	private static final String LOG_TAG = NotificationSchedulerPlugin.LOG_TAG + "::"
			+ ChannelData.class.getSimpleName();

	private static String DATA_KEY_ID = "channel_id";
	private static String DATA_KEY_NAME = "channel_name";
	private static String DATA_KEY_DESCRIPTION = "channel_description";
	private static String DATA_KEY_IMPORTANCE = "channel_importance";
	private static String DATA_KEY_BADGE_ENABLED = "badge_enabled";

	private static String DEFAULT_NAME = "Default Channel";
	private static String DEFAULT_DESCRIPTION = "Notifications channel";
	private static int DEFAULT_IMPORTANCE = NotificationManager.IMPORTANCE_DEFAULT;
	private static boolean DEFAULT_BADGE_ENABLED = true;

	private Dictionary data;

	public ChannelData(String id) {
		this.data = new Dictionary();
		data.put(DATA_KEY_ID, id);
		data.put(DATA_KEY_NAME, DEFAULT_NAME);
		data.put(DATA_KEY_DESCRIPTION, DEFAULT_DESCRIPTION);
		data.put(DATA_KEY_IMPORTANCE, (long) DEFAULT_IMPORTANCE);
		data.put(DATA_KEY_BADGE_ENABLED, DEFAULT_BADGE_ENABLED);
	}

	public ChannelData(Dictionary data) {
		this.data = data;
	}

	public ChannelData(String id, JSONObject json) throws JSONException {
		this.data = new Dictionary();
		data.put(DATA_KEY_ID, id);
		data.put(DATA_KEY_NAME, json.optString(DATA_KEY_NAME, DEFAULT_NAME));
		data.put(DATA_KEY_DESCRIPTION, json.optString(DATA_KEY_DESCRIPTION, DEFAULT_DESCRIPTION));
		data.put(DATA_KEY_IMPORTANCE, (long) json.optInt(DATA_KEY_IMPORTANCE, DEFAULT_IMPORTANCE));
		data.put(DATA_KEY_BADGE_ENABLED, json.optBoolean(DATA_KEY_BADGE_ENABLED, DEFAULT_BADGE_ENABLED));
	}

	public ChannelData(Intent intent) {
		this.data = new Dictionary();
		if (intent.hasExtra(DATA_KEY_ID)) {
			data.put(DATA_KEY_ID, intent.getStringExtra(DATA_KEY_ID));
		}
		if (intent.hasExtra(DATA_KEY_NAME)) {
			data.put(DATA_KEY_NAME, intent.getStringExtra(DATA_KEY_NAME));
		}
		if (intent.hasExtra(DATA_KEY_DESCRIPTION)) {
			data.put(DATA_KEY_DESCRIPTION, intent.getStringExtra(DATA_KEY_DESCRIPTION));
		}
		if (intent.hasExtra(DATA_KEY_IMPORTANCE)) {
			data.put(DATA_KEY_IMPORTANCE, (long) intent.getIntExtra(DATA_KEY_IMPORTANCE, DEFAULT_IMPORTANCE));
		}
		if (intent.hasExtra(DATA_KEY_BADGE_ENABLED)) {
			data.put(DATA_KEY_BADGE_ENABLED, intent.getBooleanExtra(DATA_KEY_BADGE_ENABLED, DEFAULT_BADGE_ENABLED));
		}
	}

	public ChannelData(NotificationChannel channel) {
		this.data = new Dictionary();
		data.put(DATA_KEY_ID, channel.getId());
		data.put(DATA_KEY_NAME, channel.getName().toString());
		data.put(DATA_KEY_DESCRIPTION, channel.getDescription());
		data.put(DATA_KEY_IMPORTANCE, (long) channel.getImportance());
		data.put(DATA_KEY_BADGE_ENABLED, channel.canShowBadge());
	}

	public String getId() {
		return (String) data.get(DATA_KEY_ID);
	}

	public String getName() {
		return (String) data.get(DATA_KEY_NAME);
	}

	public String getDescription() {
		return (String) data.get(DATA_KEY_DESCRIPTION);
	}

	public int getImportance() {
		return ((Long) data.get(DATA_KEY_IMPORTANCE)).intValue();
	}

	public boolean getBadgeEnabled() {
		return (boolean) data.get(DATA_KEY_BADGE_ENABLED);
	}

	@RequiresApi(api = Build.VERSION_CODES.N)
	public boolean isValid() {
		if (data.containsKey(DATA_KEY_IMPORTANCE) == false) {
			data.put(DATA_KEY_IMPORTANCE, DEFAULT_IMPORTANCE);
		}

		if (data.containsKey(DATA_KEY_BADGE_ENABLED) == false) {
			data.put(DATA_KEY_BADGE_ENABLED, DEFAULT_BADGE_ENABLED);
		}

		return data.containsKey(DATA_KEY_ID) &&
				data.containsKey(DATA_KEY_NAME) &&
				data.containsKey(DATA_KEY_DESCRIPTION);
	}

	public void populateIntent(Intent intent) {
		intent.putExtra(DATA_KEY_ID, this.getId());
		intent.putExtra(DATA_KEY_NAME, this.getName());
		intent.putExtra(DATA_KEY_DESCRIPTION, this.getDescription());
		intent.putExtra(DATA_KEY_IMPORTANCE, this.getImportance());
		if (this.data.containsKey(DATA_KEY_BADGE_ENABLED)) {
			intent.putExtra(DATA_KEY_BADGE_ENABLED, this.getBadgeEnabled());
		}
	}

	public JSONObject toJson() throws JSONException {
		JSONObject json = new JSONObject();

		json.put(DATA_KEY_ID, getId());
		json.put(DATA_KEY_NAME, getName());
		json.put(DATA_KEY_DESCRIPTION, getDescription());
		json.put(DATA_KEY_IMPORTANCE, getImportance());
		json.put(DATA_KEY_BADGE_ENABLED, getBadgeEnabled());

		return json;
	}

	public NotificationChannel toNotificationChannel() {
		NotificationChannel channel = new NotificationChannel(getId(), getName(), getImportance());
		channel.setDescription(getDescription());
		channel.setShowBadge(getBadgeEnabled());

		return channel;
	}
}

//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification.model;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;

import androidx.annotation.RequiresApi;

import org.godotengine.godot.Dictionary;

import org.json.JSONException;
import org.json.JSONObject;

public class ChannelData {

	private static String DATA_KEY_ID = "id";
	private static String DATA_KEY_NAME = "name";
	private static String DATA_KEY_DESCRIPTION = "description";
	private static String DATA_KEY_IMPORTANCE = "importance";
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
		data.put(DATA_KEY_IMPORTANCE, DEFAULT_IMPORTANCE);
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
		data.put(DATA_KEY_IMPORTANCE, json.optInt(DATA_KEY_IMPORTANCE, DEFAULT_IMPORTANCE));
		data.put(DATA_KEY_BADGE_ENABLED, json.optBoolean(DATA_KEY_BADGE_ENABLED, DEFAULT_BADGE_ENABLED));
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
		return (int) data.get(DATA_KEY_IMPORTANCE);
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

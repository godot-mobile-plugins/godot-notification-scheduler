//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification.model.fixture;

import android.content.Intent;
import android.os.Bundle;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.notification.model.NotificationData;
import org.json.JSONObject;

import java.util.Arrays;

import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;

/**
 * Test fixtures for {@link NotificationData}.
 *
 * <p><strong>Why lenient stubs?</strong><br>
 * {@code NotificationData(Intent)} calls {@code intent.hasExtra(key)} for every
 * possible key in sequence.  Stubbing only the keys relevant to a test while using
 * strict mode causes Mockito to raise {@code PotentialStubbingProblem} when the
 * constructor reaches an unstubbed key.  {@code lenient()} suppresses that check.
 *
 * <p><strong>Why mocked JSONObject?</strong><br>
 * {@code org.json.JSONObject} ships inside the Android SDK stub jar.  With
 * {@code isReturnDefaultValues = true}, every call ({@code has}, {@code opt}, etc.)
 * returns the default Java value ({@code null}/{@code false}) instead of the value
 * that was stored.  Mockito mocks let us control those return values precisely.
 */
public final class NotificationDataFixture {

	// ---- Stable test values ------------------------------------------------

	public static final int    DEFAULT_ID = 42;
	public static final String DEFAULT_CHANNEL_ID = "test-channel";
	public static final String DEFAULT_TITLE = "Test Notification";
	public static final String DEFAULT_CONTENT = "Test notification content";
	public static final String DEFAULT_SMALL_ICON = "ic_notification";
	public static final int    DEFAULT_DELAY = 60;
	public static final int    DEFAULT_INTERVAL = 3_600;
	public static final String DEFAULT_DEEPLINK = "myapp://screen/home";
	public static final int    DEFAULT_BADGE_COUNT = 5;
	public static final String DEFAULT_LARGE_ICON = "ic_large_notification";

	private NotificationDataFixture() {
	}

	// ---- Dictionary helpers ------------------------------------------------

	/** The six fields required for {@link NotificationData#isValid()} to return {@code true}. */
	public static Dictionary minimalDictionary() {
		Dictionary d = new Dictionary();
		d.put(NotificationData.DATA_KEY_ID, DEFAULT_ID);
		d.put(NotificationData.DATA_KEY_CHANNEL_ID, DEFAULT_CHANNEL_ID);
		d.put(NotificationData.DATA_KEY_TITLE, DEFAULT_TITLE);
		d.put(NotificationData.DATA_KEY_CONTENT, DEFAULT_CONTENT);
		d.put(NotificationData.DATA_KEY_SMALL_ICON_NAME, DEFAULT_SMALL_ICON);
		d.put(NotificationData.DATA_KEY_DELAY, DEFAULT_DELAY);
		return d;
	}

	/** All required fields plus every optional field. */
	public static Dictionary fullDictionary() {
		Dictionary d = minimalDictionary();
		d.put(NotificationData.DATA_KEY_LARGE_ICON_NAME, DEFAULT_LARGE_ICON);
		d.put(NotificationData.DATA_KEY_INTERVAL, DEFAULT_INTERVAL);
		d.put(NotificationData.DATA_KEY_DEEPLINK, DEFAULT_DEEPLINK);
		d.put(NotificationData.DATA_KEY_BADGE_COUNT, DEFAULT_BADGE_COUNT);
		d.put(NotificationData.OPTION_KEY_RESTART_APP, true);
		return d;
	}

	/** Minimal dictionary augmented with a nested custom-data Dictionary. */
	public static Dictionary dictionaryWithCustomData() {
		Dictionary customData = new Dictionary();
		customData.put("string_key", "hello");
		customData.put("int_key", 42);
		customData.put("bool_key", true);
		customData.put("long_key", 100L);
		customData.put("float_key", 3.14f);
		customData.put("double_key", 2.718);

		Dictionary d = minimalDictionary();
		d.put(NotificationData.DATA_KEY_CUSTOM_DATA, customData);
		return d;
	}

	// ---- JSON (mock) helpers -----------------------------------------------

	/**
	 * Mocked {@link JSONObject} whose {@code has}/{@code opt} calls return the six
	 * required {@link NotificationData} fields.
	 *
	 * <p>{@code NotificationData(JSONObject)} uses {@code json.has(key)} as a guard
	 * before calling {@code json.opt(key)}, so both methods are stubbed for each key.
	 */
	public static JSONObject minimalJson() {
		JSONObject j = mock(JSONObject.class);
		stubJsonField(j, NotificationData.DATA_KEY_ID, DEFAULT_ID);
		stubJsonField(j, NotificationData.DATA_KEY_CHANNEL_ID, DEFAULT_CHANNEL_ID);
		stubJsonField(j, NotificationData.DATA_KEY_TITLE, DEFAULT_TITLE);
		stubJsonField(j, NotificationData.DATA_KEY_CONTENT, DEFAULT_CONTENT);
		stubJsonField(j, NotificationData.DATA_KEY_SMALL_ICON_NAME, DEFAULT_SMALL_ICON);
		stubJsonField(j, NotificationData.DATA_KEY_DELAY, DEFAULT_DELAY);
		return j;
	}

	/** Minimal mock JSON plus all optional fields. */
	public static JSONObject fullJson() {
		JSONObject j = minimalJson();
		stubJsonField(j, NotificationData.DATA_KEY_LARGE_ICON_NAME, DEFAULT_LARGE_ICON);
		stubJsonField(j, NotificationData.DATA_KEY_INTERVAL, DEFAULT_INTERVAL);
		stubJsonField(j, NotificationData.DATA_KEY_DEEPLINK, DEFAULT_DEEPLINK);
		stubJsonField(j, NotificationData.DATA_KEY_BADGE_COUNT, DEFAULT_BADGE_COUNT);
		stubJsonField(j, NotificationData.OPTION_KEY_RESTART_APP, true);
		return j;
	}

	/**
	 * Minimal mock JSON plus a nested mock {@link JSONObject} for {@code custom_data}.
	 * The nested object exposes three entries via {@code keys()} / {@code opt()}.
	 */
	public static JSONObject jsonWithCustomData() {
		JSONObject customDataJson = mock(JSONObject.class);
		lenient().when(customDataJson.keys())
				.thenReturn(Arrays.asList("string_key", "int_key", "bool_key").iterator());
		lenient().when(customDataJson.opt("string_key")).thenReturn("hello");
		lenient().when(customDataJson.opt("int_key"))   .thenReturn(42);
		lenient().when(customDataJson.opt("bool_key"))  .thenReturn(true);

		JSONObject j = minimalJson();
		stubJsonField(j, NotificationData.DATA_KEY_CUSTOM_DATA, customDataJson);
		return j;
	}

	/**
	 * Helper: stubs {@code has(key) → true} and {@code opt(key) → value} on a mock
	 * {@link JSONObject}.  Both stubs are lenient to avoid {@code PotentialStubbingProblem}
	 * when the constructor checks keys other than the ones we stub here.
	 */
	private static void stubJsonField(JSONObject mock, String key, Object value) {
		lenient().when(mock.has(key)) .thenReturn(true);
		lenient().when(mock.opt(key)) .thenReturn(value);
	}

	// ---- Intent (mock) helpers ---------------------------------------------

	/**
	 * Mocked {@link Intent} returning the six required extras.
	 *
	 * <p>All stubs are <em>lenient</em>: {@code NotificationData(Intent)} calls
	 * {@code hasExtra} for every known key.  Without lenient mode, Mockito raises
	 * {@code PotentialStubbingProblem} when the constructor reaches a key this
	 * fixture does not stub.
	 */
	public static Intent minimalIntent() {
		Intent i = mock(Intent.class);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_ID)).thenReturn(true);
		lenient().when(i.getIntExtra(eq(NotificationData.DATA_KEY_ID), anyInt()))
				.thenReturn(DEFAULT_ID);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_CHANNEL_ID)).thenReturn(true);
		lenient().when(i.getStringExtra(NotificationData.DATA_KEY_CHANNEL_ID))
				.thenReturn(DEFAULT_CHANNEL_ID);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_TITLE)).thenReturn(true);
		lenient().when(i.getStringExtra(NotificationData.DATA_KEY_TITLE)).thenReturn(DEFAULT_TITLE);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_CONTENT)).thenReturn(true);
		lenient().when(i.getStringExtra(NotificationData.DATA_KEY_CONTENT)).thenReturn(DEFAULT_CONTENT);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_SMALL_ICON_NAME)).thenReturn(true);
		lenient().when(i.getStringExtra(NotificationData.DATA_KEY_SMALL_ICON_NAME))
				.thenReturn(DEFAULT_SMALL_ICON);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_DELAY)).thenReturn(true);
		lenient().when(i.getIntExtra(eq(NotificationData.DATA_KEY_DELAY), anyInt()))
				.thenReturn(DEFAULT_DELAY);

		return i;
	}

	/** Minimal intent plus all optional extras. */
	public static Intent fullIntent() {
		Intent i = minimalIntent();

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_LARGE_ICON_NAME)).thenReturn(true);
		lenient().when(i.getStringExtra(NotificationData.DATA_KEY_LARGE_ICON_NAME))
				.thenReturn(DEFAULT_LARGE_ICON);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_INTERVAL)).thenReturn(true);
		lenient().when(i.getIntExtra(eq(NotificationData.DATA_KEY_INTERVAL), anyInt()))
				.thenReturn(DEFAULT_INTERVAL);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_DEEPLINK)).thenReturn(true);
		lenient().when(i.getStringExtra(NotificationData.DATA_KEY_DEEPLINK)).thenReturn(DEFAULT_DEEPLINK);

		lenient().when(i.hasExtra(NotificationData.DATA_KEY_BADGE_COUNT)).thenReturn(true);
		lenient().when(i.getIntExtra(eq(NotificationData.DATA_KEY_BADGE_COUNT), anyInt()))
				.thenReturn(DEFAULT_BADGE_COUNT);

		lenient().when(i.hasExtra(NotificationData.OPTION_KEY_RESTART_APP)).thenReturn(true);
		lenient().when(i.getBooleanExtra(eq(NotificationData.OPTION_KEY_RESTART_APP), anyBoolean()))
				.thenReturn(true);

		return i;
	}

	/** Minimal intent plus a custom-data {@link Bundle} extra. */
	public static Intent intentWithCustomData(Bundle bundle) {
		Intent i = minimalIntent();
		lenient().when(i.hasExtra(NotificationData.DATA_KEY_CUSTOM_DATA)).thenReturn(true);
		lenient().when(i.getBundleExtra(NotificationData.DATA_KEY_CUSTOM_DATA)).thenReturn(bundle);
		return i;
	}

	/** Mocked {@link Intent} with no extras; all {@code hasExtra()} return {@code false}. */
	public static Intent emptyIntent() {
		return mock(Intent.class);
	}
}

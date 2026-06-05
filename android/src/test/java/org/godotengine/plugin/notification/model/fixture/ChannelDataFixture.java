//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification.model.fixture;

import android.content.Intent;

import org.godotengine.godot.Dictionary;
import org.json.JSONObject;

import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;

/**
 * Test fixtures for {@link org.godotengine.plugin.notification.model.ChannelData}.
 *
 * <p><strong>Why lenient stubs everywhere?</strong><br>
 * {@code ChannelData(Intent)} and {@code ChannelData(String, JSONObject)} both call the
 * mocked methods with keys we have NOT explicitly stubbed (e.g. the constructor reads
 * every possible extra even if we only care about a subset).  Mockito's
 * {@code STRICT_STUBS} mode would raise {@code PotentialStubbingProblem} if it sees
 * a stub for arg {@code "channel_name"} but a real call with arg {@code "badge_enabled"}.
 * {@code lenient()} suppresses that check while still recording the return value.
 *
 * <p><strong>Why mocked JSONObject?</strong><br>
 * {@code org.json.JSONObject} is bundled inside the Android SDK stub jar.  With
 * {@code isReturnDefaultValues = true}, all {@code optString}/{@code optInt}/{@code optBoolean}
 * calls return {@code null}/{@code 0}/{@code false} regardless of what was put into the
 * object.  Replacing the real {@code JSONObject} with a Mockito mock lets us control
 * exactly what each call returns.
 */
public final class ChannelDataFixture {

	// ---- Mirror of ChannelData's private key constants ---------------------

	public static final String KEY_ID = "channel_id";
	public static final String KEY_NAME = "channel_name";
	public static final String KEY_DESCRIPTION = "channel_description";
	public static final String KEY_IMPORTANCE = "channel_importance";
	public static final String KEY_BADGE = "badge_enabled";

	// ---- Stable test values ------------------------------------------------

	public static final String  DEFAULT_ID = "test-channel-id";
	public static final String  DEFAULT_NAME = "Test Channel";
	public static final String  DEFAULT_DESCRIPTION = "Test channel description";
	/** Mirrors {@code NotificationManager.IMPORTANCE_DEFAULT} = 3. */
	public static final int     DEFAULT_IMPORTANCE = 3;
	public static final boolean DEFAULT_BADGE = true;

	// Exact default strings baked into ChannelData(String id)
	public static final String CTOR_DEFAULT_NAME = "Default Channel";
	public static final String CTOR_DEFAULT_DESCRIPTION = "Notifications channel";

	private ChannelDataFixture() {
	}

	// ---- Dictionary helpers ------------------------------------------------

	/**
	 * Fully-populated {@link Dictionary} with all five fields.
	 * Importance is stored as {@code long} to match the production code.
	 */
	public static Dictionary fullDictionary() {
		Dictionary d = new Dictionary();
		d.put(KEY_ID, DEFAULT_ID);
		d.put(KEY_NAME, DEFAULT_NAME);
		d.put(KEY_DESCRIPTION, DEFAULT_DESCRIPTION);
		d.put(KEY_IMPORTANCE, (long) DEFAULT_IMPORTANCE);
		d.put(KEY_BADGE, DEFAULT_BADGE);
		return d;
	}

	/**
	 * Dictionary with only the three required fields ({@code isValid()} checks).
	 * Importance and badge are absent to exercise the self-healing path in
	 * {@code isValid()}.
	 */
	public static Dictionary minimalDictionary() {
		Dictionary d = new Dictionary();
		d.put(KEY_ID, DEFAULT_ID);
		d.put(KEY_NAME, DEFAULT_NAME);
		d.put(KEY_DESCRIPTION, DEFAULT_DESCRIPTION);
		return d;
	}

	/** Full dictionary minus the channel id. */
	public static Dictionary dictionaryMissingId() {
		Dictionary d = fullDictionary();
		d.remove(KEY_ID);
		return d;
	}

	/** Full dictionary minus the channel name. */
	public static Dictionary dictionaryMissingName() {
		Dictionary d = fullDictionary();
		d.remove(KEY_NAME);
		return d;
	}

	/** Full dictionary minus the channel description. */
	public static Dictionary dictionaryMissingDescription() {
		Dictionary d = fullDictionary();
		d.remove(KEY_DESCRIPTION);
		return d;
	}

	// ---- JSON (mock) helpers -----------------------------------------------

	/**
	 * Mocked {@link JSONObject} whose {@code optString}/{@code optInt}/{@code optBoolean}
	 * calls return the fixture's test values.
	 *
	 * <p>The real {@code JSONObject} is part of the Android SDK stub jar, so
	 * {@code optString("channel_name", "Default Channel")} would return {@code null}
	 * instead of the supplied default.  A Mockito mock avoids this entirely.
	 */
	public static JSONObject fullJson() {
		JSONObject j = mock(JSONObject.class);
		lenient().when(j.optString(eq(KEY_NAME), anyString())).thenReturn(DEFAULT_NAME);
		lenient().when(j.optString(eq(KEY_DESCRIPTION), anyString())).thenReturn(DEFAULT_DESCRIPTION);
		lenient().when(j.optInt(eq(KEY_IMPORTANCE), anyInt()))   .thenReturn(DEFAULT_IMPORTANCE);
		lenient().when(j.optBoolean(eq(KEY_BADGE), anyBoolean())).thenReturn(DEFAULT_BADGE);
		return j;
	}

	/**
	 * Mocked {@link JSONObject} with no keys set.
	 * Each {@code opt*} call returns its <em>second</em> argument (the default),
	 * which is exactly the behaviour of a real empty JSONObject.
	 */
	public static JSONObject emptyJson() {
		JSONObject j = mock(JSONObject.class);
		lenient().when(j.optString(anyString(), anyString()))  .thenAnswer(inv -> inv.getArgument(1));
		lenient().when(j.optInt(anyString(), anyInt()))     .thenAnswer(inv -> inv.getArgument(1));
		lenient().when(j.optBoolean(anyString(), anyBoolean())) .thenAnswer(inv -> inv.getArgument(1));
		return j;
	}

	// ---- Intent (mock) helpers ---------------------------------------------

	/**
	 * Mocked {@link Intent} that returns all five channel extras.
	 *
	 * <p>All stubs are <em>lenient</em> because {@code ChannelData(Intent)} calls
	 * {@code hasExtra} for every known key, including keys this fixture does not
	 * stub.  Without lenient mode, Mockito's {@code STRICT_STUBS} would raise
	 * {@code PotentialStubbingProblem} for those unmatched calls.
	 */
	public static Intent fullIntent() {
		Intent i = mock(Intent.class);
		lenient().when(i.hasExtra(KEY_ID)).thenReturn(true);
		lenient().when(i.getStringExtra(KEY_ID)).thenReturn(DEFAULT_ID);

		lenient().when(i.hasExtra(KEY_NAME)).thenReturn(true);
		lenient().when(i.getStringExtra(KEY_NAME)).thenReturn(DEFAULT_NAME);

		lenient().when(i.hasExtra(KEY_DESCRIPTION)).thenReturn(true);
		lenient().when(i.getStringExtra(KEY_DESCRIPTION)).thenReturn(DEFAULT_DESCRIPTION);

		lenient().when(i.hasExtra(KEY_IMPORTANCE)).thenReturn(true);
		lenient().when(i.getIntExtra(eq(KEY_IMPORTANCE), anyInt())).thenReturn(DEFAULT_IMPORTANCE);

		lenient().when(i.hasExtra(KEY_BADGE)).thenReturn(true);
		lenient().when(i.getBooleanExtra(eq(KEY_BADGE), anyBoolean())).thenReturn(DEFAULT_BADGE);
		return i;
	}

	/**
	 * Mocked {@link Intent} with no channel extras.
	 * All {@code hasExtra()} calls return {@code false} (Mockito default for booleans).
	 */
	public static Intent emptyIntent() {
		return mock(Intent.class);
	}
}

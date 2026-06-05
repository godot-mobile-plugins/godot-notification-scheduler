//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification.model;

import android.content.Intent;
import android.os.Bundle;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.notification.model.fixture.NotificationDataFixture;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.MockedConstruction;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyFloat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockConstruction;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link NotificationData}.
 *
 * <p>Grouped by concern via {@link Nested} inner classes:
 * <ul>
 *   <li>{@link FromDictionary}    – the Dictionary constructor
 *   <li>{@link FromJson}          – the JSONObject constructor
 *   <li>{@link FromIntent}        – the Intent constructor
 *   <li>{@link Validity}          – {@code isValid()} for every required field
 *   <li>{@link PresenceChecks}    – all {@code has*()} boolean accessors
 *   <li>{@link NumericConversion} – {@code toInteger()} via public getters
 *   <li>{@link CustomDataBundle}  – {@code getCustomDataBundle()} type dispatch
 *   <li>{@link IntentPopulation}  – {@code populateIntent()} completeness
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("NotificationData")
class NotificationDataTest {

	// =========================================================================
	// Dictionary constructor
	// =========================================================================

	@Nested
	@DisplayName("Dictionary constructor")
	class FromDictionary {

		@Test
		@DisplayName("reads all six required fields")
		void readsRequiredFields() {
			NotificationData nd = new NotificationData(NotificationDataFixture.minimalDictionary());

			assertAll("required fields from Dictionary",
					() -> assertEquals(NotificationDataFixture.DEFAULT_ID, nd.getId()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_CHANNEL_ID, nd.getChannelId()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_TITLE, nd.getTitle()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_CONTENT, nd.getContent()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_SMALL_ICON, nd.getSmallIconName()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_DELAY, nd.getDelay())
			);
		}

		@Test
		@DisplayName("reads all optional fields when present")
		void readsOptionalFields() {
			NotificationData nd = new NotificationData(NotificationDataFixture.fullDictionary());

			assertAll("optional fields from Dictionary",
					() -> assertEquals(NotificationDataFixture.DEFAULT_LARGE_ICON, nd.getLargeIconName()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_INTERVAL, nd.getInterval()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_DEEPLINK, nd.getDeeplink()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_BADGE_COUNT, nd.getBadgeCount()),
					() -> assertTrue(nd.hasRestartAppOption())
			);
		}

		@Test
		@DisplayName("getRawData() returns the original Dictionary")
		void getRawData_returnsOriginalDictionary() {
			Dictionary source = NotificationDataFixture.minimalDictionary();
			NotificationData nd = new NotificationData(source);

			assertNotNull(nd.getRawData());
			assertEquals(source.get(NotificationData.DATA_KEY_TITLE),
					nd.getRawData().get(NotificationData.DATA_KEY_TITLE));
		}
	}

	// =========================================================================
	// JSONObject constructor
	// =========================================================================

	@Nested
	@DisplayName("JSON constructor")
	class FromJson {

		@Test
		@DisplayName("parses all six required fields from JSONObject")
		void parsesRequiredFields() throws JSONException {
			NotificationData nd = new NotificationData(NotificationDataFixture.minimalJson());

			assertAll("required fields parsed from JSON",
					() -> assertEquals(NotificationDataFixture.DEFAULT_ID, nd.getId()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_CHANNEL_ID, nd.getChannelId()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_TITLE, nd.getTitle()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_CONTENT, nd.getContent()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_SMALL_ICON, nd.getSmallIconName())
			);
		}

		@Test
		@DisplayName("parses all optional fields from JSONObject")
		void parsesOptionalFields() throws JSONException {
			NotificationData nd = new NotificationData(NotificationDataFixture.fullJson());

			assertAll("optional fields parsed from JSON",
					() -> assertTrue(nd.hasLargeIconName()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_LARGE_ICON, nd.getLargeIconName()),
					() -> assertTrue(nd.hasInterval()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_INTERVAL, nd.getInterval()),
					() -> assertTrue(nd.hasDeeplink()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_DEEPLINK, nd.getDeeplink()),
					() -> assertTrue(nd.hasBadgeCount()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_BADGE_COUNT, nd.getBadgeCount()),
					() -> assertTrue(nd.hasRestartAppOption())
			);
		}

		@Test
		@DisplayName("converts nested custom_data JSONObject into a Dictionary")
		void convertsCustomDataJsonToDictionary() throws JSONException {
			NotificationData nd = new NotificationData(NotificationDataFixture.jsonWithCustomData());

			assertTrue(nd.hasCustomData(), "hasCustomData() must be true");
			Object raw = nd.getRawData().get(NotificationData.DATA_KEY_CUSTOM_DATA);
			assertInstanceOf(Dictionary.class, raw,
					"custom_data must be stored as a Dictionary, not a JSONObject");

			Dictionary customDict = (Dictionary) raw;
			assertAll("custom_data Dictionary entries",
					() -> assertEquals("hello", customDict.get("string_key")),
					() -> assertEquals(42, customDict.get("int_key")),
					() -> assertEquals(true, customDict.get("bool_key"))
			);
		}

		@Test
		@DisplayName("ignores non-JSONObject custom_data without throwing")
		void ignoresNonDictionaryCustomData() {
			// minimalJson() returns a Mockito mock; calling j.put(...) on it is a no-op.
			// Instead, stub has/opt to return a plain String so that the instanceof check
			// inside the constructor evaluates to false → the entry is silently skipped.
			JSONObject j = NotificationDataFixture.minimalJson();
			lenient().when(j.has(NotificationData.DATA_KEY_CUSTOM_DATA)).thenReturn(true);
			lenient().when(j.opt(NotificationData.DATA_KEY_CUSTOM_DATA)).thenReturn("plain-string");

			assertDoesNotThrow(() -> {
				NotificationData nd = new NotificationData(j);
				assertFalse(nd.hasCustomData(),
						"Non-JSONObject custom_data must be silently ignored");
			});
		}
	}

	// =========================================================================
	// Intent constructor
	// =========================================================================

	@Nested
	@DisplayName("Intent constructor")
	class FromIntent {

		@Test
		@DisplayName("reads all six required extras from a mocked Intent")
		void readsRequiredExtras() {
			NotificationData nd = new NotificationData(NotificationDataFixture.minimalIntent());

			assertAll("required extras from Intent",
					() -> assertEquals(NotificationDataFixture.DEFAULT_ID, nd.getId()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_CHANNEL_ID, nd.getChannelId()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_TITLE, nd.getTitle()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_CONTENT, nd.getContent()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_SMALL_ICON, nd.getSmallIconName()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_DELAY, nd.getDelay())
			);
		}

		@Test
		@DisplayName("reads all optional extras when present")
		void readsOptionalExtras() {
			NotificationData nd = new NotificationData(NotificationDataFixture.fullIntent());

			assertAll("optional extras from Intent",
					() -> assertTrue(nd.hasLargeIconName()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_LARGE_ICON, nd.getLargeIconName()),
					() -> assertTrue(nd.hasInterval()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_INTERVAL, nd.getInterval()),
					() -> assertTrue(nd.hasDeeplink()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_DEEPLINK, nd.getDeeplink()),
					() -> assertTrue(nd.hasBadgeCount()),
					() -> assertEquals(NotificationDataFixture.DEFAULT_BADGE_COUNT, nd.getBadgeCount()),
					() -> assertTrue(nd.hasRestartAppOption())
			);
		}

		@Test
		@SuppressWarnings("deprecation") // Bundle.get(String) is deprecated; used here to mirror production code
		@DisplayName("reads Bundle extra and stores it as a custom-data Dictionary")
		void readsBundleExtraAsCustomData() {
			// A mocked Bundle whose keySet() and get() are fully controlled.
			Bundle bundle = mock(Bundle.class);
			when(bundle.keySet()).thenReturn(Collections.singleton("user_id"));
			when(bundle.get("user_id")).thenReturn("u-001");

			NotificationData nd = new NotificationData(
					NotificationDataFixture.intentWithCustomData(bundle));

			assertTrue(nd.hasCustomData());
			Dictionary customDict =
					(Dictionary) nd.getRawData().get(NotificationData.DATA_KEY_CUSTOM_DATA);
			assertNotNull(customDict);
			assertEquals("u-001", customDict.get("user_id"));
		}

		@Test
		@DisplayName("does not throw when Intent has no extras at all")
		void doesNotThrow_withEmptyIntent() {
			assertDoesNotThrow(
					() -> new NotificationData(NotificationDataFixture.emptyIntent()));
		}
	}

	// =========================================================================
	// isValid()
	// =========================================================================

	@Nested
	@DisplayName("isValid()")
	class Validity {

		@Test
		@DisplayName("returns true when all six required fields are present")
		void returnsTrue_withAllRequiredFields() {
			NotificationData nd =
					new NotificationData(NotificationDataFixture.minimalDictionary());
			assertTrue(nd.isValid());
		}

		@Test
		@DisplayName("returns false when notification_id is absent")
		void returnsFalse_whenIdMissing() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.remove(NotificationData.DATA_KEY_ID);
			assertFalse(new NotificationData(d).isValid());
		}

		@Test
		@DisplayName("returns false when channel_id is absent")
		void returnsFalse_whenChannelIdMissing() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.remove(NotificationData.DATA_KEY_CHANNEL_ID);
			assertFalse(new NotificationData(d).isValid());
		}

		@Test
		@DisplayName("returns false when title is absent")
		void returnsFalse_whenTitleMissing() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.remove(NotificationData.DATA_KEY_TITLE);
			assertFalse(new NotificationData(d).isValid());
		}

		@Test
		@DisplayName("returns false when content is absent")
		void returnsFalse_whenContentMissing() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.remove(NotificationData.DATA_KEY_CONTENT);
			assertFalse(new NotificationData(d).isValid());
		}

		@Test
		@DisplayName("returns false when small_icon_name is absent")
		void returnsFalse_whenSmallIconMissing() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.remove(NotificationData.DATA_KEY_SMALL_ICON_NAME);
			assertFalse(new NotificationData(d).isValid());
		}

		@Test
		@DisplayName("returns false when delay is absent")
		void returnsFalse_whenDelayMissing() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.remove(NotificationData.DATA_KEY_DELAY);
			assertFalse(new NotificationData(d).isValid());
		}
	}

	// =========================================================================
	// has*() presence checks
	// =========================================================================

	@Nested
	@DisplayName("has*() presence checks")
	class PresenceChecks {

		@Test
		@DisplayName("hasLargeIconName() is false when key absent, true when present")
		void hasLargeIconName_reflectsPresence() {
			NotificationData minimal = new NotificationData(NotificationDataFixture.minimalDictionary());
			NotificationData full = new NotificationData(NotificationDataFixture.fullDictionary());
			assertFalse(minimal.hasLargeIconName(), "must be false when key is absent");
			assertTrue(full.hasLargeIconName(), "must be true when key is present");
		}

		@Test
		@DisplayName("hasInterval() is false when key absent, true when present")
		void hasInterval_reflectsPresence() {
			NotificationData minimal = new NotificationData(NotificationDataFixture.minimalDictionary());
			NotificationData full = new NotificationData(NotificationDataFixture.fullDictionary());
			assertFalse(minimal.hasInterval());
			assertTrue(full.hasInterval());
		}

		@Test
		@DisplayName("hasDeeplink() is false when key absent, true when present")
		void hasDeeplink_reflectsPresence() {
			NotificationData minimal = new NotificationData(NotificationDataFixture.minimalDictionary());
			NotificationData full = new NotificationData(NotificationDataFixture.fullDictionary());
			assertFalse(minimal.hasDeeplink());
			assertTrue(full.hasDeeplink());
		}

		@Test
		@DisplayName("hasBadgeCount() is false when key absent, true when present")
		void hasBadgeCount_reflectsPresence() {
			NotificationData minimal = new NotificationData(NotificationDataFixture.minimalDictionary());
			NotificationData full = new NotificationData(NotificationDataFixture.fullDictionary());
			assertFalse(minimal.hasBadgeCount());
			assertTrue(full.hasBadgeCount());
		}

		@Test
		@DisplayName("getBadgeCount() returns 0 when the key is absent")
		void getBadgeCount_returnsZero_whenAbsent() {
			NotificationData nd = new NotificationData(NotificationDataFixture.minimalDictionary());
			assertEquals(0, nd.getBadgeCount());
		}

		@Test
		@DisplayName("hasCustomData() is false when key absent, true when present")
		void hasCustomData_reflectsPresence() {
			NotificationData minimal = new NotificationData(NotificationDataFixture.minimalDictionary());
			NotificationData withCD = new NotificationData(NotificationDataFixture.dictionaryWithCustomData());
			assertFalse(minimal.hasCustomData());
			assertTrue(withCD.hasCustomData());
		}

		@Test
		@DisplayName("hasRestartAppOption() is false when key absent, true when present")
		void hasRestartAppOption_reflectsPresence() {
			NotificationData minimal = new NotificationData(NotificationDataFixture.minimalDictionary());
			NotificationData full = new NotificationData(NotificationDataFixture.fullDictionary());
			assertFalse(minimal.hasRestartAppOption());
			assertTrue(full.hasRestartAppOption());
		}
	}

	// =========================================================================
	// Numeric conversion – toInteger() via public getters
	// =========================================================================

	@Nested
	@DisplayName("Numeric type conversion")
	class NumericConversion {

		@Test
		@DisplayName("getId() converts a stored Integer value correctly")
		void getId_handlesStoredInteger() {
			// The minimalDictionary stores id as plain int (auto-boxed to Integer)
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.put(NotificationData.DATA_KEY_ID, 99);           // Integer
			assertEquals(99, new NotificationData(d).getId());
		}

		@Test
		@DisplayName("getId() converts a stored Long value correctly")
		void getId_handlesStoredLong() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.put(NotificationData.DATA_KEY_ID, 99L);          // Long
			assertEquals(99, new NotificationData(d).getId());
		}

		@Test
		@DisplayName("getDelay() converts a stored Long value correctly")
		void getDelay_handlesStoredLong() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.put(NotificationData.DATA_KEY_DELAY, 120L);
			assertEquals(120, new NotificationData(d).getDelay());
		}

		@Test
		@DisplayName("getInterval() converts a stored Long value correctly")
		void getInterval_handlesStoredLong() {
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.put(NotificationData.DATA_KEY_INTERVAL, 7200L);
			assertEquals(7200, new NotificationData(d).getInterval());
		}
	}

	// =========================================================================
	// getCustomDataBundle()
	// =========================================================================

	@Nested
	@DisplayName("getCustomDataBundle()")
	class CustomDataBundle {

		/**
		 * Helper that builds a NotificationData whose custom-data Dictionary
		 * contains a single entry of the requested type.
		 */
		private NotificationData notificationDataWithCustomEntry(String key, Object value) {
			Dictionary customData = new Dictionary();
			customData.put(key, value);
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.put(NotificationData.DATA_KEY_CUSTOM_DATA, customData);
			return new NotificationData(d);
		}

		@Test
		@DisplayName("calls Bundle.putString for String values")
		void storesStringValues() {
			NotificationData nd = notificationDataWithCustomEntry("str", "hello");

			try (MockedConstruction<Bundle> mocked = mockConstruction(Bundle.class)) {
				nd.getCustomDataBundle();
				verify(mocked.constructed().get(0)).putString("str", "hello");
			}
		}

		@Test
		@DisplayName("calls Bundle.putInt for Integer values")
		void storesIntegerValues() {
			NotificationData nd = notificationDataWithCustomEntry("num", 42);

			try (MockedConstruction<Bundle> mocked = mockConstruction(Bundle.class)) {
				nd.getCustomDataBundle();
				verify(mocked.constructed().get(0)).putInt("num", 42);
			}
		}

		@Test
		@DisplayName("calls Bundle.putLong for Long values")
		void storesLongValues() {
			NotificationData nd = notificationDataWithCustomEntry("lng", 100L);

			try (MockedConstruction<Bundle> mocked = mockConstruction(Bundle.class)) {
				nd.getCustomDataBundle();
				verify(mocked.constructed().get(0)).putLong("lng", 100L);
			}
		}

		@Test
		@DisplayName("calls Bundle.putFloat for Float values")
		void storesFloatValues() {
			NotificationData nd = notificationDataWithCustomEntry("flt", 3.14f);

			try (MockedConstruction<Bundle> mocked = mockConstruction(Bundle.class)) {
				nd.getCustomDataBundle();
				verify(mocked.constructed().get(0)).putFloat("flt", 3.14f);
			}
		}

		@Test
		@DisplayName("calls Bundle.putDouble for Double values")
		void storesDoubleValues() {
			NotificationData nd = notificationDataWithCustomEntry("dbl", 2.718);

			try (MockedConstruction<Bundle> mocked = mockConstruction(Bundle.class)) {
				nd.getCustomDataBundle();
				verify(mocked.constructed().get(0)).putDouble("dbl", 2.718);
			}
		}

		@Test
		@DisplayName("calls Bundle.putBoolean for Boolean values")
		void storesBooleanValues() {
			NotificationData nd = notificationDataWithCustomEntry("flag", true);

			try (MockedConstruction<Bundle> mocked = mockConstruction(Bundle.class)) {
				nd.getCustomDataBundle();
				verify(mocked.constructed().get(0)).putBoolean("flag", true);
			}
		}

		@Test
		@DisplayName("skips null values without touching the Bundle")
		void skipsNullValues() {
			Dictionary customData = new Dictionary();
			customData.put("null_key", null);
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.put(NotificationData.DATA_KEY_CUSTOM_DATA, customData);
			NotificationData nd = new NotificationData(d);

			try (MockedConstruction<Bundle> mocked = mockConstruction(Bundle.class)) {
				nd.getCustomDataBundle();
				Bundle mockBundle = mocked.constructed().get(0);
				// No put* call should have been made for the null entry
				verify(mockBundle, never()).putString(eq("null_key"), anyString());
				verify(mockBundle, never()).putInt(eq("null_key"), anyInt());
				verify(mockBundle, never()).putBoolean(eq("null_key"), anyBoolean());
			}
		}

		@Test
		@DisplayName("skips entries with unsupported value types without throwing")
		void skipsUnsupportedValueTypes() {
			// Dictionary<String, Object> enforces String keys at compile time, so
			// the non-String-key guard in getCustomDataBundle() is unreachable for
			// Dictionary-based data.  The unsupported-value-type else-branch is the
			// real dead-code guard that CAN be exercised: put a List as a value,
			// which is not Boolean/Integer/Long/Float/Double/String, and verify
			// that no Bundle put* call is made for that entry.
			Dictionary customData = new Dictionary();
			customData.put("list_key", new java.util.ArrayList<>());  // unsupported type
			Dictionary d = NotificationDataFixture.minimalDictionary();
			d.put(NotificationData.DATA_KEY_CUSTOM_DATA, customData);
			NotificationData nd = new NotificationData(d);

			try (MockedConstruction<Bundle> mocked = mockConstruction(Bundle.class)) {
				assertDoesNotThrow(() -> nd.getCustomDataBundle());
				Bundle mockBundle = mocked.constructed().get(0);
				// None of the typed put* methods must be called for the unsupported entry
				verify(mockBundle, never()).putString(anyString(), anyString());
				verify(mockBundle, never()).putInt(anyString(), anyInt());
				verify(mockBundle, never()).putLong(anyString(), anyLong());
				verify(mockBundle, never()).putFloat(anyString(), anyFloat());
				verify(mockBundle, never()).putDouble(anyString(), anyDouble());
				verify(mockBundle, never()).putBoolean(anyString(), anyBoolean());
			}
		}

		@Test
		@DisplayName("returns a non-null Bundle even when custom_data is absent")
		void returnsNonNullBundle_whenCustomDataAbsent() {
			NotificationData nd = new NotificationData(NotificationDataFixture.minimalDictionary());

			try (MockedConstruction<Bundle> ignored = mockConstruction(Bundle.class)) {
				assertNotNull(nd.getCustomDataBundle());
			}
		}
	}

	// =========================================================================
	// populateIntent()
	// =========================================================================

	@Nested
	@DisplayName("populateIntent()")
	class IntentPopulation {

		@Test
		@DisplayName("puts all six required extras onto the Intent")
		void putsRequiredExtras() {
			// populateIntent() calls intent.putExtra(key, this.getId()) where getId() returns
			// Integer.  Java's overload resolution picks putExtra(String, Serializable) in
			// phase-1 (widening reference) over putExtra(String, int) which needs unboxing
			// (phase-2).  The verify must therefore pass an Integer, not a primitive int,
			// or Mockito checks the wrong overload and reports "arguments are different".
			NotificationData nd = new NotificationData(NotificationDataFixture.minimalDictionary());
			Intent           intent = mock(Intent.class);

			nd.populateIntent(intent);

			assertAll("required extras on Intent",
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_ID,
							(Integer) NotificationDataFixture.DEFAULT_ID),
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_CHANNEL_ID, NotificationDataFixture.DEFAULT_CHANNEL_ID),
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_TITLE, NotificationDataFixture.DEFAULT_TITLE),
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_CONTENT, NotificationDataFixture.DEFAULT_CONTENT),
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_SMALL_ICON_NAME, NotificationDataFixture.DEFAULT_SMALL_ICON),
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_DELAY,
							(Integer) NotificationDataFixture.DEFAULT_DELAY)
			);
		}

		@Test
		@DisplayName("puts optional extras when they are present in the data")
		void putsOptionalExtras_whenPresent() {
			NotificationData nd = new NotificationData(NotificationDataFixture.fullDictionary());
			Intent           intent = mock(Intent.class);

			nd.populateIntent(intent);

			assertAll("optional extras on Intent",
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_LARGE_ICON_NAME, NotificationDataFixture.DEFAULT_LARGE_ICON),
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_INTERVAL,
							(Integer) NotificationDataFixture.DEFAULT_INTERVAL),
					() -> verify(intent).putExtra(
							NotificationData.DATA_KEY_DEEPLINK, NotificationDataFixture.DEFAULT_DEEPLINK),
					() -> verify(intent).putExtra(
							NotificationData.OPTION_KEY_RESTART_APP, true)
			);
		}

		@Test
		@DisplayName("does NOT put optional extras when they are absent from the data")
		void omitsOptionalExtras_whenAbsent() {
			NotificationData nd = new NotificationData(NotificationDataFixture.minimalDictionary());
			Intent           intent = mock(Intent.class);

			nd.populateIntent(intent);

			assertAll("optional extras absent from Intent",
					() -> verify(intent, never()).putExtra(
							eq(NotificationData.DATA_KEY_LARGE_ICON_NAME), anyString()),
					() -> verify(intent, never()).putExtra(
							eq(NotificationData.DATA_KEY_INTERVAL), anyInt()),
					() -> verify(intent, never()).putExtra(
							eq(NotificationData.DATA_KEY_DEEPLINK), anyString()),
					() -> verify(intent, never()).putExtra(
							eq(NotificationData.OPTION_KEY_RESTART_APP), anyBoolean())
			);
		}

		@Test
		@DisplayName("puts badge_count extra only when the count is greater than zero")
		void putsBadgeCount_onlyWhenPositive() {
			// badge_count = 5 → must be added (Integer overload, same Serializable reason)
			Dictionary dWith = NotificationDataFixture.minimalDictionary();
			dWith.put(NotificationData.DATA_KEY_BADGE_COUNT, NotificationDataFixture.DEFAULT_BADGE_COUNT);
			Intent intentWith = mock(Intent.class);
			new NotificationData(dWith).populateIntent(intentWith);
			verify(intentWith).putExtra(
					NotificationData.DATA_KEY_BADGE_COUNT,
					(Integer) NotificationDataFixture.DEFAULT_BADGE_COUNT);

			// badge_count absent → must NOT be added
			Intent intentWithout = mock(Intent.class);
			new NotificationData(NotificationDataFixture.minimalDictionary()).populateIntent(intentWithout);
			verify(intentWithout, never()).putExtra(eq(NotificationData.DATA_KEY_BADGE_COUNT), anyInt());
		}

		@Test
		@DisplayName("puts custom_data Bundle extra when custom data is present")
		void putsCustomDataBundle_whenPresent() {
			NotificationData nd = new NotificationData(NotificationDataFixture.dictionaryWithCustomData());
			Intent           intent = mock(Intent.class);

			try (MockedConstruction<Bundle> ignored = mockConstruction(Bundle.class)) {
				nd.populateIntent(intent);
				verify(intent).putExtra(eq(NotificationData.DATA_KEY_CUSTOM_DATA), any(Bundle.class));
			}
		}

		@Test
		@DisplayName("does NOT put custom_data Bundle extra when custom data is absent")
		void omitsCustomDataBundle_whenAbsent() {
			NotificationData nd = new NotificationData(NotificationDataFixture.minimalDictionary());
			Intent           intent = mock(Intent.class);

			nd.populateIntent(intent);

			verify(intent, never()).putExtra(eq(NotificationData.DATA_KEY_CUSTOM_DATA), any(Bundle.class));
		}
	}
}

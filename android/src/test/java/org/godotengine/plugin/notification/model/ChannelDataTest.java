//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification.model;

import android.content.Intent;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.notification.model.fixture.ChannelDataFixture;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

/**
 * Unit tests for {@link ChannelData}.
 *
 * <p>Tests are grouped by concern using {@link Nested} inner classes:
 * <ul>
 *   <li>{@link Construction} – each overloaded constructor
 *   <li>{@link Validation}   – {@code isValid()} edge cases
 *   <li>{@link Serialisation} – {@code toJson()} and {@code toNotificationChannel()}
 *   <li>{@link IntentPopulation} – {@code populateIntent()}
 * </ul>
 *
 * <p>Android framework classes ({@link Intent}, etc.) are replaced by Mockito
 * mocks; no Android runtime is required.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("ChannelData")
class ChannelDataTest {

	// =========================================================================
	// Constructors
	// =========================================================================

	@Nested
	@DisplayName("Constructor – from String id")
	class Construction {

		@Test
		@DisplayName("assigns all default values when constructed from id only")
		void fromId_setsAllDefaults() {
			ChannelData cd = new ChannelData(ChannelDataFixture.DEFAULT_ID);

			assertAll("default values from id constructor",
					() -> assertEquals(ChannelDataFixture.DEFAULT_ID, cd.getId(),
							"id must match the constructor argument"),
					() -> assertEquals(ChannelDataFixture.CTOR_DEFAULT_NAME, cd.getName(),
							"name must be the hardcoded default"),
					() -> assertEquals(ChannelDataFixture.CTOR_DEFAULT_DESCRIPTION, cd.getDescription(),
							"description must be the hardcoded default"),
					() -> assertEquals(ChannelDataFixture.DEFAULT_IMPORTANCE, cd.getImportance(),
							"importance must default to IMPORTANCE_DEFAULT (3)"),
					() -> assertTrue(cd.getBadgeEnabled(), "badge must be enabled by default")
			);
		}

		@Test
		@DisplayName("from Dictionary – reads all five fields correctly")
		void fromDictionary_readsAllFields() {
			ChannelData cd = new ChannelData(ChannelDataFixture.fullDictionary());

			assertAll("values read from Dictionary",
					() -> assertEquals(ChannelDataFixture.DEFAULT_ID, cd.getId()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_NAME, cd.getName()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_DESCRIPTION, cd.getDescription()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_IMPORTANCE, cd.getImportance()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_BADGE, cd.getBadgeEnabled())
			);
		}

		@Test
		@DisplayName("from JSONObject – parses all supplied fields")
		void fromJson_parsesAllFields() throws JSONException {
			ChannelData cd = new ChannelData(
					ChannelDataFixture.DEFAULT_ID, ChannelDataFixture.fullJson());

			assertAll("values parsed from JSON",
					() -> assertEquals(ChannelDataFixture.DEFAULT_ID, cd.getId(),
							"id must come from the constructor argument, not the JSON"),
					() -> assertEquals(ChannelDataFixture.DEFAULT_NAME, cd.getName()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_DESCRIPTION, cd.getDescription()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_IMPORTANCE, cd.getImportance()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_BADGE, cd.getBadgeEnabled())
			);
		}

		@Test
		@DisplayName("from empty JSONObject – falls back to hardcoded defaults")
		void fromJson_usesDefaults_whenFieldsMissing() throws JSONException {
			ChannelData cd = new ChannelData(
					ChannelDataFixture.DEFAULT_ID, ChannelDataFixture.emptyJson());

			assertAll("default fallback values from empty JSON",
					() -> assertEquals(ChannelDataFixture.DEFAULT_ID, cd.getId(),
							"id must still come from the constructor argument"),
					() -> assertEquals(ChannelDataFixture.CTOR_DEFAULT_NAME, cd.getName()),
					() -> assertEquals(ChannelDataFixture.CTOR_DEFAULT_DESCRIPTION, cd.getDescription()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_IMPORTANCE, cd.getImportance()),
					() -> assertTrue(cd.getBadgeEnabled())
			);
		}

		@Test
		@DisplayName("from Intent – reads all extras when present")
		void fromIntent_readsAllExtras() {
			ChannelData cd = new ChannelData(ChannelDataFixture.fullIntent());

			assertAll("values read from Intent extras",
					() -> assertEquals(ChannelDataFixture.DEFAULT_ID, cd.getId()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_NAME, cd.getName()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_DESCRIPTION, cd.getDescription()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_IMPORTANCE, cd.getImportance()),
					() -> assertEquals(ChannelDataFixture.DEFAULT_BADGE, cd.getBadgeEnabled())
			);
		}

		@Test
		@DisplayName("from Intent with no extras – leaves all fields absent (null id)")
		void fromIntent_emptyExtras_leavesFieldsAbsent() {
			ChannelData cd = new ChannelData(ChannelDataFixture.emptyIntent());

			// No extras → nothing added to the internal Dictionary
			assertNull(cd.getId(),
					"getId() must return null when the id extra was not present");
		}
	}

	// =========================================================================
	// isValid()
	// =========================================================================

	@Nested
	@DisplayName("isValid()")
	class Validation {

		@Test
		@DisplayName("returns true when id, name, and description are all present")
		void returnsTrue_withRequiredFields() {
			ChannelData cd = new ChannelData(ChannelDataFixture.minimalDictionary());
			assertTrue(cd.isValid());
		}

		@Test
		@DisplayName("returns false when id is missing")
		void returnsFalse_whenIdMissing() {
			ChannelData cd = new ChannelData(ChannelDataFixture.dictionaryMissingId());
			assertFalse(cd.isValid());
		}

		@Test
		@DisplayName("returns false when name is missing")
		void returnsFalse_whenNameMissing() {
			ChannelData cd = new ChannelData(ChannelDataFixture.dictionaryMissingName());
			assertFalse(cd.isValid());
		}

		@Test
		@DisplayName("returns false when description is missing")
		void returnsFalse_whenDescriptionMissing() {
			ChannelData cd = new ChannelData(ChannelDataFixture.dictionaryMissingDescription());
			assertFalse(cd.isValid());
		}

		@Test
		@DisplayName("does not throw when importance key is absent (sets default)")
		void doesNotThrow_whenImportanceMissing() {
			// minimalDictionary has id/name/description but no importance key;
			// isValid() should set the default rather than crashing.
			ChannelData cd = new ChannelData(ChannelDataFixture.minimalDictionary());
			assertDoesNotThrow(cd::isValid,
					"isValid() must not throw when the importance key is absent");
		}

		@Test
		@DisplayName("does not throw when badge key is absent (sets default)")
		void doesNotThrow_whenBadgeMissing() {
			ChannelData cd = new ChannelData(ChannelDataFixture.minimalDictionary());
			assertDoesNotThrow(cd::isValid,
					"isValid() must not throw when the badge_enabled key is absent");
		}

		@Test
		@DisplayName("validates a full Dictionary without throwing")
		void fullDictionary_isValid_withoutThrowing() {
			ChannelData cd = new ChannelData(ChannelDataFixture.fullDictionary());
			assertDoesNotThrow(() -> assertTrue(cd.isValid()));
		}
	}

	// =========================================================================
	// Serialisation – toJson() and toNotificationChannel()
	// =========================================================================

	@Nested
	@DisplayName("toJson()")
	class Serialisation {

		@Test
		@DisplayName("serialises all five fields – verifies correct put() calls on JSONObject")
		void containsAllFiveFields() throws Exception {
			// org.json.JSONObject is part of the Android stub jar; its getString() / getInt()
			// methods return null/0 regardless of what was put in.  We therefore intercept
			// the JSONObject construction and verify the put() calls directly.
			ChannelData cd = new ChannelData(ChannelDataFixture.fullDictionary());

			try (org.mockito.MockedConstruction<JSONObject> mocked =
					org.mockito.Mockito.mockConstruction(JSONObject.class)) {

				cd.toJson();
				JSONObject mockJson = mocked.constructed().get(0);

				assertAll("put() calls on JSONObject",
						() -> verify(mockJson).put(ChannelDataFixture.KEY_ID,
								ChannelDataFixture.DEFAULT_ID),
						() -> verify(mockJson).put(ChannelDataFixture.KEY_NAME,
								ChannelDataFixture.DEFAULT_NAME),
						() -> verify(mockJson).put(ChannelDataFixture.KEY_DESCRIPTION,
								ChannelDataFixture.DEFAULT_DESCRIPTION),
						() -> verify(mockJson).put(ChannelDataFixture.KEY_IMPORTANCE,
								ChannelDataFixture.DEFAULT_IMPORTANCE),
						() -> verify(mockJson).put(ChannelDataFixture.KEY_BADGE,
								ChannelDataFixture.DEFAULT_BADGE)
				);
			}
		}

		// NOTE: a round-trip test (toJson → ChannelData constructor) is omitted because
		// the Android stub jar renders org.json.JSONObject non-functional in unit tests.
		// The constructor-from-JSON path is covered by fromJson_parsesAllFields above.

		@Test
		@DisplayName("toNotificationChannel() returns a non-null object")
		void toNotificationChannel_returnsNonNull() {
			ChannelData cd = new ChannelData(ChannelDataFixture.fullDictionary());
			assertNotNull(cd.toNotificationChannel());
		}

		@Test
		@DisplayName("toNotificationChannel() does not throw")
		void toNotificationChannel_doesNotThrow() {
			ChannelData cd = new ChannelData(ChannelDataFixture.fullDictionary());
			assertDoesNotThrow(cd::toNotificationChannel);
		}
	}

	// =========================================================================
	// populateIntent()
	// =========================================================================

	@Nested
	@DisplayName("populateIntent()")
	class IntentPopulation {

		@Test
		@DisplayName("puts all five extras onto the supplied Intent")
		void putsAllFiveExtras() {
			ChannelData cd = new ChannelData(ChannelDataFixture.fullDictionary());
			Intent      intent = mock(Intent.class);

			cd.populateIntent(intent);

			assertAll("extras added to Intent",
					() -> verify(intent).putExtra(
							ChannelDataFixture.KEY_ID, ChannelDataFixture.DEFAULT_ID),
					() -> verify(intent).putExtra(
							ChannelDataFixture.KEY_NAME, ChannelDataFixture.DEFAULT_NAME),
					() -> verify(intent).putExtra(
							ChannelDataFixture.KEY_DESCRIPTION, ChannelDataFixture.DEFAULT_DESCRIPTION),
					() -> verify(intent).putExtra(
							ChannelDataFixture.KEY_IMPORTANCE, ChannelDataFixture.DEFAULT_IMPORTANCE),
					() -> verify(intent).putExtra(
							ChannelDataFixture.KEY_BADGE, ChannelDataFixture.DEFAULT_BADGE)
			);
		}

		@Test
		@DisplayName("does not throw when badge_enabled key is absent")
		void doesNotThrow_whenBadgeKeyAbsent() {
			// populateIntent() calls getImportance() unconditionally, so importance must be
			// present to avoid an NPE.  Only badge_enabled is absent here.
			Dictionary d = ChannelDataFixture.fullDictionary();
			d.remove(ChannelDataFixture.KEY_BADGE);
			ChannelData cd = new ChannelData(d);
			Intent      intent = mock(Intent.class);
			assertDoesNotThrow(() -> cd.populateIntent(intent));
		}
	}
}

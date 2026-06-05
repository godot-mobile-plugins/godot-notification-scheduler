//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import org.godotengine.plugin.notification.model.fixture.NotificationDataFixture;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.HashSet;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

/**
 * Unit tests for {@link CancelNotificationReceiver}.
 *
 * <p>Three scenarios are tested:
 * <ol>
 *   <li><strong>Null intent</strong> – receiver must log an error and exit
 *       without touching the {@link Context}.
 *   <li><strong>Intent missing notification_id extra</strong> – same
 *       defensive exit, no {@link Context} interaction.
 *   <li><strong>Valid intent</strong> – dismissal data must be persisted to
 *       {@link SharedPreferences} via
 *       {@code NotificationSchedulerPlugin.handleNotificationDismissed()}.
 * </ol>
 *
 * <p>Because {@code NotificationSchedulerPlugin.instance} is {@code null}
 * during unit tests (no Godot engine is running), the implementation falls
 * through to {@code saveDismissedDataToPrefs()}, which is what the
 * SharedPreferences assertions below verify.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("CancelNotificationReceiver")
class CancelNotificationReceiverTest {

	@Mock
	private Context                  context;
	@Mock
	private SharedPreferences        sharedPreferences;
	@Mock
	private SharedPreferences.Editor editor;

	private CancelNotificationReceiver receiver;

	/**
	 * Stubs the full SharedPreferences write chain:
	 * {@code context → getSharedPreferences → getStringSet / edit → putStringSet → apply}.
	 *
	 * <p>This prevents NullPointerExceptions inside
	 * {@code saveDismissedDataToPrefs()} when the instance is null and
	 * lets tests assert on the final {@code apply()} call.
	 */
	@BeforeEach
	void setUp() {
		receiver = new CancelNotificationReceiver();

		// lenient() prevents UnnecessaryStubbingException in STRICT_STUBS mode:
		// the null-intent and missing-id tests never reach the SharedPreferences
		// layer, so these stubs would otherwise be flagged as unused.
		lenient().when(context.getSharedPreferences(anyString(), anyInt()))
				.thenReturn(sharedPreferences);
		lenient().when(sharedPreferences.getStringSet(anyString(), any()))
				.thenReturn(new HashSet<>());
		lenient().when(sharedPreferences.edit())
				.thenReturn(editor);
		lenient().when(editor.putStringSet(anyString(), any()))
				.thenReturn(editor);
	}

	// =========================================================================
	// Null intent
	// =========================================================================

	@Nested
	@DisplayName("Null intent")
	class NullIntent {

		@Test
		@DisplayName("does not throw when intent is null")
		void doesNotThrow() {
			assertDoesNotThrow(() -> receiver.onReceive(context, null));
		}

		@Test
		@DisplayName("does not interact with Context when intent is null")
		void doesNotTouchContext() {
			receiver.onReceive(context, null);
			verifyNoInteractions(context);
		}
	}

	// =========================================================================
	// Intent without notification_id extra
	// =========================================================================

	@Nested
	@DisplayName("Intent missing notification_id extra")
	class MissingIdExtra {

		@Test
		@DisplayName("does not throw when the id extra is absent")
		void doesNotThrow() {
			// An empty mock intent: all hasExtra() calls return false
			Intent intent = NotificationDataFixture.emptyIntent();
			assertDoesNotThrow(() -> receiver.onReceive(context, intent));
		}

		@Test
		@DisplayName("does not interact with Context when the id extra is absent")
		void doesNotTouchContext() {
			Intent intent = NotificationDataFixture.emptyIntent();
			receiver.onReceive(context, intent);
			verifyNoInteractions(context);
		}
	}

	// =========================================================================
	// Valid intent
	// =========================================================================

	@Nested
	@DisplayName("Valid intent (notification_id present)")
	class ValidIntent {

		@Test
		@DisplayName("persists dismissal data to SharedPreferences")
		void persistsDismissalData() {
			// A fully valid intent whose hasExtra(DATA_KEY_ID) returns true
			Intent intent = NotificationDataFixture.minimalIntent();

			receiver.onReceive(context, intent);

			// saveDismissedDataToPrefs() must commit the updated dismissed set
			verify(editor).putStringSet(anyString(), any());
			verify(editor).apply();
		}

		@Test
		@DisplayName("reads the existing dismissed set before writing")
		void readsExistingDismissedSet() {
			Intent intent = NotificationDataFixture.minimalIntent();

			receiver.onReceive(context, intent);

			verify(sharedPreferences).getStringSet(anyString(), any());
		}

		@Test
		@DisplayName("does not throw with a valid intent")
		void doesNotThrow() {
			Intent intent = NotificationDataFixture.minimalIntent();
			assertDoesNotThrow(() -> receiver.onReceive(context, intent));
		}
	}
}

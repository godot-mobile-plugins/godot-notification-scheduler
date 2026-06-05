//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import org.godotengine.plugin.notification.model.NotificationData;
import org.godotengine.plugin.notification.model.fixture.NotificationDataFixture;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

/**
 * Unit tests for {@link NotificationReceiver}.
 *
 * <p>Key implementation details that shape these tests:
 * <ul>
 *   <li>{@code Build.VERSION.SDK_INT} returns {@code 0} in unit tests
 *       (Android stub behaviour with {@code isReturnDefaultValues = true}).
 *       This means the OS-version guard
 *       {@code SDK_INT < Build.VERSION_CODES.M (23)} is always {@code true},
 *       so {@link NotificationData#buildNotification} returns {@code null}
 *       in every test – the {@code NotificationManagerCompat.notify()} path
 *       is never reached.
 *   <li>The channel self-healing block ({@code SDK_INT >= O}) is also never
 *       entered, so no {@code NotificationManager} interactions occur.
 *   <li>For non-repeating notifications {@code removeScheduledNotification}
 *       is called, which reads {@link SharedPreferences}.  The mocked chain
 *       below enables this without a NullPointerException.
 * </ul>
 *
 * <p>Test scenarios:
 * <ol>
 *   <li>Null intent          – logs error, no side-effects.
 *   <li>Missing id extra     – logs error, no side-effects.
 *   <li>Non-repeating intent – scheduled-notification entry is looked up and
 *       removed from SharedPreferences.
 *   <li>Repeating intent     – scheduled-notification entry is never touched
 *       (the removal is skipped for repeating / interval-based notifications).
 * </ol>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("NotificationReceiver")
class NotificationReceiverTest {

	@Mock
	private Context                  context;
	@Mock
	private SharedPreferences        sharedPreferences;
	@Mock
	private SharedPreferences.Editor editor;

	private NotificationReceiver receiver;

	/**
	 * Stubs the SharedPreferences chain needed by
	 * {@code removeScheduledNotification()}.
	 *
	 * <ul>
	 *   <li>{@code contains()} returns {@code true} so the
	 *       {@code edit().remove().apply()} branch is entered and we can
	 *       assert on it.
	 *   <li>The {@code editor} chain is fully stubbed to avoid
	 *       NullPointerExceptions on method-chaining.
	 * </ul>
	 */
	@BeforeEach
	void setUp() {
		receiver = new NotificationReceiver();

		// lenient() prevents UnnecessaryStubbingException in STRICT_STUBS mode:
		// null-intent, missing-id, and repeating-notification tests never call
		// removeScheduledNotification(), so these stubs would be flagged unused.
		lenient().when(context.getSharedPreferences(anyString(), anyInt()))
				.thenReturn(sharedPreferences);
		lenient().when(sharedPreferences.contains(anyString())).thenReturn(true);
		lenient().when(sharedPreferences.edit()).thenReturn(editor);
		lenient().when(editor.remove(anyString())).thenReturn(editor);
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
	// Intent missing notification_id extra
	// =========================================================================

	@Nested
	@DisplayName("Intent missing notification_id extra")
	class MissingIdExtra {

		@Test
		@DisplayName("does not throw when the id extra is absent")
		void doesNotThrow() {
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
	// Non-repeating notification (no interval)
	// =========================================================================

	@Nested
	@DisplayName("Non-repeating notification (no interval extra)")
	class NonRepeatingNotification {

		@Test
		@DisplayName("looks up the scheduled-notification entry in SharedPreferences")
		void looksUpScheduledEntry() {
			Intent intent = NotificationDataFixture.minimalIntent();

			receiver.onReceive(context, intent);

			verify(sharedPreferences).contains(
					String.valueOf(NotificationDataFixture.DEFAULT_ID));
		}

		@Test
		@DisplayName("removes the scheduled-notification entry when it exists")
		void removesScheduledEntry_whenFound() {
			Intent intent = NotificationDataFixture.minimalIntent();

			receiver.onReceive(context, intent);

			verify(editor).remove(String.valueOf(NotificationDataFixture.DEFAULT_ID));
			verify(editor).apply();
		}

		@Test
		@DisplayName("does not throw even though buildNotification returns null")
		void doesNotThrow_whenNotificationNull() {
			// buildNotification always returns null in unit tests (SDK_INT = 0 < M)
			Intent intent = NotificationDataFixture.minimalIntent();
			assertDoesNotThrow(() -> receiver.onReceive(context, intent));
		}
	}

	// =========================================================================
	// Repeating notification (interval extra present)
	// =========================================================================

	@Nested
	@DisplayName("Repeating notification (interval extra present)")
	class RepeatingNotification {

		/**
		 * Creates an intent that carries both the required fields and the
		 * {@code interval} optional extra, marking the notification as
		 * repeating.  {@code removeScheduledNotification} must be skipped
		 * for repeating notifications.
		 */
		private Intent repeatingIntent() {
			Intent i = NotificationDataFixture.minimalIntent();
			// lenient() required: minimalIntent() already has lenient stubs for specific keys,
			// but the NotificationData constructor also calls hasExtra for other keys (e.g.
			// "large_icon_name").  A strict stub for "interval" would trigger
			// PotentialStubbingProblem when those other keys are checked.
			lenient().when(i.hasExtra(NotificationData.DATA_KEY_INTERVAL)).thenReturn(true);
			lenient().when(i.getIntExtra(
					org.mockito.ArgumentMatchers.eq(NotificationData.DATA_KEY_INTERVAL),
					org.mockito.ArgumentMatchers.anyInt()))
					.thenReturn(NotificationDataFixture.DEFAULT_INTERVAL);
			return i;
		}

		@Test
		@DisplayName("does not remove the scheduled-notification entry")
		void doesNotRemoveScheduledEntry() {
			receiver.onReceive(context, repeatingIntent());

			// removeScheduledNotification must NOT be called for repeating notifications
			verify(sharedPreferences, never()).contains(anyString());
			verify(editor, never()).remove(anyString());
		}

		@Test
		@DisplayName("does not call SharedPreferences.edit() for removal")
		void doesNotCallEdit_forRemoval() {
			receiver.onReceive(context, repeatingIntent());

			verify(sharedPreferences, never()).edit();
		}

		@Test
		@DisplayName("does not throw even when notification object is null")
		void doesNotThrow() {
			assertDoesNotThrow(() -> receiver.onReceive(context, repeatingIntent()));
		}
	}
}

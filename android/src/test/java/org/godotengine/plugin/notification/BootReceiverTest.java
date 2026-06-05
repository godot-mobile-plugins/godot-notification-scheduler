//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.notification;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link BootReceiver}.
 *
 * <p>Verifies that:
 * <ul>
 *   <li>Receiving {@link Intent#ACTION_BOOT_COMPLETED} triggers the
 *       rescheduling path via
 *       {@code NotificationSchedulerPlugin.rescheduleAll(context)}.
 *   <li>Any other action (including {@code null}) is silently ignored and
 *       the {@link Context} is never touched.
 * </ul>
 *
 * <p>{@link Context} and {@link SharedPreferences} are Mockito mocks so that
 * the test does not require an Android runtime.  The shared-preferences chain
 * is set up to return an empty entry map, which causes {@code rescheduleAll}
 * to log a message and return immediately without scheduling any alarms.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("BootReceiver")
class BootReceiverTest {

	@Mock
	private Context           context;
	@Mock
	private SharedPreferences sharedPreferences;
	@Mock
	private SharedPreferences.Editor editor;

	private BootReceiver bootReceiver;

	/**
	 * Wire up a minimal SharedPreferences chain so that
	 * {@code rescheduleAll()} can call {@code getAll()} without a
	 * NullPointerException.  The empty map makes the implementation return
	 * early, keeping the test focused on the receiver's routing logic.
	 */
	@BeforeEach
	void setUp() {
		bootReceiver = new BootReceiver();
		// lenient() prevents UnnecessaryStubbingException in STRICT_STUBS mode:
		// the non-boot-action tests never call rescheduleAll(), so these stubs
		// would otherwise be flagged as unused.
		lenient().when(context.getSharedPreferences(anyString(), anyInt()))
				.thenReturn(sharedPreferences);
		lenient().when(sharedPreferences.getAll())
				.thenReturn(Collections.emptyMap());
	}

	// =========================================================================
	// Boot-completed action
	// =========================================================================

	@Nested
	@DisplayName("ACTION_BOOT_COMPLETED")
	class BootCompletedAction {

		@Test
		@DisplayName("triggers rescheduling by reading SharedPreferences")
		void triggersReschedule() {
			Intent intent = mock(Intent.class);
			when(intent.getAction()).thenReturn(Intent.ACTION_BOOT_COMPLETED);

			bootReceiver.onReceive(context, intent);

			// rescheduleAll() must query the persisted notification schedule
			verify(context).getSharedPreferences(anyString(), anyInt());
			verify(sharedPreferences).getAll();
		}

		@Test
		@DisplayName("does not throw when the schedule store is empty")
		void doesNotThrow_whenScheduleEmpty() {
			Intent intent = mock(Intent.class);
			when(intent.getAction()).thenReturn(Intent.ACTION_BOOT_COMPLETED);

			assertDoesNotThrow(() -> bootReceiver.onReceive(context, intent));
		}
	}

	// =========================================================================
	// Non-boot actions
	// =========================================================================

	@Nested
	@DisplayName("Non-boot action")
	class NonBootAction {

		@Test
		@DisplayName("ignores an unrelated action without touching Context")
		void ignoresUnrelatedAction_withoutTouchingContext() {
			Intent intent = mock(Intent.class);
			when(intent.getAction()).thenReturn("android.intent.action.TIME_TICK");

			bootReceiver.onReceive(context, intent);

			verifyNoInteractions(context);
		}

		@Test
		@DisplayName("ignores a null action without touching Context")
		void ignoresNullAction_withoutTouchingContext() {
			Intent intent = mock(Intent.class);
			// getAction() returns null by default for a Mockito mock;
			// Intent.ACTION_BOOT_COMPLETED.equals(null) == false
			when(intent.getAction()).thenReturn(null);

			bootReceiver.onReceive(context, intent);

			verifyNoInteractions(context);
		}

		@Test
		@DisplayName("does not throw when action is null")
		void doesNotThrow_withNullAction() {
			Intent intent = mock(Intent.class);
			when(intent.getAction()).thenReturn(null);

			assertDoesNotThrow(() -> bootReceiver.onReceive(context, intent));
		}
	}
}

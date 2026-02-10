#
# © 2024-present https://github.com/cengiz-pz
#

extends Node

@export_category("Notification Channel")
@export var channel_id: String = "my_channel_id"
@export var channel_name: String = "My Demo Channel"
@export var channel_description: String = "My Channel Description"
@export var channel_importance: NotificationChannel.Importance = NotificationChannel.Importance.DEFAULT

@export_category("Notification Content")
@export var notification_title: String = "Godot Notification Scheduler Demo"
@export var notification_text: String = "This is a demo notification. Have you received it?"

@onready var notification_scheduler: NotificationScheduler = $NotificationScheduler as NotificationScheduler
@onready var _label: RichTextLabel = $CanvasLayer/MainContainer/VBoxContainer/RichTextLabel as RichTextLabel
@onready var _delay_slider: HSlider = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/HBoxContainer/DelayHSlider as HSlider
@onready var _delay_value_label: Label = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/HBoxContainer/ValueLabel as Label
@onready var _interval_checkbox: CheckBox = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/IntervalHBoxContainer/IntervalCheckBox as CheckBox
@onready var _interval_slider: HSlider = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/IntervalHBoxContainer/IntervalHSlider as HSlider
@onready var _interval_value_label: Label = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/IntervalHBoxContainer/ValueLabel as Label
@onready var _notification_permission_button: Button = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/PermissionsVBoxContainer/PermissionHBoxContainer/NotificationPermissionButton as Button
@onready var _optimization_permission_button: Button = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/PermissionsVBoxContainer/PermissionHBoxContainer/OptimizationPermissionButton as Button
@onready var _exact_alarm_permission_button: Button = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/PermissionsVBoxContainer/PermissionHBoxContainer/ExactAlarmButton as Button
@onready var _restart_checkbox: CheckBox = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/RestartCheckBox as CheckBox
@onready var _badge_count_slider: HSlider = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/BadgeCountHBoxContainer/BadgeCountHSlider as HSlider
@onready var _badge_count_value_label: Label = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/BadgeCountHBoxContainer/ValueLabel as Label
@onready var _badge_count_checkbox: CheckBox = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/BadgeCountHBoxContainer/CheckBox as CheckBox
@onready var _id_value_label: Label = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/ActionHBoxContainer/IdValueLabel as Label
@onready var _android_texture_rect: TextureRect = $CanvasLayer/MainContainer/VBoxContainer/HBoxContainer/AndroidTextureRect as TextureRect
@onready var _ios_texture_rect: TextureRect = $CanvasLayer/MainContainer/VBoxContainer/HBoxContainer/iOSTextureRect as TextureRect

var _active_texture_rect: TextureRect

var _notification_id: int = 1
var _channel_created: bool = false  # Track if channel has been successfully created


func _ready() -> void:
	if OS.has_feature("ios"):
		_android_texture_rect.hide()
		_active_texture_rect = _ios_texture_rect
	else:
		_ios_texture_rect.hide()
		_active_texture_rect = _android_texture_rect

	_delay_value_label.text = str(int(_delay_slider.value))
	_interval_value_label.text = str(int(_interval_slider.value))
	_badge_count_value_label.text = str(int(_badge_count_slider.value))

	_id_value_label.text = str(_notification_id)
	var __popup_menu: PopupMenu = $CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/ActionHBoxContainer/MenuButton.get_popup()
	__popup_menu.id_pressed.connect(_on_notification_id_selected)

	notification_scheduler.initialize()


func _on_notification_scheduler_initialization_completed() -> void:
	_print_to_screen("Initialization completed!")

	if notification_scheduler.has_post_notifications_permission():
		_create_channel()
	else:
		_notification_permission_button.disabled = false
		_print_to_screen("App does not have post notification permissions!")

	if notification_scheduler.is_ignoring_battery_optimizations():
		_print_to_screen("App is exempt from battery optimizations")
	else:
		_optimization_permission_button.disabled = false
		_print_to_screen("App does not have battery optimization exemption permissions!")

	if notification_scheduler.has_exact_alarm_permission():
		_print_to_screen("App has exact alarm permission")
	else:
		_exact_alarm_permission_button.disabled = false
		_print_to_screen("App does not have exact alarm permissions!")


func _create_channel() -> void:
	_print_to_screen("Creating notification channel...")
	var __result = notification_scheduler.create_notification_channel(
			NotificationChannel.new()
					.set_id(channel_id)
					.set_name(channel_name)
					.set_description(channel_description)
					.set_importance(channel_importance))

	if __result == OK:
		_print_to_screen("Channel '%s' created successfully!" % channel_id)
		_channel_created = true
	elif __result == ERR_ALREADY_EXISTS:
		_print_to_screen("Channel '%s' already exists (this is OK)" % channel_id)
		_channel_created = true  # Channel exists, so we can use it
	else:
		_channel_created = false
		match __result:
			ERR_UNCONFIGURED:
				_print_to_screen("Can't create channel %s - plugin not initialized!" % channel_id, true)
			ERR_INVALID_DATA:
				_print_to_screen("Can't create channel %s - channel data is invalid!" % channel_id, true)
			_:
				_print_to_screen("Can't create channel %s - unknown error: %d" % [channel_id, __result], true)


func _ensure_channel_exists() -> bool:
	if _channel_created:
		return true  # Channel already verified as existing
	
	# Try to create the channel
	_print_to_screen("Ensuring notification channel exists...")
	var result = notification_scheduler.create_notification_channel(
			NotificationChannel.new()
					.set_id(channel_id)
					.set_name(channel_name)
					.set_description(channel_description)
					.set_importance(channel_importance))
	
	if result == OK or result == ERR_ALREADY_EXISTS:
		_channel_created = true
		_print_to_screen("✓ Channel verified")
		return true
	else:
		_print_to_screen("Failed to create/verify channel. Error: %d" % result, true)
		return false


func _on_notification_id_selected(a_notification_id: int) -> void:
	_notification_id = a_notification_id
	$CanvasLayer/MainContainer/VBoxContainer/VBoxContainer/ActionHBoxContainer/IdValueLabel.text = str(a_notification_id)


func _on_send_button_pressed() -> void:
	# Ensure channel exists before scheduling
	if not _ensure_channel_exists():
		_print_to_screen("Cannot schedule notification: Channel not available!", true)
		return
	
	var __notification_data = NotificationData.new()\
			.set_id(_notification_id)\
			.set_channel_id(channel_id)\
			.set_title(notification_title)\
			.set_content(notification_text)\
			.set_delay(roundi(_delay_slider.value))

	if _interval_checkbox.button_pressed:
		__notification_data.set_interval(roundi(_interval_slider.value))

	if _restart_checkbox.button_pressed:
		__notification_data.set_restart_app_option()

	if _badge_count_checkbox.button_pressed:
		__notification_data.set_badge_count(roundi(_badge_count_slider.value))

	__notification_data.set_large_icon_name(NotificationScheduler.DEFAULT_ICON_NAME)
	__notification_data.set_custom_data(CustomData.new().set_int_property("my_test_int", 14)
			.set_string_property("my_test_string", "just testing"))

	_print_to_screen("Scheduling notification %d with%s a delay of %d seconds (badge count: %d)"
			% [_notification_id,
			(" an interval of %d seconds and" % int(_interval_slider.value)) if _interval_checkbox.button_pressed else "",
			int(_delay_slider.value),
			roundi(_badge_count_slider.value)])

	notification_scheduler.schedule(__notification_data)


func _on_cancel_button_pressed() -> void:
	_print_to_screen("Canceling notification %d" % _notification_id)

	notification_scheduler.cancel(_notification_id)


func _print_to_screen(a_message: String, a_is_error: bool = false) -> void:
	_label.add_text("%s\n\n" % a_message)
	if a_is_error:
		NotificationScheduler.log_error(a_message)
	else:
		NotificationScheduler.log_info(a_message)

	_label.scroll_to_line(_label.get_line_count() - 1)


func _on_delay_h_slider_value_changed(value: float) -> void:
	_delay_value_label.text = str(int(value))


func _on_interval_h_slider_value_changed(value: float) -> void:
	_interval_value_label.text = str(int(value))


func _on_badge_count_h_slider_value_changed(value: float) -> void:
	_badge_count_value_label.text = str(int(value))


func _on_notification_permission_button_pressed() -> void:
	_notification_permission_button.disabled = true
	notification_scheduler.request_post_notifications_permission()


func _on_optimization_permission_button_pressed() -> void:
	_optimization_permission_button.disabled = true
	notification_scheduler.request_ignore_battery_optimizations_permission()


func _on_exact_alarm_button_pressed() -> void:
	_exact_alarm_permission_button.disabled = true
	notification_scheduler.request_exact_alarm_permission()


func _on_notification_scheduler_post_notifications_permission_granted(permission_name: String) -> void:
	_print_to_screen("%s permission granted" % permission_name)

	_create_channel()


func _on_notification_scheduler_post_notifications_permission_denied(permission_name: String) -> void:
	_print_to_screen("%s permission denied" % permission_name)


func _on_notification_scheduler_battery_optimizations_permission_granted(permission_name: String) -> void:
	_print_to_screen("%s permission granted" % permission_name)


func _on_notification_scheduler_battery_optimizations_permission_denied(permission_name: String) -> void:
	_print_to_screen("%s permission denied" % permission_name)
	_optimization_permission_button.disabled = false


func _on_notification_scheduler_schedule_exact_alarm_permission_granted(permission_name: String) -> void:
	_print_to_screen("%s permission granted" % permission_name)


func _on_notification_scheduler_schedule_exact_alarm_permission_denied(permission_name: String) -> void:
	_print_to_screen("%s permission denied" % permission_name)
	_exact_alarm_permission_button.disabled = false


func _on_notification_scheduler_notification_opened(a_notification: NotificationData) -> void:
	_print_to_screen("Notification %d opened" % a_notification.get_id())
	_print_to_screen("CustomData.my_test_int: %d" % a_notification.get_custom_data().get_int_property("my_test_int"))
	_print_to_screen("CustomData.my_test_string: %s" % a_notification.get_custom_data().get_string_property("my_test_string"))
	notification_scheduler.set_badge_count(0)


func _on_notification_scheduler_notification_dismissed(a_notification: NotificationData) -> void:
	_print_to_screen("Notification %d dismissed" % a_notification.get_id())
	_print_to_screen("CustomData.my_test_int: %d" % a_notification.get_custom_data().get_int_property("my_test_int"))
	_print_to_screen("CustomData.my_test_string: %s" % a_notification.get_custom_data().get_string_property("my_test_string"))
	notification_scheduler.set_badge_count(0)


func _on_h_slider_value_changed(value: float) -> void:
	_badge_count_value_label.text = str(int(value))

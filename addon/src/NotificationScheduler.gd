#
# © 2024-present https://github.com/cengiz-pz
#

@tool
@icon("icon.png")
class_name NotificationScheduler extends Node

signal initialization_completed

signal post_notifications_permission_granted(permission_name: String)
signal post_notifications_permission_denied(permission_name: String)
signal battery_optimizations_permission_granted(permission_name: String)
signal battery_optimizations_permission_denied(permission_name: String)
signal schedule_exact_alarm_permission_granted(permission_name: String)
signal schedule_exact_alarm_permission_denied(permission_name: String)

signal notification_opened(notification_data: NotificationData)
signal notification_dismissed(notification_data: NotificationData)

const PLUGIN_SINGLETON_NAME: String = "@pluginName@"

const INITIALIZATION_COMPLETED_SIGNAL_NAME = "initialization_completed"
const POST_NOTIFICATIONS_PERMISSION_GRANTED_SIGNAL_NAME = "post_notifications_permission_granted"
const POST_NOTIFICATIONS_PERMISSION_DENIED_SIGNAL_NAME = "post_notifications_permission_denied"
const BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL_NAME = "battery_optimizations_permission_granted"
const BATTERY_OPTIMIZATIONS_PERMISSION_DENIED_SIGNAL_NAME = "battery_optimizations_permission_denied"
const SCHEDULE_EXACT_ALARM_PERMISSION_GRANTED_SIGNAL_NAME = "schedule_exact_alarm_permission_granted"
const SCHEDULE_EXACT_ALARM_PERMISSION_DENIED_SIGNAL_NAME = "schedule_exact_alarm_permission_denied"

const NOTIFICATION_OPENED_SIGNAL_NAME = "notification_opened"
const NOTIFICATION_DISMISSED_SIGNAL_NAME = "notification_dismissed"

const DEFAULT_NOTIFICATION_ID: int = -1
const DEFAULT_ICON_NAME: String = "ic_default_notification"

var _plugin_singleton: Object


func _connect_signals() -> void:
	_plugin_singleton.connect(INITIALIZATION_COMPLETED_SIGNAL_NAME, _on_initialization_completed)
	_plugin_singleton.connect(NOTIFICATION_OPENED_SIGNAL_NAME, _on_notification_opened)
	_plugin_singleton.connect(NOTIFICATION_DISMISSED_SIGNAL_NAME, _on_notification_dismissed)
	_plugin_singleton.connect(
		POST_NOTIFICATIONS_PERMISSION_GRANTED_SIGNAL_NAME, _on_post_notifications_permission_granted
	)
	_plugin_singleton.connect(
		POST_NOTIFICATIONS_PERMISSION_DENIED_SIGNAL_NAME, _on_post_notifications_permission_denied
	)
	_plugin_singleton.connect(
		BATTERY_OPTIMIZATIONS_PERMISSION_GRANTED_SIGNAL_NAME, _on_battery_optimizations_permission_granted
	)
	_plugin_singleton.connect(
		BATTERY_OPTIMIZATIONS_PERMISSION_DENIED_SIGNAL_NAME, _on_battery_optimizations_permission_denied
	)
	_plugin_singleton.connect(
		SCHEDULE_EXACT_ALARM_PERMISSION_GRANTED_SIGNAL_NAME, _on_schedule_exact_alarm_permission_granted
	)
	_plugin_singleton.connect(
		SCHEDULE_EXACT_ALARM_PERMISSION_DENIED_SIGNAL_NAME, _on_schedule_exact_alarm_permission_denied
	)


func initialize() -> void:
	if _plugin_singleton == null:
		if Engine.has_singleton(PLUGIN_SINGLETON_NAME):
			_plugin_singleton = Engine.get_singleton(PLUGIN_SINGLETON_NAME)
			_connect_signals()
			_plugin_singleton.initialize()
		elif not OS.has_feature("editor_hint"):
			log_error("%s singleton not found!" % PLUGIN_SINGLETON_NAME)


func create_notification_channel(a_notification_channel: NotificationChannel) -> Error:
	var __result: Error

	if _plugin_singleton:
		__result = _plugin_singleton.create_notification_channel(a_notification_channel.get_raw_data())
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
		__result == ERR_UNCONFIGURED

	return __result


func schedule(a_notification_data: NotificationData) -> Error:
	var __result: Error

	if _plugin_singleton:
		__result = _plugin_singleton.schedule(a_notification_data.get_raw_data())
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
		__result == ERR_UNCONFIGURED

	return __result


func cancel(a_notification_id: int) -> Error:
	var __result: Error

	if _plugin_singleton:
		__result = _plugin_singleton.cancel(a_notification_id)
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
		__result == ERR_UNCONFIGURED

	return __result


func set_badge_count(a_count: int) -> Error:
	var __result: Error

	if _plugin_singleton:
		__result = _plugin_singleton.set_badge_count(a_count)
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
		__result == ERR_UNCONFIGURED

	return __result


func get_notification_id(a_default_value: int = DEFAULT_NOTIFICATION_ID) -> int:
	var __result: int = a_default_value

	if _plugin_singleton:
		__result = _plugin_singleton.get_notification_id(a_default_value)
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)

	return __result


func has_post_notifications_permission() -> bool:
	var __result: bool = false
	if _plugin_singleton:
		__result = _plugin_singleton.has_post_notifications_permission()
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
	return __result


func request_post_notifications_permission() -> Error:
	var __result: Error

	if _plugin_singleton:
		__result = _plugin_singleton.request_post_notifications_permission()
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
		__result == ERR_UNCONFIGURED

	return __result


func has_battery_optimizations_permission() -> bool:
	var __result: bool = false
	if _plugin_singleton:
		__result = _plugin_singleton.has_battery_optimizations_permission()
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
	return __result


func request_battery_optimizations_permission() -> Error:
	var __result: Error

	if _plugin_singleton:
		__result = _plugin_singleton.request_battery_optimizations_permission()
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
		__result == ERR_UNCONFIGURED

	return __result


func has_schedule_exact_alarm_permission() -> bool:
	var __result: bool = false
	if _plugin_singleton:
		__result = _plugin_singleton.has_schedule_exact_alarm_permission()
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
	return __result


func request_schedule_exact_alarm_permission() -> Error:
	var __result: Error = ERR_UNCONFIGURED

	if _plugin_singleton:
		__result = _plugin_singleton.request_schedule_exact_alarm_permission()
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
		__result == ERR_UNCONFIGURED

	return __result


func open_app_info_settings() -> Error:
	var __result: Error

	if _plugin_singleton:
		__result = _plugin_singleton.open_app_info_settings()
	else:
		log_error("%s singleton not initialized!" % PLUGIN_SINGLETON_NAME)
		__result == ERR_UNCONFIGURED

	return __result


func _on_initialization_completed() -> void:
	initialization_completed.emit()


func _on_notification_opened(a_notification_data: Dictionary) -> void:
	notification_opened.emit(NotificationData.new(a_notification_data))


func _on_notification_dismissed(a_notification_data: Dictionary) -> void:
	notification_dismissed.emit(NotificationData.new(a_notification_data))


func _on_post_notifications_permission_granted(a_permission_name: String) -> void:
	post_notifications_permission_granted.emit(a_permission_name)


func _on_post_notifications_permission_denied(a_permission_name: String) -> void:
	post_notifications_permission_denied.emit(a_permission_name)


func _on_battery_optimizations_permission_granted(a_permission_name: String) -> void:
	battery_optimizations_permission_granted.emit(a_permission_name)


func _on_battery_optimizations_permission_denied(a_permission_name: String) -> void:
	battery_optimizations_permission_denied.emit(a_permission_name)


func _on_schedule_exact_alarm_permission_granted(a_permission_name: String) -> void:
	schedule_exact_alarm_permission_granted.emit(a_permission_name)


func _on_schedule_exact_alarm_permission_denied(a_permission_name: String) -> void:
	schedule_exact_alarm_permission_denied.emit(a_permission_name)


static func log_error(a_description: String) -> void:
	push_error(a_description)


static func log_info(a_description: String) -> void:
	print_rich("[color=cyan]INFO: %s[/color]" % a_description)

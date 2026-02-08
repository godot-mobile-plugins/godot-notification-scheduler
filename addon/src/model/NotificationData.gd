#
# © 2024-present https://github.com/cengiz-pz
#

class_name NotificationData extends RefCounted

const DATA_KEY_ID = "notification_id"
const DATA_KEY_CHANNEL_ID = "channel_id"
const DATA_KEY_TITLE = "title"
const DATA_KEY_CONTENT = "content"
const DATA_KEY_SMALL_ICON_NAME = "small_icon_name"
const DATA_KEY_LARGE_ICON_NAME = "large_icon_name"
const DATA_KEY_DELAY = "delay"
const DATA_KEY_DEEPLINK = "deeplink"
const DATA_KEY_INTERVAL = "interval"
const DATA_KEY_BADGE_COUNT= "badge_count"
const DATA_KEY_CUSTOM_DATA= "custom_data"

const OPTION_KEY_RESTART_APP = "restart_app"

const DEFAULT_DATA: Dictionary = {
	DATA_KEY_ID: NotificationScheduler.DEFAULT_NOTIFICATION_ID,
	DATA_KEY_SMALL_ICON_NAME: NotificationScheduler.DEFAULT_ICON_NAME
}

var _data: Dictionary


func _init(a_data: Dictionary = DEFAULT_DATA.duplicate()) -> void:
	_data = a_data


func set_id(a_id: int) -> NotificationData:
	_data[DATA_KEY_ID] = a_id
	return self


func set_channel_id(a_channel_id: String) -> NotificationData:
	_data[DATA_KEY_CHANNEL_ID] = a_channel_id
	return self


func set_title(a_title: String) -> NotificationData:
	_data[DATA_KEY_TITLE] = a_title
	return self


func set_content(a_content: String) -> NotificationData:
	_data[DATA_KEY_CONTENT] = a_content
	return self


func set_small_icon_name(a_small_icon_name: String) -> NotificationData:
	_data[DATA_KEY_SMALL_ICON_NAME] = a_small_icon_name
	return self


func set_large_icon_name(a_large_icon_name: String) -> NotificationData:
	_data[DATA_KEY_LARGE_ICON_NAME] = a_large_icon_name
	return self


func set_delay(a_delay: int) -> NotificationData:
	_data[DATA_KEY_DELAY] = a_delay
	return self


func set_deeplink(a_deeplink: String) -> NotificationData:
	_data[DATA_KEY_DEEPLINK] = a_deeplink
	return self


func set_interval(a_interval: int) -> NotificationData:
	_data[DATA_KEY_INTERVAL] = a_interval
	return self


func set_badge_count(a_count: int) -> NotificationData:
	_data[DATA_KEY_BADGE_COUNT] = a_count
	return self


func set_custom_data(a_custom_data: CustomData) -> NotificationData:
	_data[DATA_KEY_CUSTOM_DATA] = a_custom_data.get_raw_data()
	return self


func set_restart_app_option() -> NotificationData:
	_data[OPTION_KEY_RESTART_APP] = true
	return self


func get_id() -> int:
	return _data[DATA_KEY_ID]


func get_channel_id() -> String:
	return _data[DATA_KEY_CHANNEL_ID] if _data.has(DATA_KEY_CHANNEL_ID) else ""


func get_title() -> String:
	return _data[DATA_KEY_TITLE] if _data.has(DATA_KEY_TITLE) else ""


func get_content() -> String:
	return _data[DATA_KEY_CONTENT] if _data.has(DATA_KEY_CONTENT) else ""


func get_small_icon_name() -> String:
	return _data[DATA_KEY_SMALL_ICON_NAME] if _data.has(DATA_KEY_SMALL_ICON_NAME) else ""


func get_large_icon_name() -> String:
	return _data[DATA_KEY_LARGE_ICON_NAME] if _data.has(DATA_KEY_LARGE_ICON_NAME) else ""


func get_delay() -> int:
	return _data[DATA_KEY_DELAY] if _data.has(DATA_KEY_DELAY) else 0


func get_deeplink() -> String:
	return _data[DATA_KEY_DEEPLINK] if _data.has(DATA_KEY_DEEPLINK) else ""


func get_interval() -> int:
	return _data[DATA_KEY_INTERVAL] if _data.has(DATA_KEY_INTERVAL) else 0


func get_badge_count() -> int:
	return _data[DATA_KEY_BADGE_COUNT] if _data.has(DATA_KEY_BADGE_COUNT) else 0


func get_custom_data() -> CustomData:
	return CustomData.new(_data[DATA_KEY_CUSTOM_DATA]) if _data.has(DATA_KEY_CUSTOM_DATA) else null


func get_restart_app_option() -> bool:
	return _data[OPTION_KEY_RESTART_APP] if _data.has(OPTION_KEY_RESTART_APP) else false


func get_raw_data() -> Dictionary:
	return _data

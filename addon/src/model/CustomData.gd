#
# © 2024-present https://github.com/cengiz-pz
#

class_name CustomData extends RefCounted


var _data: Dictionary


func _init(a_data: Dictionary = {}) -> void:
	_data = a_data


func set_bool_property(a_key: String, a_value: bool) -> CustomData:
	_data[a_key] = a_value
	return self


func set_int_property(a_key: String, a_value: int) -> CustomData:
	_data[a_key] = a_value
	return self


func set_float_property(a_key: String, a_value: float) -> CustomData:
	_data[a_key] = a_value
	return self


func set_string_property(a_key: String, a_value: String) -> CustomData:
	_data[a_key] = a_value
	return self


func has_property(a_key: String) -> bool:
	return _data.has(a_key)


func get_bool_property(a_key: String) -> bool:
	return _data[a_key] if _data.has(a_key) else false


func get_int_property(a_key: String) -> int:
	return _data[a_key] if _data.has(a_key) else 0


func get_float_property(a_key: String) -> float:
	return _data[a_key] if _data.has(a_key) else 0.0


func get_string_property(a_key: String) -> String:
	return _data[a_key] if _data.has(a_key) else ""


func get_raw_data() -> Dictionary:
	return _data

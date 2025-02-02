@tool
extends Container

var _custom_defaults: Dictionary = {};

## Overrides inherited default for [param property].
## This method is intended to only be called from [method _init]
func set_custom_default(property: StringName, value: Variant) -> void:
	_custom_defaults[property] = value;
	set(property, value);

func _property_can_revert(property: StringName) -> bool:
	return _custom_defaults.has(property);

func _property_get_revert(property: StringName) -> Variant:
	return _custom_defaults.get(property);

## Virtual method for [member NOTIFICATION_SORT_CHILDREN].
func _sort_children() -> void:
	pass

## Virtual method for [member NOTIFICATION_THEME_CHANGED].
func _update_theme_cache() -> void:
	pass

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN: _sort_children();
		NOTIFICATION_THEME_CHANGED: _update_theme_cache();

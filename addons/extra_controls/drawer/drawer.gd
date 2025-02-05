@icon("./icon.svg")
@tool
extends CustomContainer
class_name Drawer

const CustomContainer := preload("../_shared/custom_container.gd");

@export var side: Side = SIDE_LEFT:
	get(): return side;
	set(value): side = value; queue_sort(); queue_redraw();

## Material used for rendering the backdrop while the drawer is open.
@export var backdrop_material: Material = null:
	get(): return backdrop_material;
	set(value): backdrop_material = value; queue_redraw();
	
# Backdrop is rendered separately from the drawer such that they can use different
# materials from eachother. 
var _backdrop_id: RID;

#region Related to caching theme properties
var _cached_backdrop_color: Color = Color.TRANSPARENT:
	get(): return _cached_backdrop_color;
	set(value): _cached_backdrop_color = value; queue_redraw();
	
var _cached_drawer_panel: StyleBox = null:
	get(): return _cached_drawer_panel;
	set(value): _cached_drawer_panel = value; update_minimum_size();
	
func _update_theme_cache() -> void:
	super();
	_cached_drawer_panel = get_theme_stylebox(&"panel", &"Drawer");
	_cached_backdrop_color = get_theme_color(&"backdrop", &"Drawer");
#endregion

## Value in range (0.0, 1.0). Open is represented by 1, closed by 0.
var _openess: float = 0:
	get(): return _openess;
	set(value): _openess = value; queue_sort(); queue_redraw();
	
func open() -> void:
	create_tween().tween_property(self, "_openess", 1.0, 0.2);

func close() -> void:
	create_tween().tween_property(self, "_openess", 0.0, 0.2);

var _padding: Vector2:
	get(): return _cached_drawer_panel.get_minimum_size() if _cached_drawer_panel else Vector2.ZERO;

var _padding_left: float:
	get(): return _cached_drawer_panel.content_margin_left if _cached_drawer_panel else 0.0;
var _padding_right: float:
	get(): return _cached_drawer_panel.content_margin_right if _cached_drawer_panel else 0.0;
var _padding_top: float:
	get(): return _cached_drawer_panel.content_margin_top if _cached_drawer_panel else 0.0;
var _padding_bottom: float:
	get(): return _cached_drawer_panel.content_margin_bottom if _cached_drawer_panel else 0.0;

func _enter_tree() -> void:
	_backdrop_id = RenderingServer.canvas_item_create();
	RenderingServer.canvas_item_set_parent(_backdrop_id, get_canvas_item());
	RenderingServer.canvas_item_set_draw_behind_parent(_backdrop_id, true);

func _exit_tree() -> void:
	RenderingServer.free_rid(_backdrop_id);

#region Related to drawing
func _draw() -> void:
	_draw_backdrop();
	_draw_drawer();
	
func _draw_backdrop() -> void:
	# Use same shade for opened and closed backdrop to prevent weird transitions.
	var invisible_color = Color(_cached_backdrop_color, 0);
	var effective_color = lerp(invisible_color, _cached_backdrop_color, _openess);
	
	RenderingServer.canvas_item_clear(_backdrop_id);
	if backdrop_material:
		RenderingServer.canvas_item_set_material(_backdrop_id, backdrop_material.get_rid())
	RenderingServer.canvas_item_add_rect(_backdrop_id, Rect2(Vector2.ZERO, size), effective_color);

func _draw_drawer() -> void:
	draw_style_box(_cached_drawer_panel, _calculate_drawer_area());
#endregion

func _get_minimum_size() -> Vector2:
	var result = Vector2.ZERO;
	for child in get_children():
		var control := child as Control;
		if not control: continue;
		
		result = result.max(control.get_combined_minimum_size());
	
	result += _padding;
	return result;

func _sort_children() -> void:
	var content_area := _calculate_content_area();
	
	for child in get_children():
		var control := child as Control;
		if not control: continue;
		
		fit_child_in_rect(control, content_area);

func _calculate_drawer_area() -> Rect2:
	var offset := _calculate_content_area_offset();
	var size := _calculate_content_area_size();
	return Rect2(offset, size);

func _calculate_content_area() -> Rect2:
	var size = _calculate_content_area_size();
	var offset = _calculate_content_area_offset();
	
	return  Rect2(offset, size).grow_individual(
		-_padding_left,
		-_padding_top,
		-_padding_right,
		-_padding_bottom
	);

func _calculate_content_area_offset() -> Vector2:
	var content_size := get_combined_minimum_size();
	var available_size := size;
	
	match side:
		SIDE_LEFT:   return Vector2(-content_size.x * (1.0 - _openess), 0.0);
		SIDE_RIGHT:  return Vector2(available_size.x - content_size.x * _openess, 0.0);
		SIDE_TOP:    return Vector2(0.0, -content_size.y * (1.0 - _openess));
		SIDE_BOTTOM: return Vector2(0.0, available_size.y - content_size.y * _openess);
	return Vector2.ZERO;

func _calculate_content_area_size() -> Vector2:
	var content_size := get_combined_minimum_size();
	var available_size := size;
	
	match side:
		SIDE_LEFT, SIDE_RIGHT:
			return Vector2(content_size.x, available_size.y);
		SIDE_TOP, SIDE_BOTTOM:
			return Vector2(available_size.x, content_size.y);
	return Vector2.ZERO;

func _gui_input(event: InputEvent) -> void:
	match event.get_class():
		"InputEventScreenTouch":
			if event.is_pressed():
				_begin_touch(event);
			else:
				_end_touch(event);
		"InputEventScreenDrag":
			_touch_move(event);
			pass

var _is_gesturing: bool = false;

func _begin_touch(event: InputEventScreenTouch) -> void:
	var area := _calculate_drawer_area();
	var axis_position := 0.0; 
	match side:
		SIDE_LEFT: axis_position = event.position.x - area.end.x;
		SIDE_RIGHT: axis_position = -(event.position.x - area.position.x);
		SIDE_TOP: axis_position = event.position.y - area.end.y;
		SIDE_BOTTOM: axis_position = -(event.position.y - area.position.y);
		
	if axis_position < 20:
		_is_gesturing = true

func _touch_move(event: InputEventScreenDrag) -> void:
	if not _is_gesturing: return;
	
	var size := get_minimum_size();
	
	match side:
		SIDE_LEFT: _openess = clamp(_openess + (event.relative.x / size.x), 0, 1) 
		SIDE_RIGHT: _openess = clamp(_openess - (event.relative.x / size.x), 0, 1) 
		SIDE_TOP: _openess = clamp(_openess + (event.relative.y / size.y), 0, 1) 
		SIDE_BOTTOM: _openess = clamp(_openess - (event.relative.y / size.y), 0, 1) 

func _end_touch(event: InputEventScreenTouch) -> void:
	if _is_gesturing:
		_is_gesturing = false;
		if _openess > 0.5: open(); 
		else: close();
		return;

	var area := _calculate_drawer_area();
	if not area.has_point(event.position):
		close()
	pass

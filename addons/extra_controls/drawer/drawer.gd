@icon("./icon.svg")
@tool
extends CustomContainer

const CustomContainer := preload("../_shared/custom_container.gd");

## Material used for rendering the backdrop while the drawer is open.
@export var backdrop_material: Material = null:
	get(): return backdrop_material;
	set(value): backdrop_material = value; queue_redraw();
	
# Backdrop is rendered separately from the drawer such that they can use different
# materials from eachother. 
var _backdrop_id: RID;

var _cached_backdrop_color: Color = Color.TRANSPARENT:
	get(): return _cached_backdrop_color;
	set(value): _cached_backdrop_color = value; queue_redraw();
	
var _cached_drawer_panel: StyleBox = null:
	get(): return _cached_drawer_panel;
	set(value): _cached_drawer_panel = value; queue_redraw();

func _init() -> void:
	set_custom_default(&"clip_children", CLIP_CHILDREN_AND_DRAW);
	
func _enter_tree() -> void:
	_backdrop_id = RenderingServer.canvas_item_create();
	RenderingServer.canvas_item_set_parent(_backdrop_id, get_canvas_item());
	RenderingServer.canvas_item_set_draw_behind_parent(_backdrop_id, true);

func _exit_tree() -> void:
	RenderingServer.free_rid(_backdrop_id);

func _draw() -> void:
	_draw_backdrop();
	_draw_drawer();
	
func _draw_backdrop() -> void:
	RenderingServer.canvas_item_clear(_backdrop_id);
	RenderingServer.canvas_item_add_rect(_backdrop_id, Rect2(Vector2.ZERO, size), _cached_backdrop_color);

func _draw_drawer() -> void:
	pass

func _sort_children() -> void:
	var children := get_children();

func _update_theme_cache() -> void:
	super();

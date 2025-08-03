extends HBoxContainer

@export var node: Node

@onready var property_class = $PropertyClass
@onready var property_name = $PropertyName

var data: Dictionary
var index: int

func _process(delta: float) -> void:
	data = node.get_property_list()[index]
	property_class.text = "  " + type_string(data.type)
	property_name.text = data.name
	tooltip_text = "Value: " + str(node.get(data.name))

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		DisplayServer.clipboard_set(str(node.get(property_name.text)))

extends TabContainer

const property_box = preload("res://addons/beatscript/debug/property_box.tscn")
const signal_box = preload("res://addons/beatscript/debug/signal_box.tscn")

@onready var properties: VBoxContainer = $Properties/VBoxContainer
@onready var methods: VBoxContainer = $Methods/VBoxContainer
@onready var signals: VBoxContainer = $Signals/VBoxContainer

var node_path: String
var property_list: Array[Dictionary]
var method_list: Array[Dictionary]
var signal_list: Array[Dictionary]

func _on_item_selected(path: NodePath):
	var node: Node = get_node(path)
	node_path = path

	property_list = node.get_property_list()#; print(property_list)
	method_list = node.get_method_list()#; print(method_list)
	signal_list = node.get_signal_list()#; print(signal_list)

	# Add Properties
	for child in properties.get_children():
		child.free()

	var is_owner: bool
	for property in property_list:
		if property.usage == PROPERTY_USAGE_CATEGORY:
			# We don't need to add anything from the Owner since we can select that as well.
			is_owner = property.name == "owner"
			if is_owner: continue

			var header_name: String = property.hint_string
			if header_name.is_empty(): 
				var header: Label = add_header(property.name, 20)
				header.modulate.a = 0.75
				continue

			add_header(header_name, 24)
		elif property.usage == PROPERTY_USAGE_GROUP:
			if is_owner: continue
			var header: Label = add_header(property.name, 20)
			header.modulate.a = 0.75
		elif property.usage == PROPERTY_USAGE_SUBGROUP:
			if is_owner: continue
			var header: Label = add_header(property.name, 18)
			header.modulate.a = 0.6
		elif property.name.begins_with("metadata/_"): continue
		else:
			if is_owner: continue
			var box = property_box.instantiate()
			box.node = node
			box.index = property_list.find(property)
			properties.add_child(box)

	# Add Methods
	for child in methods.get_children():
		child.free()
	for method in method_list:
		var box = signal_box.instantiate()
		box.data = method
		methods.add_child(box)

	# Add Signals
	for child in signals.get_children():
		child.free()
	for sigma in signal_list:
		var box = signal_box.instantiate()
		box.data = sigma
		signals.add_child(box)

func add_header(text: String, font_size: int) -> Label:
	var header: Label = Label.new()
	header.text = " " + text
	header.add_theme_font_size_override("font_size", font_size)
	properties.add_child(header)
	return header

extends CanvasLayer

## If true, this overlay can also be used to edit Property values.
@export var edit_mode: bool
## Excludes any path that begins with these strings from the overlay. They're still created and in the Tree, but you can't see or access it from the Tree. This can also be used to make it easier to prevent the game from crashing when using this feature.
@export var excluded_paths: Array[String] = ["/root/BangerScript"]
## Toggles the visibility of the BangerScript Debug Overlay. This can be changed to any keybind that fits the needs of your game. By default, it's set to F1.
@export var toggle_keybind: Shortcut

@onready var node_tree: Tree = $NodeTree
@onready var node_info: TabContainer = $NodeInfo

var node_open: bool # Checks if a Node has been selected for viewing or editing.
var tree_items: Array[TreeItem] # Helps keep track of where the items are positioned
var tree_string: String

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)
	hide()

	tree_string = get_tree().root.get_tree_string()
	node_tree.clear(); tree_items.clear()

	# Setup connections to the nodes
	var node_list: Array = tree_string.split("\n")
	node_list.resize(node_list.size() - 1) # Remove empty space

	for node in node_list:
		if node == ".": # This is always the root
			create_tree_item(node)
		else:
			var path: Array = node.split("/")
			var root: String = path.back()
			if path.size() > 1:
				root = node.left(-("/" + path.back()).length())
			create_tree_item("/root/" + node, tree_items.filter(filter_by_tooltip.bind("/root/" + root)).front() if path.size() > 1 else node_tree.get_root(), node_list.find(root))

	# Setup connections to the nodes
	node_tree.item_selected.connect(func():
		if node_tree.get_selected() != null:
			await get_tree().process_frame
			node_info._on_item_selected(node_tree.get_selected().get_tooltip_text(0)))

func _input(event: InputEvent) -> void:
	if toggle_keybind.matches_event(event) and event.is_pressed():
		toggle()

func toggle():
	if visible: hide()
	else: show()

# Function to search by tooltip since that's the full path we'll use to search for nodes and sort the tree
func filter_by_tooltip(item: TreeItem, path: String):
	return item.get_tooltip_text(0) == path

# Remove EVERY Null instance
func remove_null_instances():
	for i in range(tree_items.size() - 1, -1, -1):
		var item: TreeItem = tree_items[i]
		if not is_instance_valid(item):
			tree_items.remove_at(i)

func create_tree_item(path: String, parent: TreeItem = null, index: int = -1):
	if path == ".": # This is always the root
		var root: TreeItem = node_tree.create_item()
		root.set_text(0, "Window")
		root.set_tooltip_text(0, "/root")
		root.set_suffix(0, "- root")
		tree_items.append(root)
	else:
		var node: Node = get_node(path)
		var item: TreeItem = node_tree.create_item(parent, index)

		item.collapsed = true
		item.set_text(0, node.get_class())
		var rename_item = func(n: Node):
			item.set_tooltip_text(0, n.get_path())
			item.set_suffix(0, "- " + n.name)
			item.visible = true
			for p in excluded_paths:
				if item.get_tooltip_text(0).begins_with(p):
					item.visible = false; break

		rename_item.call(node)
		node.renamed.connect(rename_item.bind(node))

		# I would've done a MATCH here, but I don't know how to do that for getting Node super classes
		# Also I would've used icons, but the Editor icons aren't built-in
		if node is Node2D:
			item.set_custom_color(0, Color.CORNFLOWER_BLUE)
		elif node is Node3D:
			item.set_custom_color(0, Color.INDIAN_RED)
		elif node is Control:
			item.set_custom_color(0, Color.PALE_GREEN)

		tree_items.insert(index, item)

func remove_tree_item(node: Node):
	var item: TreeItem = tree_items.filter(filter_by_tooltip.bind(node.get_path())).front()
	tree_items.erase(item)
	item.free()
	tree_string = get_tree().root.get_tree_string()

func _on_node_added(node: Node):
	if node == null: return

	if tree_items.filter(filter_by_tooltip.bind(node.get_path())).is_empty():
		remove_null_instances()
		tree_string = get_tree().root.get_tree_string()
		var node_list: Array = tree_string.split("\n")
		node_list.resize(node_list.size() - 1)

		var path: Array = (node.get_path() as String).right(-"/root/".length()).split("/")
		var root: String = path.back()
		if path.size() > 1:
			root = (node.get_path() as String).right(-"/root/".length()).left(-("/" + path.back()).length())
		create_tree_item(node.get_path(), tree_items.filter(filter_by_tooltip.bind("/root/" + root)).front() if path.size() > 1 else node_tree.get_root(), node_list.find(root))

func _on_node_removed(node: Node):
	if get_tree() == null: return # This means the Window is closed
	if tree_items.filter(filter_by_tooltip.bind(node.get_path())).size() > 0:
		remove_tree_item(node)

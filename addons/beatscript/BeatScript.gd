extends Node

@onready var scripts: Node

var variables: Dictionary

func _init() -> void:
	scripts = Node.new()
	scripts.name = "GDScripts"
	add_child(scripts)

func _ready() -> void:
	if OS.get_cmdline_args().has("--beat-debug"):
		add_child(preload("res://addons/beatscript/debug/DebugOverlay.tscn").instantiate())

## Easy way to get a list of [GDScript] files from a given location.
func get_scripts_at(path: String) -> Array:
	if not DirAccess.dir_exists_absolute(path): return []
	var array: Array = DirAccess.get_files_at(path)
	return array.filter(func(a): return a.get_extension() == "gd")

## Adds a script to the current scene from the given location.
func add_script(path: String, global: bool = false):
	if not FileAccess.file_exists(path): return
	for node in scripts.get_children(): if node.scene_file_path == path: return

	var script: String = FileAccess.get_file_as_string(path)
	var extend_pos: int = script.find("extends ")
	if extend_pos < 0: return

	var extend: String = script.erase(0, extend_pos + "extends ".length()).split("\n")[0].dedent()
	var node = ClassDB.instantiate(extend)
	node.scene_file_path = path
	node.name = path.get_file().get_basename().to_pascal_case() + ("@Global" if global else "")
	node.set_script(ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE))
	scripts.add_child(node)

	return node

## Checks if a script exists at the given path.
func has_script(path: String) -> bool:
	for node in scripts.get_children(): if node.scene_file_path == path:
		return true
	return false

## Returns the index of the child using the given script in this class.
func find_script(path: String) -> int:
	for node in scripts.get_children(): if node.scene_file_path == path:
		return node.get_index()
	return -1

## Removes a script from the current scene. However, it can still be used or re-added if you store it in a variable.
func remove_script(path: String):
	for node in scripts.get_children(): if node.scene_file_path == path:
		scripts.remove_child(node)
		return node

## Completely removes a script from the current scene if it is running. After using this, you'll need to use `add_script` to add it back to the scene.
func free_script(path: String):
	for node in scripts.get_children(): if node.scene_file_path == path:
		node.queue_free()
		break

## Easy way to free all the loaded scripts. Does not remove Global scripts automatically unless you specify to do so.
func clear_scripts(remove_globals: bool = false):
	for node in scripts.get_children():
		if not remove_globals and node.name.ends_with("_Global"): continue
		node.queue_free()

## Sets a global variable from a script.
func set_var(n: String, value, path: String):
	for node in scripts.get_children(): if node.scene_file_path == path:
		if not variables.has(path): variables[path] = {}
		variables[path][n] = value

## Gets a global variable from a script.
func get_var(n: String, path: String, fallback = null) -> Variant:
	for node in scripts.get_children(): if node.scene_file_path == path:
		if not variables.has(path): break
		return variables[path].get(n, fallback)
	return fallback

## Gets a global variable from a script, or adds it if the variable doesn't exist.
func get_or_add_var(n: String, path: String, fallback = null) -> Variant:
	for node in scripts.get_children(): if node.scene_file_path == path:
		if not variables.has(path): variables[path] = {}
		return variables[path].get_or_add(n, fallback)
	return fallback

## Removes a global variable assigned by a script.
func remove_var(n: String, path: String):
	for node in scripts.get_children(): if node.scene_file_path == path:
		if not variables.has(path): break
		variables[path].erase(n)
		if variables[path].is_empty(): variables.erase(path)
		break

## Checks if a given method exists and if that method is connected to a signal within a node. If so, it applies the connection.
func connect_node(node: Node, method: String, sigma: Signal) -> bool:
	if node.has_method(method) and !sigma.is_connected(node[method]):
		sigma.connect(node[method]); return true
	return false

## Checks if a given method exists and if that method is connected to a signal within a node. If so, it disconnects the method and signal.
func disconnect_node(node: Node, method: String, sigma: Signal) -> bool:
	if node.has_method(method) and sigma.is_connected(node[method]):
		sigma.disconnect(node[method]); return true
	return false

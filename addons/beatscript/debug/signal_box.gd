extends Label

var data: Dictionary

func _ready() -> void:
	text = "  " + data.name + "("
	for i in data.args.size():
		var arg: Dictionary = data.args[i]
		text += arg.name + ": "
		text += type_string(arg.type) if arg.class_name.is_empty() else arg.class_name
		if i < data.args.size() - 1: text += ", "
	text += ")"

	# Get Return type
	var return_value: String = type_string(data.return.type) if data.return.class_name.is_empty() else data.return.class_name
	if not return_value.is_empty() and return_value != "Nil":
		text += " -> " + return_value

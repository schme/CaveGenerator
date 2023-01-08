tool
extends HBoxContainer
class_name PropertySlider

onready var value_label: Label = $ValueLabel
onready var control: Slider = $ControlSlider

signal value_changed(val)

func _on_value_changed(val: float):
	value_label.text = "%6.2f" % val
	emit_signal("value_changed", val)

func set_value(val: float):
	control.value = val

func get_value():
	return control.value

func _ready():
# warning-ignore:return_value_discarded
	control.connect("value_changed", self, "_on_value_changed")
	_on_value_changed(control.value)

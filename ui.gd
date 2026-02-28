# ui.gd
extends Control

# Get references to the labels (use % syntax for unique names within the scene)
@onready var mineral_label: Label = $mainUI/VBoxContainer/MineralLabel
@onready var mps_label: Label = $mainUI/VBoxContainer/MPSLabel

func _process(delta: float) -> void:
	# Update the labels frequentlys
	# Format the float to show maybe 1 decimal place
	mineral_label.text = "Minerals: %.1f" % GameManager.minerals
	mps_label.text = "MPS: %.1f" % GameManager.minerals_per_second

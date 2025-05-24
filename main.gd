extends Node

@export var rock_scene: PackedScene
var screensize = Vector2.ZERO

func _ready():
	screensize = get_viewport().get_visible_rect().size
	for i in 3:
		spawn_rock(3)

func spawn_rock(size, pos=null, vel=null):
	if pos == null:
		pass

extends Node3D

@onready var ball = $Ball
@onready var bricks_container = $Bricks

# Updated path to point to test1 directory
var brick_scene_path = "res://test1/scenes/brick.tscn"

func _ready():
	spawn_bricks()

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		ball.start_game()

func spawn_bricks():
	var brick_res = load(brick_scene_path)
	if not brick_res:
		print("Error loading brick scene at: ", brick_scene_path)
		return

	var rows = 5
	var cols = 8
	var start_x = -7.0
	var start_z = -8.0
	var spacing_x = 2.0
	var spacing_z = 1.0

	for r in range(rows):
		for c in range(cols):
			var brick = brick_res.instantiate()
			bricks_container.add_child(brick)
			brick.position = Vector3(start_x + c * spacing_x, 0.5, start_z + r * spacing_z)

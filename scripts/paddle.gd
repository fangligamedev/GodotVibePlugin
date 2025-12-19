extends CharacterBody3D

@export var speed: float = 10.0

func _physics_process(delta):
	var input_dir = Input.get_axis("ui_left", "ui_right")
	var direction = Vector3(input_dir, 0, 0)
	
	if direction:
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	move_and_slide()

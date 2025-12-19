extends CharacterBody3D

@export var speed: float = 15.0
@export var limit_x: float = 9.0

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	# Clamp position
	position.x = clamp(position.x, -limit_x, limit_x)

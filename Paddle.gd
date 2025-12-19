extends CharacterBody3D

@export var speed = 15.0

func _physics_process(delta):
	# 获取水平输入的轴值 (-1 到 1)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

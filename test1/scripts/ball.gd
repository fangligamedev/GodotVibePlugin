extends CharacterBody3D

@export var speed: float = 12.0
var direction: Vector3 = Vector3.ZERO
var active: bool = false

func start_game():
	if not active:
		active = true
		direction = Vector3(randf_range(-0.5, 0.5), 0, -1).normalized()

func _physics_process(delta):
	if not active:
		return

	var collision_info = move_and_collide(direction * speed * delta)
	if collision_info:
		direction = direction.bounce(collision_info.get_normal())
		var collider = collision_info.get_collider()
		if collider.has_method("hit"):
			collider.hit()

		# Prevent pure horizontal loop
		if abs(direction.z) < 0.1:
			direction.z = sign(direction.z) * 0.1
			direction = direction.normalized()

	if global_position.z > 5.0:
		get_tree().reload_current_scene()

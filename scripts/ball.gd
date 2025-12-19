extends RigidBody3D

@export var launch_speed: float = 15.0
var active: bool = false

func _ready():
	contact_monitor = true
	max_contacts_reported = 3

func launch(direction: Vector3):
	if active: return
	active = true
	linear_velocity = direction.normalized() * launch_speed

func _physics_process(delta):
	# 1. Check Game Over
	if global_position.z > 15.0:
		print("Game Over")
		get_tree().reload_current_scene()
	
	# 2. Maintain Speed (Arcade physics)
	if active and linear_velocity.length() < launch_speed:
		linear_velocity = linear_velocity.normalized() * launch_speed
	
	# 3. Handle Collisions
	for body in get_colliding_bodies():
		if body.has_method("hit"):
			body.hit()

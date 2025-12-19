extends Node3D

const PADDLE_SCRIPT = preload("res://scripts/paddle.gd")
const BALL_SCRIPT = preload("res://scripts/ball.gd")
const BRICK_SCRIPT = preload("res://scripts/brick.gd")

func _ready():
	setup_environment()
	create_walls()
	create_paddle()
	create_ball()
	create_bricks()

func setup_environment():
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 15, 10)
	cam.rotation_degrees = Vector3(-60, 0, 0)
	add_child(cam)
	
	# Light
	var light = DirectionalLight3D.new()
	light.position = Vector3(0, 10, 0)
	light.rotation_degrees = Vector3(-45, 0, 0)
	light.shadow_enabled = true
	add_child(light)

func create_walls():
	# Simple function to make a wall
	var make_wall = func(pos, size):
		var body = StaticBody3D.new()
		body.position = pos
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = BoxMesh.new()
		mesh_inst.mesh.size = size
		body.add_child(mesh_inst)
		var col = CollisionShape3D.new()
		col.shape = BoxShape3D.new()
		col.shape.size = size
		body.add_child(col)
		add_child(body)
	
	# Left, Right, Top walls
	make_wall.call(Vector3(-11, 1, 0), Vector3(1, 2, 30))
	make_wall.call(Vector3(11, 1, 0), Vector3(1, 2, 30))
	make_wall.call(Vector3(0, 1, -15), Vector3(23, 2, 1))

func create_paddle():
	var paddle = CharacterBody3D.new()
	paddle.name = "Paddle"
	paddle.set_script(PADDLE_SCRIPT)
	paddle.position = Vector3(0, 1, 10)
	
	var mesh = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = Vector3(4, 1, 1)
	paddle.add_child(mesh)
	
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(4, 1, 1)
	paddle.add_child(col)
	
	add_child(paddle)

func create_ball():
	var ball = RigidBody3D.new()
	ball.name = "Ball"
	ball.set_script(BALL_SCRIPT)
	ball.position = Vector3(0, 1, 8)
	ball.axis_lock_linear_y = true # Lock Y movement
	ball.axis_lock_angular_x = true
	ball.axis_lock_angular_z = true
	
	# Physics Material (Bouncy)
	var phys_mat = PhysicsMaterial.new()
	phys_mat.bounce = 1.0
	phys_mat.friction = 0.0
	ball.physics_material_override = phys_mat
	
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.5
	mesh.mesh.height = 1.0
	ball.add_child(mesh)
	
	var col = CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	col.shape.radius = 0.5
	ball.add_child(col)
	
	add_child(ball)
	# Launch immediately for demo
	ball.call_deferred("launch", Vector3(1, 0, -1))

func create_bricks():
	for x in range(-4, 5):
		for z in range(-3, 1):
			var brick = StaticBody3D.new()
			brick.set_script(BRICK_SCRIPT)
			brick.position = Vector3(x * 2.2, 1, z * 1.5 - 5)
			brick.add_to_group("Bricks")
			
			var mesh = MeshInstance3D.new()
			mesh.mesh = BoxMesh.new()
			mesh.mesh.size = Vector3(2, 1, 1)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(randf(), randf(), randf())
			mesh.mesh.material = mat
			brick.add_child(mesh)
			
			var col = CollisionShape3D.new()
			col.shape = BoxShape3D.new()
			col.shape.size = Vector3(2, 1, 1)
			brick.add_child(col)
			
			add_child(brick)

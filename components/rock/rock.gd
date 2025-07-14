extends RigidBody2D

var screensize = Vector2.ZERO
var size
var radius
var scale_factor = 0.2

signal exploded

func start(_position, _velocity, _size):
	screensize = DisplayServer.screen_get_size()
	position = _position
	size = _size
	mass = 1.5 * size
	
	# set explosion force based on size 
	$Explosion.scale = Vector2.ONE * 0.75 * size
	
	# we set the scale based on size given, and create the shape
	$Sprite2D.scale = Vector2.ONE * scale_factor * size
	radius = int($Sprite2D.texture.get_size().x / 2 * $Sprite2D.scale.x)
	var shape = CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape

	linear_velocity = _velocity
	angular_velocity = randf_range(-PI, PI)

func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0 - radius, screensize.x + radius)
	xform.origin.y = wrapf(xform.origin.y, 0 - radius, screensize.y + radius)
	physics_state.transform = xform

func explode():
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion/AnimationPlayer.play("explosion")
	$Explosion.show()
	exploded.emit(size, radius, position, linear_velocity)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	await $Explosion/AnimationPlayer.animation_finished
	queue_free()

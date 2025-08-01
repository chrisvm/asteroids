extends RigidBody2D

enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = INIT

@export var bullet_scene: PackedScene
@export var fire_rate = 0.25
@export var turn_strength = 1.5

# vars concerning the pid algo
@export var pid_kp: float = 10.0
@export var pid_kd: float = 5.0
var angle_error = 0
var error_derivative = 0
var last_angle_error: float = 0.0

var can_shoot = true

@export var engine_power = 500

var thrust = Vector2.ZERO
var rotation_dir = 0
var screensize = Vector2.ZERO
 
signal lives_changed
signal dead

var reset_pos = false
var lives = 0: set = set_lives

func _ready() -> void:
	change_state(ALIVE)
	$GunCooldown.wait_time = fire_rate
	$GunCooldown.timeout.connect(_on_gun_cooldown_timeout)
	screensize = get_viewport_rect().size
	
func _process(delta):
	get_input()
	
func _on_gun_cooldown_timeout() -> void:
	can_shoot = true

func set_lives(value):
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)

func reset():
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)
	
func get_input():
	if state in [DEAD, INIT]:
		return
	
	thrust = Vector2.ZERO
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()
	
	# handle mouse inmput
	var to_mouse = get_global_mouse_position() - global_position
	var target_angle = to_mouse.angle()
	angle_error = wrapf(target_angle - rotation, -PI, PI)

func _physics_process(delta: float) -> void:
	constant_force = thrust
	error_derivative = (angle_error - last_angle_error) / delta

func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false

	var torque = angle_error * pid_kp - error_derivative * pid_kd
	physics_state.apply_torque(torque)

	last_angle_error = angle_error
	
	# wrap the player around the screen
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform
	
func shoot():
	if state == INVULNERABLE:
		return
	can_shoot = false   
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)
	
func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
	state = new_state

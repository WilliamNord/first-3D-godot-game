extends CharacterBody3D

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0 
var speed_boost = 1 # spiller fart modifyer
var gravity = 9.8  # Legger til tyngdekraft
const JUMP_VELOCITY = 7

@onready var player: CharacterBody3D = $"."

#@onready var camera_3d: Camera3D = $TwistPivot/PitchPivot/Camera3D
#var camera_children = get_children() #prøvde å få pistiolene til å rotere litt til siden du gikk mot

@onready var camera_3d: Camera3D = $TwistPivot/PitchPivot/Camera3D
@onready var ray_cast_3d: RayCast3D = $TwistPivot/PitchPivot/Camera3D/RayCast3D
@onready var hold_position: Node3D = $TwistPivot/PitchPivot/Camera3D/HoldPosition

#prøve å holde ting
#var held_object : Object

#Muzzle Flashing
@onready var omni_light_3d: OmniLight3D = $TwistPivot/PitchPivot/Camera3D/MuzzleFlash/OmniLight3D
@onready var muzzle_flash: GPUParticles3D = $TwistPivot/PitchPivot/Camera3D/MuzzleFlash/MuzzleFlash
@onready var muzzle_timer: Timer = $TwistPivot/PitchPivot/Camera3D/MuzzleFlash/MuzzleTimer

@onready var texture_progress_bar: TextureProgressBar = $UI/Control/TextureProgressBar


@onready var world_environment: WorldEnvironment = $"../WorldEnvironment"


@onready var gun: MeshInstance3D = $TwistPivot/PitchPivot/Camera3D/Gun
@onready var also_gun: MeshInstance3D = $TwistPivot/PitchPivot/Camera3D/AlsoGun
@onready var also_gun_2: MeshInstance3D = $TwistPivot/PitchPivot/Camera3D/AlsoGun2

#var full_gun = [gun, also_gun, also_gun_2]
#
##funksjon for å sette alle gun deler til synlig eller usynlg
#func set_full_gun_visible(state: bool):
	#for i in full_gun:
		#i.visible = state

var wepon_held = gun

@onready var grenade_launcher: Node3D = $TwistPivot/PitchPivot/Camera3D/GrenadeLauncher
var grenade_launcher_held = false
@onready var grenade_pos: Node3D = $Grenade_pos
var grenade_shell = load("res://grenade_shell.tscn")


@onready var sniper_rifle_01: MeshInstance3D = $TwistPivot/PitchPivot/Camera3D/SniperRifle01

@onready var shader: MeshInstance3D = $TwistPivot/PitchPivot/Camera3D/Shader


@onready var gun_shot: AudioStreamPlayer3D = $TwistPivot/PitchPivot/Camera3D/Gun/GunShot
@onready var slow_gun_shot: AudioStreamPlayer3D = $TwistPivot/PitchPivot/Camera3D/Gun/SlowGunShot

@onready var timestop_sound: AudioStreamPlayer3D = $timestop_sound
@onready var time_speed_up_sound: AudioStreamPlayer3D = $TimeSpeedUp_sound
@onready var time_speed_up_wait: Timer = $TimeSpeedUp_wait

@onready var progress_bar: ProgressBar = $UI/Control/ProgressBar

var bullet = load("res://bullet.tscn") # Laster inn bullet scene
@onready var pos = $TwistPivot/PitchPivot/Camera3D/Pos # Bullet spawn posisjon
@onready var can_shoot_timer: Timer = $can_shoot_timer # Tid før skyting igjen
@onready var reloading_timer: Timer = $reloading_timer

#grapple
@onready var grapple_ray: RayCast3D = $TwistPivot/PitchPivot/Camera3D/Grapple
@onready var grapple_point: MeshInstance3D = $TwistPivot/PitchPivot/Camera3D/Grapple_point


#can shoot, reload, timeslow
var can_shoot = true
var is_reloading = false
var time_slowed = false



#time slow progressbar
var progressbar_up = false
var progressbar_down = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print(bullet_count_gun, "this is label")
	omni_light_3d.visible = false
	muzzle_flash.emitting = false
	wepon_held = gun

func _TimeSpeedUp():
	Engine.time_scale = 1.0
	progressbar_up = true
	speed_boost = 1.5
	time_slowed = false
	can_shoot_timer.wait_time = 0.2
	reloading_timer.wait_time = 2.0
	shader.visible = false
	progressbar_up = true
	progressbar_down = false
	time_speed_up_sound.play()
	world_environment.environment.volumetric_fog_enabled = false
	
#gun ammo
@onready var bullet_count_gun = $UI/Control/bullet_count
var texts = ["6/6", "5/6", "4/6", "3/6", "2/6", "1/6", "reloading..."]
var index = 1

#grenade ammo
@onready var bullet_count_grenade_launcher = $UI/Control/bullet_count
var texts_grenade = ["4/4", "3/4", "2/4", "1/4","reloading..."]
var index_grenade = 1

func shoot_gun():
	var instance = bullet.instantiate()
	instance.position = pos.global_position
	instance.transform.basis = pos.global_transform.basis
	get_parent().add_child(instance)
	bullet_count_gun.text = texts[index]
	index = (index + 1) % texts.size()
	can_shoot_timer.start()
	can_shoot = false
	if time_slowed == true:
		slow_gun_shot.play()
	else:
		gun_shot.play()
		omni_light_3d.visible = true
		muzzle_flash.emitting = true
		muzzle_timer.start()

func shoot_grenade_launcher():
	var instance = grenade_shell.instantiate()
	instance.position = pos.global_position
	instance.transform.basis = pos.global_transform.basis
	get_parent().add_child(instance)
	bullet_count_grenade_launcher.text = texts[index]
	index = (index + 1) % texts.size()
	can_shoot_timer.start()
	can_shoot = false
	if time_slowed == true:
		slow_gun_shot.play()
	else: 
		gun_shot.play()
		omni_light_3d.visible = true
		muzzle_flash.emitting = true
		muzzle_timer.start()
	

	

func _process(delta: float) -> void:  
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	
	
	# Bevegelse basert på CharacterBody3D
	var direction = ($TwistPivot.basis * Vector3(input.x, 0, input.z)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * 5 * speed_boost
		velocity.z = direction.z * 5 * speed_boost
	elif is_on_floor() == true:
		velocity = Vector3.ZERO
	
	#if Input.is_action_just_pressed("move_right"):
		#for child in camera_children:
			#child.rotation.z = lerp_angle(child.rotation.z, 0.5, 0.2)
		##camera_children.rotation.z = lerp_angle(camera_children.rotation.z, camera_children.rotation.z - 0.5, 0.1)
		#
		
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Håndterer gravitasjon
	if not is_on_floor():
		if time_slowed == true:
			velocity.y -= gravity * delta * (1.5 / Engine.time_scale) * 5
		else:
			velocity.y -= gravity * delta * 1.5

	move_and_slide()  # Bruker CharacterBody3D sin metode for bevegelse

	# Kamera rotasjon
	$TwistPivot.rotate_y(twist_input)
	$TwistPivot/PitchPivot.rotate_x(pitch_input)
	$TwistPivot/PitchPivot.rotation.x = clamp(
		$TwistPivot/PitchPivot.rotation.x,
		-1.5,
		1.5
	)
	twist_input = 0.0
	pitch_input = 0.0
	
	
	if Input.is_action_just_pressed("button_1"):
		gun.visible = true
		also_gun.visible = true
		also_gun_2.visible = true
		grenade_launcher.visible = false
		sniper_rifle_01.visible = false
		wepon_held = gun
	
	
	if Input.is_action_just_pressed("button_2"):
		gun.visible = false
		also_gun.visible = false
		also_gun_2.visible = false
		grenade_launcher.visible = true
		sniper_rifle_01.visible = false
		wepon_held = grenade_launcher
	

	# Skyting
	if Input.is_action_just_pressed("click"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif can_shoot and not is_reloading:
			if wepon_held == gun:
				shoot_gun()
			elif wepon_held == grenade_launcher:
				shoot_grenade_launcher()

	if Input.is_action_just_pressed("click") and index == 7 % texts.size() and not is_reloading:
		is_reloading = true
		reloading_timer.start()

	if Input.is_action_just_pressed("reload(manual)") and not is_reloading:
		index = 6
		bullet_count_gun.text = texts[index]
		reloading_timer.start()
		is_reloading = true


	# Tidsslowing
	if Input.is_action_just_pressed("time"):
		if not time_slowed:
			Engine.time_scale = 0.01
			progressbar_down = true
			progressbar_up = false
			time_slowed = true
			speed_boost = 1.0 / Engine.time_scale * 1
			can_shoot_timer.wait_time = 1.0 * Engine.time_scale
			reloading_timer.wait_time = 2 * Engine.time_scale
			shader.visible = true
			timestop_sound.play()
			world_environment.environment.volumetric_fog_enabled = true
		else:
			_TimeSpeedUp()
			
	#progressbar bruk opp eg refyll fart
	if progressbar_down == true:
		texture_progress_bar.value -= 2
	
	if progressbar_up == true:
		texture_progress_bar.value += 1
		
	if texture_progress_bar.value == 0:
		_TimeSpeedUp()
		
	##grapple
	#if grapple_ray.is_colliding():
		#grapple_point.global_position = ray_cast_3d.get_collision_point()
		#grapple_point.visible = true
	#else:
		#grapple_point.visible = false
		
		
	
	
	#KODE FOR Å PLUKKE OPP TING
	
	#if Input.is_action_just_pressed("Hold"):
		#if ray_cast_3d.get_collider():
			#held_object = ray_cast_3d.get_collider()
			#if held_object == RigidBody3D:
				#held_object.mode = RigidBody3D.FREEZE_MODE_KINEMATIC
				#held_object.collision_mask = 0
	#
	#if held_object:
		#held_object.global_transform.origin = held_object.global_transform.origin

	
	#ikke fungerende ENDA kanskje...
	#if texture_progress_bar.value == 100:
		#texture_progress_bar.modulate.a = 0
		#texture_progress_bar.modulate.a = lerp(texture_progress_bar.modulate.a, 0, 0.5)
		#
		
func _unhandled_input(event: InputEvent) -> void: 
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity

func _on_can_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_reloading_timer_timeout() -> void:
	is_reloading = false
	index = 0
	bullet_count_gun.text = texts[index]
	index = (index + 1) % texts.size()


func _on_muzzle_timer_timeout() -> void:
	omni_light_3d.visible = false
	muzzle_flash.emitting = false
	

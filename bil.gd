extends VehicleBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


var is_in_car = false

var max_rpm = 500
var max_torque = 200

@onready var seat_pos: Node3D = $Seat/SeatPos
@onready var exit_pos: Node3D = $Seat/ExitPos

@onready var player: CharacterBody3D = $"../Player"




@onready var camera_3d: Camera3D = $TwistPivot/PitchPivot/Camera3D
@onready var bil: VehicleBody3D = $"."
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@onready var kilometer_label: Label = $UI/Control/kilometer_label

@onready var startup: AudioStreamPlayer3D = $Startup
@onready var drive: AudioStreamPlayer3D = $Drive

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#sette seg i bilen
	if Input.is_action_just_pressed("E_interact") and can_enter_car == true:
		player.global_position = seat_pos.global_position
		startup.play()
		is_in_car = true
	
	#komme seg ut av bilen
	if Input.is_action_just_pressed("ui_accept") and is_in_car == true:
		is_in_car = false
		can_enter_car = false
		player.global_position = exit_pos.global_position
		
		#finne km/t ved rpm og radius av hjul
	var KM_speed = $Back_left.get_rpm() * 0.5 * (60/1000)
	
	#når du er i bilen
	if is_in_car == true:
		
		#kilometer_label.text = str(KM_speed) + "KM"
		
		#holder deg i bilen og lar deg styre
		steering = lerp(steering, Input.get_axis("ui_right", "ui_left") * 0.4, 5 * delta)
		var acceleration = Input.get_axis("ui_down", "ui_up") * 2
		player.position = seat_pos.global_position
		#player.global_rotation = seat_pos.global_rotation
		var rpm = $Back_left.get_rpm()
		$Back_left.engine_force = acceleration * max_torque  * (1 - rpm / max_rpm)
		
		rpm = $Back_right.get_rpm()
		$Back_right.engine_force = acceleration * max_torque  * (1 - rpm / max_rpm)
		
		
var can_enter_car = false

#kan du sette deg i bilen
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		can_enter_car = true

#startup sound
func _on_startup_finished() -> void:
	if is_in_car == true:
		drive.play()

#driving sound
func _on_drive_finished() -> void:
	if is_in_car == true:
		drive.play()

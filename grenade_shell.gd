extends RigidBody3D

@onready var grenade_shell: RigidBody3D = self

@onready var fire_trail: GPUParticles3D = $"Fire Trail"
@onready var omni_light_3d: OmniLight3D = $OmniLight3D

@onready var grenade_timer: Timer = $GrenadeTimer


var speed = 35

@onready var star: GPUParticles3D = $eksplosjon/Star
@onready var sparks: GPUParticles3D = $eksplosjon/Sparks
@onready var flash: GPUParticles3D = $eksplosjon/Flash
@onready var fire: GPUParticles3D = $eksplosjon/Fire
@onready var smoke: GPUParticles3D = $eksplosjon/Smoke

@onready var grenade_body: MeshInstance3D = $MeshInstance3D
@onready var grenade_body_tail: MeshInstance3D = $MeshInstance3D2
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@onready var explode_sound: AudioStreamPlayer3D = $"Explode sound"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_central_impulse(transform.basis.z * -speed)
	star.emitting = false

#func _process(delta: float) -> void:
	#if collision_shape_3d.is_colliding():
		#star.emitting = true

	
	#
#func _integrate_forces(state):
	#for i in range(state.get_contact_count()):
		#var collider = state.get_contact_collider_object(i)
		#if collider and collider != self:
			#star.emitting = trued
			#queue_free()
			
var bounces = 0

func _integrate_forces(state):
		for i in range(state.get_contact_count()):
			var collider = state.get_contact_collider_object(i)
			bounces += 1
			if bounces == 3 or collider.is_in_group("Explodable"):
				collision_shape_3d.disabled = true
				linear_velocity = Vector3.ZERO
				angular_velocity = Vector3.ZERO
				gravity_scale = 0.0
				# Explosion effect
				sparks.emitting = true
				flash.emitting = true
				fire.emitting = true
				smoke.emitting = true
				grenade_body.visible = false
				grenade_body_tail.visible = false
				fire_trail.visible = false
				grenade_timer.start()
				apply_explosion_force(global_position, 10.0, 5.0)
				explode_sound.play()
				#grenade_shell.visible = false
				#queue_free()  # Optional: Destroy the grenade or perform the explosion

func apply_explosion_force(position: Vector3, force_radius: float, explosion_force: float):
	var nearby_bodies = get_tree().get_nodes_in_group("Explodable")
	
	for body in nearby_bodies:
		if body is RigidBody3D:
			var distance = position.distance_to(body.global_position)
		
			if distance < force_radius:
				var force_direction = (body.global_position - position).normalized()
				var force_magnitude = explosion_force * (2 - (distance / force_radius))
				
				body.apply_central_impulse(force_direction * force_magnitude)

func _on_grenade_timer_timeout() -> void:
	queue_free()
	

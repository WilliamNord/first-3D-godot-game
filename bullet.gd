extends RigidBody3D

@onready var bullet: RigidBody3D = $"."

var speed = 35.0

func _ready() -> void:
	apply_central_impulse(transform.basis.z * -speed)
	bullet.gravity_scale = 0.3
	
#func _process(delta: float) -> void:
	#position += transform.basis * Vector3(0,0,-speed) * delta
 


func _on_child_entered_tree(node: Node) -> void:
	pass



# kan hende ikke funker
func _on_collision_shape_3d_child_entered_tree(node: Node) -> void:
	bullet.gravity_scale = 1.0

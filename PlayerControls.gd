extends Node

var was_clicked = false
var from = null
var to = null
var camera = null

func _ready():
	camera = get_parent().get_node("Camera")

const ray_length = 1000

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		from = camera.project_ray_origin(event.position)
		to = from + camera.project_ray_normal(event.position) * ray_length
		was_clicked = true

func _physics_process(delta):
	if was_clicked:
		var space_state = PhysicsServer.space_get_direct_state(camera.get_world().get_space())
		var result = space_state.intersect_ray(from, to,[self], 1)
		was_clicked = false
		if "collider" in result and result["collider"].get_parent() is Part:
			var creature = result["collider"].get_parent().get_creature()
			print(creature.genetics.genome_to_string(creature.genome))
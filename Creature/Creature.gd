extends Spatial

var Genetics = preload("res://Genetics//Genetics.gd")
var Part = preload("Part.tscn")

var nutrition = 10
var plenty_threshold = 30
var part = null
var genome = PoolByteArray ([1])
var genetics = null
var metabolism = 0.1
var metabolism_multiplier = 0.1
var color_update_frames = 100
var color_update_counter = 0

func _ready():
	pass
	
func init(_genome = null):
	if _genome:
		genome = _genome
	part = Part.instance()
	part.init(true, Part)
	add_child(part)
	genetics = Genetics.new()
	genetics.init(genome)
	var material = SpatialMaterial.new()
	var mesh = part.get_node("PartRigidBody").get_node("CollisionShape").get_node("MeshInstance")
	mesh.set_surface_material(0, material)
	metabolism += part.develop(genetics)
	process_color()

func init_blueprint(blueprint):
	genetics = Genetics.new()
	genome = genetics.create_genome(blueprint)
	init()
	
func add_food(add_nutrition):
	nutrition += add_nutrition
	#print("Nutrition increased to " + str(nutrition))
	if nutrition >= plenty_threshold:
		procreate()

func _process(delta):
	nutrition -= delta*metabolism*metabolism_multiplier
	color_update_counter += 1
	if color_update_counter >= color_update_frames:
		process_color()
		color_update_counter = 0
	if nutrition <= 0:
		die()
		
func process_color():
	var color_mod = clamp(nutrition/20.0, 0, 1)
	part.set_color(Color(1 - color_mod, color_mod, 0))
	
func procreate():
	print("procreating")
	nutrition = nutrition/2
	var new_genome = genetics.mutate()
	get_parent().creature_from_genome(new_genome, part.rigid_body.get_global_transform().origin)
	process_color()
	
func part_at_point(point):
	var result = part.contains_point(point)
	return result
	
func die():
	self.queue_free()

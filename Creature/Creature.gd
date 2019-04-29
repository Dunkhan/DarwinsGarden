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

func _ready():
	pass
	
func init():
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
	process_color()
	if nutrition <= 0:
		get_parent().remove_child(self)
		
func process_color():
	var color_mod = clamp(nutrition/20, 0, 1)
	part.set_color(Color(1 - color_mod, color_mod, 0))
	
func procreate():
	print("procreating")
	nutrition = nutrition/2
	var new_genome = genetics.mutate()
	get_parent().creature_from_genome(new_genome, get_transform().origin)
	process_color()

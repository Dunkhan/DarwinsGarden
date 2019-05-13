extends Node

onready var Creature = preload("res://Creature/Creature.tscn")
onready var Food = preload("Food.tscn")

var food_frequency = 7
var food_counter = 0
var food_queue : Array = Array()
var scarcity_counter = 0

func _ready():
	var _error = self.connect("tree_exiting", self, "on_quit")
	randomize()
	#food_timer = Timer.new()
	#food_timer.connect("timeout", self, "on_food_timer")
	#add_child(food_timer)
	#food_timer.start(-1.0/food_frequency)
	var bp = Base_Proteins.Base_Proteins
	Proteins.init(bp)
	print("creature 1")
	creature_from_blueprint(
		[
			[bp.organ_mouth],
			[bp.new_part, [255, 128, 128]],
			[bp.organ_mouth],
			[bp.to_parent],
			[bp.new_part, [128, 128, 255]],
			[bp.organ_mouth],
			[bp.to_parent],
			[bp.new_part, [0, 128, 128]],
			[bp.organ_mouth],
			[bp.to_parent],
			[bp.new_part, [128, 128, 0]],
			[bp.organ_mouth],
		])
	print("creature 2")
	creature_from_blueprint(
		[
			[bp.organ_mouth],
			[bp.new_part, [255, 128, 128]],
			[bp.articulation, [100, 200, 300, 400, 500, 600, 700, 800, 900, 2]],
			[bp.grow, [250]],
			[bp.to_parent],
			[bp.new_part, [0, 128, 128]],
			[bp.organ_mouth],
		])
	print("creature 3")
	creature_from_blueprint(
		[
			[bp.organ_mouth],
			[bp.new_part, [255, 128, 128]],
			[bp.articulation, [100, 200, 300, 400, 500, 600, 700, 800, 900, 2]],
		])
#	creature_from_string("3,1,255,128,128,3,5,1,128,128,3,5,1,128,128,5,1,0,128,128,3,0,3,128,255,3,5,3")

func on_quit():
	print("quitting")

func creature_from_blueprint(blueprint):
	var c = Creature.instance()
	var t  = c.get_transform()
	t.origin += Vector3(randf()*20-10, 2, randf()*20-10)
	c.set_transform(t)
	add_child(c)
	c.init_blueprint(blueprint)
	
func creature_from_string(genome_string):
	var t = Vector3(0,0,0)
	creature_from_genome(Genetics.genome_from_string(genome_string), t)
	
func creature_from_genome(genome, position : Vector3):
	var c = Creature.instance()
	var t  = c.get_transform()
	t.origin = Vector3(position.x + randf()*2-1, position.y + 5, position.z + randf()*2-1)
	c.set_transform(t)
	add_child(c)
	c.genome = genome
	c.init()

func _process(delta):
	food_counter += delta
	if(food_counter <= 1.0/food_frequency):
		return
	food_counter = 0
	create_food(Vector3(randf()*200-100, 10, randf()*200-100))
	if randf()*10000 > scarcity_counter:
		create_food(Vector3(randf()*50-25, 10, randf()*50-25))
		scarcity_counter += 1
	
func create_food(position):
	var f
	if food_queue.empty():
		f = Food.instance()
	else:
		f = food_queue.pop_front()
	add_child(f)
	var t = f.get_transform()
	t.origin = position
	f.set_transform(t)
		
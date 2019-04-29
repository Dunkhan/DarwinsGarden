extends Spatial

var Organ = preload("Organ.gd")

var organs = []
var child_parts = []
var limb : Generic6DOFJoint = null
var is_core = false
var size = 1
var Part
var metabolism = 0.1
var move_timer : Timer = null
var articulate_cost = 0
var rigid_body

func init(_is_core, part_subtree):
	is_core = _is_core
	Part = part_subtree
	
func _ready():
	rigid_body = get_node("PartRigidBody")

func develop(genome):
	#print("starting part")
	var bp = Base_Proteins.Base_Proteins
	var next_protein = genome.next_protein()
	while next_protein != Base_Proteins.Base_Proteins.end:
		#print("processing protein: " + str(next_protein))
		match next_protein:
			bp.new_part:
				metabolism += add_part(genome)
				break
			bp.grow:
				grow(genome)
			bp.organ_mouth:
				metabolism += add_mouth(genome)
			bp.articulation:
				if(!is_core):
					articulate_cost = articulate(genome)
			bp.to_parent:
				#print("returning to parent")
				if not is_core:
					get_parent().develop(genome)
					break
			
		next_protein = genome.next_protein()
	return (metabolism + articulate_cost) * size * size
	
func add_part(genome):
	#print("Growing new part")
	var token = genome.next_token()
	var direction
	if len(token) == 0:
		direction = int_to_vector(randi())
	else:
		direction = int_to_vector(token[0])
	var new_part = Part.instance()
	new_part.limb=Generic6DOFJoint.new()
	var t  = self.get_transform()
	t.origin += direction
	new_part.set_transform(t)
	add_child(new_part)
	new_part.add_child(new_part.limb)
	new_part.limb.set_node_a(self.rigid_body.get_path())
	new_part.limb.set_node_b(new_part.rigid_body.get_path())
	set_child_limb_defaults(new_part.limb, direction)
	var mesh = rigid_body.get_node("CollisionShape").get_node("MeshInstance")
	var child_mesh = new_part.rigid_body.get_node("CollisionShape").get_node("MeshInstance")
	child_mesh.set_surface_material(0, mesh.get_surface_material(0))
#	new_part.set_limb_limits(false)
	new_part.init(false, Part)
	child_parts.append(new_part)
	
	return new_part.develop(genome)

func grow(genome):
	#print("growing")
	#todo make this work with a different size for each dimension
	var token = genome.next_token()
	if len(token) == 0:
		return
	var value = token[0]
	value = value*(1.0/255.0) + 0.5
	size = value
	#print(value)
	var new_transform = get_node("PartRigidBody").transform.scaled(Vector3(value, value, value))
	if not is_core:
		new_transform = new_transform.translated((new_transform.origin + get_parent().get_node("PartRigidBody").transform.origin)*value)
	for child in child_parts:
		var child_transform = child.get_node("PartRigidBody").transform.translated((child.get_node("PartRigidBody").transform.origin + get_node("PartRigidBody").transform.origin)*value)
	set_transform(new_transform)
#	set_limb_limits(true)

func add_mouth(genome):
	#print("Adding mouth")
	var organ = Organ.new()
	organ.type = Organ.Organ_Types.mouth
	organs.append(organ)
	rigid_body.contact_monitor = true
	rigid_body.contacts_reported = 4
	rigid_body.collision_layer = rigid_body.collision_layer | (4 << 1)
	rigid_body.collision_mask = rigid_body.collision_mask | (4 << 1)
	rigid_body.connect("body_entered", self, "on_food_collision")
	return 0.05

func articulate(genome):
	#print("articulating joint")
	var cost = 0
	limb.set("angular_motor_x/enabled", true)
	limb.set("angular_motor_y/enabled", true)
	limb.set("angular_motor_z/enabled", true)
	for property in (
			[["angular_limit_x/upper_angle", 70, 1],
			["angular_limit_y/upper_angle", 70, 1],
			["angular_limit_z/upper_angle", 70, 1],
			["angular_limit_x/lower_angle", -70, 1],
			["angular_limit_y/lower_angle", -70, 1],
			["angular_limit_z/lower_angle", -70, 1],
			["angular_motor_x/target_velocity", 1, 100],
			["angular_motor_y/target_velocity", 1, 100],
			["angular_motor_z/target_velocity", 1, 100],]):
		var next_token = genome.next_token()
		if(len(next_token) == 0):
			break
		var value = next_token[0]*(property[1]/255.0)
		limb.set(property[0], value)
		cost += (abs(value*property[2])/900)
		print("move cost " + str(cost) + " - " + str(value))
		
	if move_timer == null:
		move_timer = Timer.new()
		move_timer.connect("timeout", self, "on_move_timer")
		add_child(move_timer)
		move_timer.start()
	var frequency = 10
	var next_token = genome.next_token()
	if(len(next_token) != 0):
		frequency = next_token[0]%9+1
	move_timer.set_wait_time(frequency)
	return cost * frequency/10

func on_move_timer():
	for property in (
			["angular_motor_x/target_velocity",
			"angular_motor_y/target_velocity",
			"angular_motor_z/target_velocity"]):
		var value = limb.get(property)
		limb.set(property, -value)

func on_food_collision(body):
	if (body is Food):
		body.get_parent().remove_child(body)
		get_creature().add_food(body.food_value)
	
func get_creature():
	if is_core:
		return get_parent()
	else:
		return get_parent().get_creature()
		
func set_child_limb_defaults(limb, direction):
	limb.set("angular_limit_x/upper_angle", 10)
	limb.set("angular_limit_y/upper_angle", 10)
	limb.set("angular_limit_z/upper_angle", 10)
	limb.set("angular_limit_x/lower_angle", -10)
	limb.set("angular_limit_y/lower_angle", -10)
	limb.set("angular_limit_z/lower_angle", -10)
	limb.set("angular_limit_x/softness", 0.1)
	limb.set("angular_limit_y/softness", 0.1)
	limb.set("angular_limit_z/softness", 0.1)
	limb.transform = limb.transform.translated(direction)
	
#func set_limb_limits(recurse):
#	if(limb != null):
#		var distance = size + get_parent().size
#		limb.set("linear_limit_x/upper_distance", distance*0)
#		limb.set("linear_limit_y/upper_distance", distance*0)
#		limb.set("linear_limit_z/upper_distance", distance*0)
#		limb.set("linear_limit_x/lower_distance", distance*0)
#		limb.set("linear_limit_y/lower_distance", distance*0)
#		limb.set("linear_limit_z/lower_distance", distance*0)
#		limb.set("linear_spring_x/stiffness", 0.1)
#		limb.set("linear_spring_y/stiffness", 0.1)
#		limb.set("linear_spring_z/stiffness", 0.1)
#		limb.set("linear_spring_x/damping", 0.1)
#		limb.set("linear_spring_y/damping", 0.1)
#		limb.set("linear_spring_z/damping", 0.1)
#
#	if recurse:
#		for child in child_parts:
#			child.set_limb_limits(false)
	
func int_to_vector(value):
	var distance = size+1
	var x = distance if value%6 == 0 else (-distance if value%6 == 1 else 0)
	var y = distance if value%6 == 2 else (-distance if value%6 == 3 else 0)
	var z = distance if value%6 == 4 else (-distance if value%6 == 5 else 0)
	return Vector3(x,y,z)
	
func set_color(color):
	var mesh = rigid_body.get_node("CollisionShape").get_node("MeshInstance")
	mesh.get_surface_material(0).albedo_color = color
	for child in child_parts:
		child.set_color(color)
		
func _notification(what):
    if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
        get_tree().quit() # default behavior

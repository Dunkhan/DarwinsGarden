extends Spatial
class_name Part

var Organ = preload("Organ.gd")

var organs = []
var child_parts = []
var limb : Generic6DOFJoint = null
var is_core = false
var size = 1
var Part
var metabolism = 0.2
var move_timer : Timer = null
var articulate_cost = 0
var rigid_body
var has_mouth
var relative_position : Vector3

func init(_is_core, part_subtree):
	is_core = _is_core
	Part = part_subtree
	
func _ready():
	rigid_body = get_node("PartRigidBody")

func develop(genome):
	#print("starting part")
	if(relative_position == Vector3(0,0,0) && not is_core):
		relative_position = transform.origin + get_parent().transform.origin
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
					#warning-ignore:unsafe_method_access
					get_parent().develop(genome)
					break
			
		next_protein = genome.next_protein()
	return (metabolism + articulate_cost) * size * size
	
func add_part(genome):
	#print("Growing new part")
	var direction = get_vector(genome)
	var new_part = part_in_direction(transform.origin + (direction * size))
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
	#warning-ignore:unsafe_property_access
	var new_transform = get_node("PartRigidBody").get_node("CollisionShape").transform.scaled(Vector3(value, value, value))
	get_node("PartRigidBody").get_node("CollisionShape").set_transform(new_transform)
	refresh_position()	

func add_mouth(_genome):
	#print("Adding mouth")
	if has_mouth:
		return 0
	has_mouth = true
	var organ = Organ.new()
	organ.type = Organ.Organ_Types.mouth
	organs.append(organ)
	rigid_body.contact_monitor = true
	rigid_body.contacts_reported = 4
	rigid_body.connect("body_entered", self, "on_food_collision")
	return 0.1

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
		var _error = move_timer.connect("timeout", self, "on_move_timer")
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
	if body is Food && not body.is_eaten:
		body.is_eaten = true
		call_deferred("process_food_collision", body)
		
func process_food_collision(body):
	body.get_parent().food_queue.push_front(body)
	body.get_parent().remove_child(body)
	get_creature().add_food(body.food_value)
	body.is_eaten = false
		
func get_creature():
	if is_core:
		return get_parent()
	else:
#warning-ignore:unsafe_method_access
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
	
func get_vector(genome):
	var token = genome.next_token()
	if(len(token) == 0):
		return Vector3(1,0,0)
	var x = token[0]*(2/255.0)-1.0
	token = genome.next_token()
	if(len(token) == 0):
		return Vector3(x,0,0)
	var y = token[0]*(2/255.0)-1.0
	token = genome.next_token()
	if(len(token) == 0):
		return Vector3(x,y,0)
	var z = token[0]*(2/255.0)-1.0
	return Vector3(x,y,z).normalized() * (1+size)
	
func set_color(color):
	var mesh = rigid_body.get_node("CollisionShape").get_node("MeshInstance")
	mesh.get_surface_material(0).albedo_color = color
	for child in child_parts:
		child.set_color(color)
		
func contains_point(vector):
	if transform.origin.distance_to(vector) < size:
		return self
	for child in child_parts:
		var result = child.contains_point(vector)
		if result != null:
			return result
	return null

func part_in_direction(direction):
	var new_part = get_creature().part_at_point(transform.origin + direction)
	if new_part == null:
		new_part = get_creature().Part.instance()
		var t = self.get_transform()
		t.origin = direction
		new_part.set_transform(t)
		new_part.limb=Generic6DOFJoint.new()
		add_child(new_part)
		new_part.add_child(new_part.limb)
		new_part.limb.set_node_a(rigid_body.get_path())
		new_part.limb.set_node_b(new_part.rigid_body.get_path())
		set_child_limb_defaults(new_part.limb, direction)
		var mesh = rigid_body.get_node("CollisionShape").get_node("MeshInstance")
		var child_mesh = new_part.rigid_body.get_node("CollisionShape").get_node("MeshInstance")
		child_mesh.set_surface_material(0, mesh.get_surface_material(0))
	#	new_part.set_limb_limits(false)
		new_part.init(false, Part)
		child_parts.append(new_part)
	return new_part
	
func refresh_position():
	#warning-ignore:unsafe_property_access
	if(not is_core):
		var new_distance = (size+get_parent().size)/2
		var new_transform = transform
		new_transform.origin = get_parent().transform.origin
		new_transform = new_transform.translated(relative_position * new_distance)
		set_transform(new_transform)
		var new_limb = limb.duplicate()
		limb.queue_free()
		limb = new_limb
		#warning-ignore:unsafe_property_access
		var parent = get_parent()
		limb.set_node_a(get_parent().rigid_body.get_path())
		limb.set_node_b(rigid_body.get_path())
		add_child(limb)
	for child in child_parts:
		child.refresh_position()

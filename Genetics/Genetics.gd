extends Node
class_name Genetics

var genome = null
var pointer = 0
var mutation_rate = 0.5

func _ready():
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func init(bytes):
	genome = bytes

func next_token():
	if(pointer/8 >= len(genome)):
		#print("end")
		return PoolByteArray([])
	var result = PoolByteArray ([genome[pointer/8]])
	pointer += 8
	return result

func next_protein():
	var result = Proteins.get_protein(next_token())
	#if result == Base_Proteins.Base_Proteins.end:
		#print("ending")
	return result
	
func create_genome(args):
	var result = PoolByteArray([])
	for i in range(len(args)):
		result.append(Proteins.get_first_index(args[i][0])[0])
		if(len(args[i]) > 1):
			for byte in args[i][1]:
				result.append(byte)
	#print(genome_to_string(result))
	return result
	
static func genome_from_string(genome_string):
	var tokens = genome_string.split(",", true)
	var result = PoolByteArray([])
	for i in tokens:
		result.append(int(i))
	return result
	
static func genome_to_string(bytes):
	var result = ""
	for byte in bytes:
		result = result + str(byte) + ","
	return result
	
func mutate():
	var result = genome
	while randf()<=mutation_rate:
		var type = randf()
		if(type <= 0.4):
			result = bit_flip_mutation(result)
		elif(type <= 0.55):
			result = sequence_move_mutation(result)
		elif(type <= 0.7):
			result = piece_switch_mutation(result)
		elif(type <= 0.85):
			result = sequence_delete_mutation(result)
		else:
			result = sequence_duplicate_mutation(result)
		
	return result

func bit_flip_mutation(_genome):
	print("bit flip mutation")
	var i = randi()%len(_genome)
	var random_bit = 1
	while randf() >= 0.5:
		random_bit = 1 << random_bit
	_genome[i] = _genome[i] ^ random_bit
	return _genome
			
func piece_switch_mutation(_genome):
	print("piece switch mutation")
	if not len(_genome) > 1:
		return _genome
	var i = randi()%len(_genome)
	var preceeding = randf() >= 0.5
	if(i == 0 && len(_genome) > 1):
		preceeding = false
	if(i == len(_genome)-1):
		preceeding = false
	if(preceeding):
		var save = _genome[i]
		_genome[i] = _genome[i+1]
		_genome[i+1] = save
	else:
		var save = _genome[i]
		_genome[i] = _genome[i-1]
		_genome[i-1] = save
	return _genome
			
func sequence_move_mutation(_genome):
	print("sequence move mutation")
	if not len(_genome) > 1:
		return
	var start = randi()%(len(_genome)-1)
	if(start == len(_genome)-1):
		return
	var length = min(randi()%10, len(_genome)-1-start)
	if(length > 0 && length < len(_genome)-1):
		var insert = randi() % (len(_genome) -1 - length)
		var sequence = _genome.subarray(start, start+length)
		var before = _genome.subarray(0, start)
		var after = _genome.subarray(start+length, len(_genome)-1)
		_genome = before
		_genome.append_array(after)
		before = _genome.subarray(0, insert-1) if insert > 0 else PoolByteArray([])
		after = _genome.subarray(insert, len(_genome)-1) if insert < len(_genome)-1 else PoolByteArray([])
		_genome = before
		_genome.append_array(sequence)
		_genome.append_array(after)
	return _genome
	
func sequence_duplicate_mutation(_genome):
	print("sequence duplicate mutation")
	if not len(_genome) > 1:
		return
	var start = randi()%(len(_genome)-1)
	var length = min(randi()%10, len(_genome)-1-start)
	if(length > 0 && length < len(_genome)):
		var sequence = _genome.subarray(start, start+length)
		var before = _genome.subarray(0, start)
		var after = _genome.subarray(start+length, len(_genome)-1)
		_genome = before
		_genome.append_array(after)
		_genome.append_array(sequence)
	return _genome
	
func sequence_delete_mutation(_genome):
	print("sequence duplicate mutation")
	if not len(_genome) > 1:
		return
	var start = randi()%(len(_genome)-1)
	var length = min(randi()%10, len(_genome)-1-start)
	if(length > 0 && length < len(_genome)):
		var before = _genome.subarray(0, start)
		var after = _genome.subarray(start+length, len(_genome)-1)
		_genome = before
		_genome.append_array(after)
	return _genome










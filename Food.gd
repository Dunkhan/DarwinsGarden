extends Node
class_name Food

var decay_time = 60
var food_value = 5
var decay = 0
var is_eaten = false

func _ready():
	pass
	
func _process(delta):
	decay += delta
	if decay >= decay_time:
		get_parent().remove_child(self)

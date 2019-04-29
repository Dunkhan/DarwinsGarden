extends Node

var all_proteins = {}
var protein_length = 8

func init(base_proteins):
	#protein_length = floor( log2(len(base_proteins)) + 1 )
	for i in range(pow(2, protein_length)):
		all_proteins[PoolByteArray ([i])] = i%(len(base_proteins))
	#print(base_proteins)
		
func get_protein(byte_index):
	if(len(byte_index) == 0):
		return Base_Proteins.Base_Proteins.end
	#print(str(byte_index[0]))
	return all_proteins[byte_index]
	
func get_first_index(protein):
	for index in all_proteins:
		if all_proteins[index] == protein:
			return index

func create(byte_index, args=[]):
	var result = []
	result.append(get_protein(byte_index))
	result = result + args
	return result
	
func all_proteins_string():
	var result = ""
	for protein in all_proteins:
		result = result + " " + str(protein[0]) + "," + str(all_proteins[protein])
	return result
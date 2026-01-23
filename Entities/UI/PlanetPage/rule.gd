extends HBoxContainer






func applies() -> bool:
	if $SubjectButton.selected == -1:
		return false
	if $ConditionButton.selected == -1:
		return false
	if $ResourceButton.selected == -1:
		return false
	
	if $Amount.value == 0:
		return false
	
	return true


func get_subject():
	if $SubjectButton.selected == 0:
		return "sender"
	elif $SubjectButton.selected == 1:
		return "receiver"

func get_resource():
	match $ResourceButton.selected:
		0:
			return "population"
		1:
			return "food"
		2:
			return "technology"
		3:
			return "iron"
		4:
			return "uranium"

func get_condition():
	match $ConditionButton.selected:
		0:
			return "<"
		1:
			return "="
		2:
			return ">"

func get_amount():
	return $Amount.value

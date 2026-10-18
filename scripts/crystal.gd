extends Area2D

var was_collected: bool = false

func _on_body_entered(body: Node2D) -> void:
	if was_collected:
		return

	if not body.is_in_group("player"):
		return
	if QuestManager.collect_crystal():
		was_collected = true
		queue_free()

extends Area2D
@export var crystal_id: String = ""
var was_collected: bool = false

func _ready() -> void:
	# Si el cristal no tiene ID, se genera uno único y estable
	# a partir del nivel y de la posición del nodo en la escena.
	if crystal_id.is_empty():
		crystal_id = _generate_id()

	# Necesario para que SaveManager pueda encontrarlo al cargar.
	add_to_group("crystals")

	body_entered.connect(_on_body_entered)

func _generate_id() -> String:
	if owner != null:
		var level_name: String = owner.scene_file_path.get_file().get_basename()
		return "%s/%s" % [level_name, str(owner.get_path_to(self))]
	return str(name)

func _on_body_entered(body: Node2D) -> void:
	if was_collected:
		return

	if not body.is_in_group("player"):
		return
	if QuestManager.collect_crystal(crystal_id):
		was_collected = true
		queue_free()

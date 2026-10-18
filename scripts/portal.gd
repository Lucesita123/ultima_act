extends Area2D

var activated: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	QuestManager.quest_completed.connect(activate_portal)


func activate_portal() -> void:
	activated = true

	if sprite.sprite_frames.has_animation("active"):
		sprite.play("active")

	print("Portal activado")


func _on_body_entered(body: Node2D) -> void:
	if not activated:
		return

	if body.is_in_group("player"):
		print("¡Nivel completado!")


extends Area2D

@export_file("*.tscn") var next_level: String

var activated: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    QuestManager.quest_completed.connect(activate_portal)

    if QuestManager.quest_state == QuestManager.QuestState.COMPLETED:
        activate_portal()


func activate_portal() -> void:
    activated = true

    if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("active"):
        sprite.play("active")


func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return

    if not activated:
        print("Primero debes completar la misión")
        return

    if next_level.is_empty():
        push_warning("No se configuró el siguiente nivel")
        return

    set_deferred("monitoring", false)
    get_tree().change_scene_to_file.call_deferred(next_level)

extends CanvasLayer

## Vida que representa cada corazón del HUD.
@export var health_per_heart: int = 20
@export var heart_full_texture: Texture2D
@export var heart_empty_texture: Texture2D
@export var heart_size: Vector2 = Vector2(30, 26)

@onready var hearts_container: HBoxContainer = $HUDContainer/HealthPanel/VBoxContainer/HeartsContainer
@onready var health_label: Label = $HUDContainer/HealthPanel/VBoxContainer/HealthLabel
@onready var crystal_label: Label = $HUDContainer/CrystalsPanel/HBoxContainer/CrystalLabel
@onready var quest_label: Label = $HUDContainer/QuestPanel/QuestLabel

func _ready() -> void:
	QuestManager.quest_updated.connect(update_quest_info)
	update_quest_info()

func update_health(current: int, maximum: int) -> void:
	var total_hearts: int = ceili(float(maximum) / float(health_per_heart))
	var full_hearts: int = ceili(float(current) / float(health_per_heart))

	build_hearts(total_hearts)

	for i in hearts_container.get_child_count():
		var heart: TextureRect = hearts_container.get_child(i)
		if i < full_hearts:
			heart.texture = heart_full_texture
		else:
			heart.texture = heart_empty_texture

	health_label.text = "VIDA: %d/%d" % [current, maximum]

# Crea o elimina corazones hasta tener la cantidad indicada.
func build_hearts(total_hearts: int) -> void:
	while hearts_container.get_child_count() < total_hearts:
		var heart := TextureRect.new()
		heart.custom_minimum_size = heart_size
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts_container.add_child(heart)

	while hearts_container.get_child_count() > total_hearts:
		var extra: Node = hearts_container.get_child(hearts_container.get_child_count() - 1)
		hearts_container.remove_child(extra)
		extra.queue_free()

func update_quest_info() -> void:
	crystal_label.text = "CRISTALES: %d/%d" % [
		QuestManager.collected_crystals,
		QuestManager.required_crystals
	]
	match QuestManager.quest_state:
		QuestManager.QuestState.NOT_STARTED:
			quest_label.text = "MISION: Habla con Han Solo"
		QuestManager.QuestState.ACTIVE:
			quest_label.text = "MISION: Recolectar los cristales"
		QuestManager.QuestState.READY_TO_DELIVER:
			quest_label.text = "MISION: Entrega los cristales a Han Solo"
		QuestManager.QuestState.COMPLETED:
			quest_label.text = "MISION COMPLETADA"

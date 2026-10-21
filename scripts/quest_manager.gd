extends Node

signal quest_updated
signal quest_completed

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	READY_TO_DELIVER,
	COMPLETED
}

var quest_state: QuestState = QuestState.NOT_STARTED
var required_crystals: int = 3
var collected_crystals: int = 0
var collected_crystal_ids: Array[String] = []
var defeated_enemy_ids: Array[String] = []

func start_quest() -> void:
	if quest_state != QuestState.NOT_STARTED:
		return
	collected_crystals = 0
	quest_state = QuestState.ACTIVE
	quest_updated.emit()
	
func collect_crystal(crystal_id: String) -> bool:
	if quest_state != QuestState.ACTIVE:
		return false
	if crystal_id in collected_crystal_ids:
		return false
	collected_crystal_ids.append(crystal_id)
	collected_crystals += 1
	if collected_crystals >= required_crystals:
		quest_state = QuestState.READY_TO_DELIVER
	quest_updated.emit()
	return true

# Registrar que un enemigo fue eliminado (para que se guarde).
func register_defeated_enemy(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	if enemy_id in defeated_enemy_ids:
		return
	defeated_enemy_ids.append(enemy_id)

func complete_quest() -> void:
	if quest_state != QuestState.READY_TO_DELIVER:
		return
	quest_state = QuestState.COMPLETED
	quest_updated.emit()
	quest_completed.emit()

func reset_quest() -> void:
	quest_state = QuestState.NOT_STARTED
	collected_crystals = 0
	collected_crystal_ids.clear()
	defeated_enemy_ids.clear()
	quest_updated.emit()

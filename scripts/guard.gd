extends CharacterBody2D

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN,
	FLEE
}


@export var patrol_speed: float = 70.0
@export var chase_speed: float = 115.0
@export var arrival_distance: float = 12.0

@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0

@export var idle_duration: float = 1.0
@export var repath_distance: float = 8.0

#VARIABLES EXPORTADAS DEL NIVEL DE VIDA DEL GUARDIA
@export var max_health: int = 100
# ID único del guardia (se genera solo si se deja vacío).
@export var guard_id: String = ""
@export_range(0.1, 0.9, 0.05) var flee_threeshold: float = 0.3
@export var flee_speed: float = 145.0
@export var flee_distance: float = 180.0
@export var flee_safe_distance: float = 230.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@onready var patrol_a: Marker2D = $PositionPatrolA
@onready var patrol_b: Marker2D = $PositionPatrolB

@onready var healthbar: ProgressBar = $HealthBar

#VARIABLES LOCALES
var health: int
var is_dead: bool = false

var state: State = State.IDLE
var player: CharacterBody2D = null

var home_position: Vector2
var patrol_positions: Array[Vector2] = []
var patrol_index: int = 0

var idle_timer: float = 0.0
var attack_timer: float = 0.0

var facing_direction: String = "down"
var navigation_ready: bool = false

var is_retreating: bool = false

func _ready() -> void:
	# ID estable para el sistema de guardado.
	if guard_id.is_empty():
		guard_id = _generate_id()
	add_to_group("guards")

	home_position = global_position

	health = max_health
	healthbar.max_value = max_health
	healthbar.value = health

	# Guardamos las posiciones globales de patrullaje.
	# Así no se mueven junto con el guardia.
	patrol_positions = [
		patrol_a.global_position,
		patrol_b.global_position
	]

	# Configuración de navegación.
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = false

	detection_area.body_entered.connect(
		_on_detection_body_entered
	)

	detection_area.body_exited.connect(
		_on_detection_body_exited
	)

	# Estado inicial.
	state = State.IDLE
	idle_timer = idle_duration
	
	sprite.animation_finished.connect(
		_on_guard_animation_finished
	)

	# Esperar a que el mapa de navegación se sincronice.
	call_deferred("_initialize_navigation")


func _initialize_navigation() -> void:
	await get_tree().physics_frame

	if not is_inside_tree():
		return

	navigation_ready = true

	navigation_agent.target_position = home_position


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	
	if not navigation_ready:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)

	if state == State.CHASE or state == State.ATTACK or state == State.FLEE:
		evaluate_decision()

	match state:
		State.IDLE:
			process_idle(delta)

		State.PATROL:
			process_patrol()

		State.CHASE:
			process_chase()

		State.ATTACK:
			process_attack()

		State.RETURN:
			process_return()
		State.FLEE:
			process_flee()

	move_and_slide()
	update_animation()


func process_idle(delta: float) -> void:
	velocity = Vector2.ZERO

	idle_timer -= delta

	if idle_timer <= 0.0:
		change_state(State.PATROL)


func process_patrol() -> void:
	if patrol_positions.is_empty():
		velocity = Vector2.ZERO
		return

	var target: Vector2 = patrol_positions[patrol_index]

	navigate_to(target, patrol_speed)

	if global_position.distance_to(target) <= arrival_distance:
		velocity = Vector2.ZERO

		patrol_index = (
			patrol_index + 1
		) % patrol_positions.size()

		change_state(State.IDLE)


func process_chase() -> void:
	if not is_instance_valid(player):
		player = null
		change_state(State.RETURN)
		return

	if is_player_in_attack_range():
		velocity = Vector2.ZERO
		change_state(State.ATTACK)
		return

	navigate_to(
		player.global_position,
		chase_speed
	)


func process_attack() -> void:
	velocity = Vector2.ZERO

	if not is_instance_valid(player):
		player = null
		change_state(State.RETURN)
		return

	if not is_player_in_attack_range():
		change_state(State.CHASE)
		return

	# Orientarse hacia el jugador.
	var direction: Vector2 = (
		player.global_position - global_position
	)

	update_facing_direction(direction)

	if attack_timer <= 0.0:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
			sprite.play("attack")

		attack_timer = attack_cooldown

		print("Guardia atacó al jugador")


func process_return() -> void:
	navigate_to(
		home_position,
		patrol_speed
	)

	if global_position.distance_to(home_position) <= arrival_distance:
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		is_retreating = false

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = maxi(health - amount, 0)
	healthbar.value = health
	if health <= 0:
		die()
		return
	#evaluate_decision()
	
func _generate_id() -> String:
	if owner != null:
		var level_name: String = owner.scene_file_path.get_file().get_basename()
		return "%s/%s" % [level_name, str(owner.get_path_to(self))]
	return str(name)

func die() -> void:
	is_dead = true

	# Guardar que este enemigo fue eliminado.
	QuestManager.register_defeated_enemy(guard_id)
	velocity = Vector2.ZERO
	# Dejar de detectar y atacar
	detection_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitoring", false)

	# Desactivar colisiones físicas
	$CollisionShape2D.set_deferred("disabled", true)

	# Evitar que el jugador siga atacando al guardia muerto
	remove_from_group("enemies")

	# Reproducir muerte
	sprite.play("death")

func navigate_to(
	target: Vector2,
	movement_speed: float
) -> void:

	if not navigation_ready:
		velocity = Vector2.ZERO
		return

	# Solo actualizar destino si ha cambiado.
	if navigation_agent.target_position.distance_to(target) > repath_distance:
		navigation_agent.target_position = target

	# Comprobar si terminó el recorrido.
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	# Obtener el siguiente punto de la ruta.
	var next_position: Vector2 = (
		navigation_agent.get_next_path_position()
	)

	# Calcular dirección hacia ese punto.
	var direction: Vector2 = (
		global_position.direction_to(next_position)
	)

	velocity = direction * movement_speed


func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body is CharacterBody2D:
			player = body as CharacterBody2D
			if not is_retreating:
				change_state(State.CHASE)


func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		change_state(State.RETURN)


func is_player_in_attack_range() -> bool:
	if not is_instance_valid(player):
		return false

	return attack_area.overlaps_body(player)


func change_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		State.IDLE:
			idle_timer = idle_duration
			velocity = Vector2.ZERO

		State.PATROL:
			pass

		State.CHASE:
			pass

		State.ATTACK:
			velocity = Vector2.ZERO

		State.RETURN:
			pass

func is_player_alive() -> bool:
	if not is_instance_valid(player):
		return false

	if player.is_dead:
		return false

	return true

func process_flee() -> void:
	if not is_instance_valid(player):
		player = null
		change_state(State.RETURN)
		return

	is_retreating = true

	var distance_to_player: float = (
		global_position.distance_to(player.global_position)
	)

	if distance_to_player >= flee_safe_distance:
		change_state(State.RETURN)
		return

	var flee_direction: Vector2 = (
		global_position - player.global_position
	).normalized()

	if flee_direction == Vector2.ZERO:
		flee_direction = Vector2.RIGHT

	var desired_target: Vector2 = (
		global_position + flee_direction * flee_distance
	)

	var navigation_map: RID = navigation_agent.get_navigation_map()

	var safe_target: Vector2 = (
		NavigationServer2D.map_get_closest_point(
			navigation_map,
			desired_target
		)
	)

	navigate_to(safe_target, flee_speed)

func evaluate_decision() -> void:
	if is_retreating and state == State.RETURN:
		return
	if is_dead:
		return

	if not is_instance_valid(player):
		if state == State.CHASE or state == State.ATTACK or state == State.FLEE:
			change_state(State.RETURN)
		return

	var health_percentage: float = (
		float(health) / float(max_health)
	)

	if health_percentage <= flee_threeshold:
		if state != State.FLEE:
			change_state(State.FLEE)
		return

	if is_player_in_attack_range():
		change_state(State.ATTACK)
	else:
		change_state(State.CHASE)

func update_animation() -> void:
	if is_dead:
		return
	if velocity.length() > 5.0:
		update_facing_direction(velocity)

	var prefix: String = "idle"

	if velocity.length() > 5.0:
		prefix = "walk"

	var animation_name: String = (
		prefix + "_" + facing_direction
	)

	if sprite.sprite_frames == null:
		return

	if sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name or not sprite.is_playing():
			sprite.play(animation_name)


func update_facing_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.001:
		return

	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			facing_direction = "right"
		else:
			facing_direction = "left"
	else:
		if direction.y > 0.0:
			facing_direction = "down"
		else:
			facing_direction = "up"

func _on_guard_animation_finished() -> void:
	if sprite.animation == "death":
		queue_free()

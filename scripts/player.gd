
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

@export var speed: float = 220.0
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_cooldown: float = 0.5

var health: int
var is_dead: bool = false
var is_attacking: bool = false
var attack_timer: float = 0.0

@onready var attack_area: Area2D = $AttackArea
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")

	health = max_health
	health_changed.emit(health, max_health)

	animatedSprite.animation_finished.connect(
		_on_animation_finished
	)

	animatedSprite.play("idle")


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)

	if Input.is_action_just_pressed("player_attack"):
		attack()

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed
	move_and_slide()

	if not is_attacking:
		animatedSprite.play("idle")

func attack() -> void:
	if is_dead:
		return

	if is_attacking:
		return

	if attack_timer > 0.0:
		return

	is_attacking = true
	attack_timer = attack_cooldown

	animatedSprite.play("attack")

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage(attack_damage)

func _on_animation_finished() -> void:
	match animatedSprite.animation:
		"attack":
			is_attacking = false

			if not is_dead:
				animatedSprite.play("idle")
		"death":
			died.emit()

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health = maxi(health - amount, 0)

	health_changed.emit(health, max_health)

	if health == 0:
		is_dead = true
		is_attacking = false
		velocity = Vector2.ZERO
		animatedSprite.play("death")

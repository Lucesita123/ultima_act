extends CanvasLayer

@onready var joystick_base: Control = $Controls/JoystickBase
@onready var joystick_knob: Control = $Controls/JoystickBase/JoystickKnob
@onready var attack_button: TouchScreenButton = $Controls/AttackButton
@onready var interact_button: TouchScreenButton = $Controls/InteractButton

@export var joystick_radius: float = 65.0
@export var deadzone: float = 0.15
## Distancia de los botones al borde inferior derecho de la pantalla.
@export var attack_button_margin: Vector2 = Vector2(100, 110)
@export var interact_button_margin: Vector2 = Vector2(210, 70)

var joystick_direction: Vector2 = Vector2.ZERO
var active_touch_index: int = -1

func _ready() -> void:
	joystick_knob.position = (
		joystick_base.size - joystick_knob.size
	) / 2.0
	get_viewport().size_changed.connect(place_buttons)
	place_buttons()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if active_touch_index == -1:
				if is_inside_joystick(event.position):
					active_touch_index = event.index
					update_joystick(event.position)
		elif event.index == active_touch_index:
			active_touch_index = -1
			reset_joystick()
	elif event is InputEventScreenDrag:
		if event.index == active_touch_index:
			update_joystick(event.position)

# Indica si el toque empezó dentro de la base del joystick.
func is_inside_joystick(screen_position: Vector2) -> bool:
	var center: Vector2 = get_joystick_center()
	var touch_radius: float = joystick_base.size.x / 2.0
	return screen_position.distance_to(center) <= touch_radius

# Mueve la perilla siguiendo el dedo y convierte su desplazamiento
# en las acciones de movimiento del jugador.
func update_joystick(screen_position: Vector2) -> void:
	var offset: Vector2 = (
		screen_position - get_joystick_center()
	).limit_length(joystick_radius)

	joystick_knob.position = (
		joystick_base.size - joystick_knob.size
	) / 2.0 + offset

	joystick_direction = offset / joystick_radius

	if joystick_direction.length() < deadzone:
		joystick_direction = Vector2.ZERO

	apply_movement(joystick_direction)

# Regresa la perilla al centro y detiene el movimiento.
func reset_joystick() -> void:
	joystick_direction = Vector2.ZERO
	joystick_knob.position = (
		joystick_base.size - joystick_knob.size
	) / 2.0
	apply_movement(Vector2.ZERO)

func get_joystick_center() -> Vector2:
	return joystick_base.get_global_rect().get_center()

# Presiona las mismas acciones que usa el teclado para que
# player.gd las lea con Input.get_vector().
func apply_movement(direction: Vector2) -> void:
	set_action_strength("move_left", maxf(-direction.x, 0.0))
	set_action_strength("move_right", maxf(direction.x, 0.0))
	set_action_strength("move_up", maxf(-direction.y, 0.0))
	set_action_strength("move_down", maxf(direction.y, 0.0))

func set_action_strength(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

# Ubica los botones de ataque e interacción en la esquina inferior
# derecha, sin importar el tamaño de la pantalla del móvil.
func place_buttons() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	attack_button.position = screen_size - attack_button_margin
	interact_button.position = screen_size - interact_button_margin

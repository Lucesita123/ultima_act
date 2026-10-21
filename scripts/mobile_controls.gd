extends CanvasLayer

@onready var joystick_base: Control = $Controls/JoystickBase
@onready var joystick_knob: Control = $Controls/JoystickBase/JoystickKnob

@export var joystick_radius: float = 65.0
@export var deadzone: float = 0.15

var joystick_direction: Vector2 = Vector2.ZERO
var active_touch_index: int = -1

func _ready() -> void:
	joystick_knob.position = (
		joystick_base.size - joystick_knob.size
	) / 2.0
	
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

func is_inside_joystick(screen_position: Vector2):
	pass

func update_joystick(screen_position: Vector2):
	pass
	
func reset_joystick():
	pass

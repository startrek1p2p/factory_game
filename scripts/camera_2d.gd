extends Camera2D

const ACTION_MOVE_UP := "camera_move_up"
const ACTION_MOVE_DOWN := "camera_move_down"
const ACTION_MOVE_LEFT := "camera_move_left"
const ACTION_MOVE_RIGHT := "camera_move_right"

var speed := 300.0

func _ready() -> void:
	_register_action_if_missing(ACTION_MOVE_UP, KEY_W)
	_register_action_if_missing(ACTION_MOVE_DOWN, KEY_S)
	_register_action_if_missing(ACTION_MOVE_LEFT, KEY_A)
	_register_action_if_missing(ACTION_MOVE_RIGHT, KEY_D)

func _process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed(ACTION_MOVE_UP):
		direction.y -= 1
	if Input.is_action_pressed(ACTION_MOVE_DOWN):
		direction.y += 1
	if Input.is_action_pressed(ACTION_MOVE_LEFT):
		direction.x -= 1
	if Input.is_action_pressed(ACTION_MOVE_RIGHT):
		direction.x += 1

	position += direction.normalized() * speed * delta

func _register_action_if_missing(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventKey and input_event.keycode == keycode:
			return

	var new_event := InputEventKey.new()
	new_event.keycode = keycode
	InputMap.action_add_event(action_name, new_event)

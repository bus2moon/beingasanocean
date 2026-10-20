extends Node3D
## Graybox Block entry scene: captures the mouse, Esc releases it, and falling
## out of the world respawns Cub.

@export var respawn_below := -20.0

@onready var player: Player = $Player
@onready var spawn: Marker3D = $Spawn


func _ready() -> void:
	player.global_position = spawn.global_position
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	if player.global_position.y < respawn_below:
		player.global_position = spawn.global_position
		player.velocity = Vector3.ZERO

extends Node
## Windowed smoke run: loads the main scene, sprints Cub forward for a few
## seconds, logs FPS, saves a screenshot to user://capture.png, then quits.
## Run: Godot --path . res://tests/capture.tscn

const MAIN := preload("res://scenes/main.tscn")


func _ready() -> void:
	var main := MAIN.instantiate()
	add_child(main)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player: Player = main.get_node("Player")
	var intent := PlayerIntent.new()
	intent.move = Vector2(0, 1)
	intent.sprint = true
	player.scripted_intent = intent
	var samples: Array[float] = []
	var shot: Image
	for i in 420:
		await get_tree().process_frame
		if i > 240:
			samples.append(Engine.get_frames_per_second())
		if i == 70:
			shot = get_viewport().get_texture().get_image()
	shot.save_png("user://capture.png")
	samples.sort()
	print("fps min %d median %d | screenshot %s" % [samples[0], samples[samples.size() / 2], ProjectSettings.globalize_path("user://capture.png")])
	get_tree().quit()

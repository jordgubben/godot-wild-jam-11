extends Control

onready var timer = get_node("Timer")
onready var tween = get_node("Tween")
onready var sprite_left = $SpriteLeft
onready var sprite_right = $SpriteRight

var white_opaque = Color(1.0, 1.0, 1.0, 1.0)
var white_transparent = Color(1.0, 1.0, 1.0, 0.0)
var black_opaque = Color(0.0, 0.0, 0.0, 1.0)
var black_transparent = Color(0.0, 0.0, 0.0, 0.0)
var light_gray_opaque = Color(0.75, 0.75, 0.75, 1.0)

var mirrored_sprite = "right"

var shake_base = 20
var move_distance = 100
var ease_in_speed = 0.25
var ease_out_speed = 0.50

var characters_folder = "res://img/characters"
var characters_image_format = "png"

var previous_pos
var sprite

var on_tween = false

var shake_amount

var shake_weak = 1
var shake_regular = 2
var shake_strong = 4

var shake_short = 0.25
var shake_medium = 0.5
var shake_long = 2

func _ready():
	set_physics_process(false)
	timer.connect("timeout", self, "on_Timer_timeout")
	timer.one_shot = true
	
	if mirrored_sprite == "left":
		sprite_left.scale.x = -1
	elif mirrored_sprite == "right":
		sprite_right.scale.x = -1

func _physics_process(delta):
	sprite.offset = Vector2(rand_range(-1.0, 1.0) * shake_amount, rand_range(-1.0, 1.0) * shake_amount)

func load_image(character, image, sprite):
	sprite.texture = load("%s/%s/%s.%s" % [characters_folder, character, image, characters_image_format])

func animate_sprite(character, image, animation, direction):
	
	var current_pos
	var move_vector_in
	var move_vector_out
	
	if direction == 'left':
		sprite = sprite_left
		current_pos = sprite.position
		
		move_vector_in = Vector2(current_pos.x + move_distance, current_pos.y)
		move_vector_out = Vector2(current_pos.x - move_distance, current_pos.y)
	else:
		sprite = sprite_right
		current_pos = sprite.position
		
		move_vector_in = Vector2(current_pos.x - move_distance, current_pos.y)
		move_vector_out = Vector2(current_pos.x + move_distance, current_pos.y)
	
	previous_pos = current_pos
	
	match animation:
		
		'shake_weak_short':
			shake_amount = shake_weak
			timer.wait_time = shake_short
			timer.start()
			set_physics_process(true)
			
		'shake_weak_medium':
			shake_amount = shake_weak
			timer.wait_time = shake_medium
			timer.start()
			set_physics_process(true)
			
		'shake_weak_long':
			shake_amount = shake_weak
			timer.wait_time = shake_long
			timer.start()
			set_physics_process(true)
			
		'shake_regular_short':
			shake_amount = shake_regular
			timer.wait_time = shake_short
			timer.start()
			set_physics_process(true)
			
		'shake_regular_medium':
			shake_amount = shake_regular
			timer.wait_time = shake_medium
			timer.start()
			set_physics_process(true)
			
		'shake_regular_long':
			shake_amount = shake_regular
			timer.wait_time = shake_long
			timer.start()
			set_physics_process(true)
			
		'shake_strong_short':
			shake_amount = shake_strong
			timer.wait_time = shake_short
			timer.start()
			set_physics_process(true)
			
		'shake_strong_medium':
			shake_amount = shake_strong
			timer.wait_time = shake_medium
			timer.start()
			set_physics_process(true)
			
		'shake_strong_long':
			shake_amount = shake_strong
			timer.wait_time = shake_long
			timer.start()
			set_physics_process(true)
			
		'fade_in':
			load_image(character, image, sprite)
			tween.interpolate_property(sprite, "modulate",
					white_transparent, white_opaque, ease_in_speed/1.25,
					Tween.TRANS_QUAD, Tween.EASE_IN)
					
			tween.start()
			
		'fade_out':
			tween.interpolate_property(sprite, "modulate",
					white_opaque, white_transparent, ease_out_speed/1.25,
					Tween.TRANS_QUAD, Tween.EASE_OUT)
					
			tween.start()
			
		'move_in':
			load_image(character, image, sprite)
			tween.interpolate_property(sprite, "position",
					current_pos, move_vector_in, ease_in_speed,
					Tween.TRANS_QUINT, Tween.EASE_IN)
					
			tween.interpolate_property(sprite, "modulate",
					white_transparent, white_opaque, ease_in_speed,
					Tween.TRANS_QUINT, Tween.EASE_IN)
					
			tween.start()
			
		'move_out':
			tween.interpolate_property(sprite, "position",
					current_pos, move_vector_out, ease_out_speed,
					Tween.TRANS_BACK, Tween.EASE_OUT)
					
			tween.interpolate_property(sprite, "modulate",
					white_opaque, black_transparent, ease_out_speed,
					Tween.TRANS_QUINT, Tween.EASE_OUT)
					
			tween.start()
		
		'on':
			tween.interpolate_property(sprite, "modulate",
					light_gray_opaque, white_opaque, ease_in_speed,
					Tween.TRANS_QUAD, Tween.EASE_IN)
					
			tween.start()
		'off':
			tween.interpolate_property(sprite, "modulate",
					white_opaque, light_gray_opaque, ease_out_speed,
					Tween.TRANS_QUAD, Tween.EASE_OUT)
					
			tween.start()

func _input(event):
	if event.is_action_pressed("ui_left"):
		animate_sprite('jimmy', '01', 'move_out', 'left')
		yield(tween, "tween_completed")
		animate_sprite('jimmy', '01', 'move_in', 'left')
		
	if event.is_action_pressed("ui_up"):
		animate_sprite('jimmy', '02', 'move_out', 'left')
		yield(tween, "tween_completed")
		animate_sprite('jimmy', '02', 'move_in', 'left')

	if event.is_action_pressed("ui_accept"):
		animate_sprite('jimmy', '01', 'on', 'left')
		animate_sprite('jimmy', '01', 'off', 'right')
	if event.is_action_pressed("ui_cancel"):
		animate_sprite('jimmy', '01', 'off', 'left')
		animate_sprite('jimmy', '01', 'on', 'right')
		
	if event.is_action_pressed("ui_focus_next"):
		animate_sprite('jimmy', '01', 'shake_regular_medium', 'left')
		
	if event.is_action_pressed("ui_right"):
		animate_sprite('jimmy', '01', 'move_out', 'right')
		yield(tween, "tween_completed")
		animate_sprite('jimmy', '01', 'move_in', 'right')

	if event.is_action_pressed("ui_down"):
		animate_sprite('jimmy', '02', 'move_out', 'right')
		yield(tween, "tween_completed")
		animate_sprite('jimmy', '02', 'move_in', 'right')
		
func on_Timer_timeout():
	sprite.position = previous_pos
	set_physics_process(false)
	
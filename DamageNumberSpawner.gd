@icon("uid://bvrool5ggsehu")
class_name DamageNumberSpawner
extends Node2D

# Spawns floating damage numbers when a DamageableArea is hit.

# --- TUNABLES ---
@export var label_settings: LabelSettings
@export var critical_hit_color: Color = Color.RED
@export var float_height: float = 40.0
@export var duration: float = 0.6
@export var target_path: NodePath

# --- LIFECYCLE ---
func _ready() -> void:
	print("[DamageNumberSpawner] _ready called")

	var target: DamageableArea = null

	if target_path != NodePath():
		target = get_node_or_null(target_path)
		if target and target is DamageableArea:
			print("[DamageNumberSpawner] Connected via target_path")
		else:
			print("[DamageNumberSpawner] target_path not valid")

	if target == null and get_parent() and get_parent() is DamageableArea:
		target = get_parent()
		print("[DamageNumberSpawner] Connected to parent DamageableArea")

	if target:
		target.damage_taken.connect(_on_damage_taken)
		print("[DamageNumberSpawner] Successfully connected to DamageableArea")
	else:
		print("[DamageNumberSpawner] ERROR: No DamageableArea found!")

# --- SIGNAL HANDLERS ---
func _on_damage_taken(attack_area: AttackArea) -> void:
	print("[DamageNumberSpawner] _on_damage_taken triggered")

	if attack_area == null:
		print("[DamageNumberSpawner] ERROR: attack_area is null")
		return

	var damage := attack_area.damage

	# Compute spawn position above the DamageableArea
	var spawn_pos: Vector2 = Vector2.ZERO
	if attack_area.get_parent() and attack_area.get_parent() is DamageableArea:
		var area = attack_area.get_parent() as DamageableArea
		spawn_pos = area.global_position

		var shape_node = area.get_node_or_null("CollisionShape2D")
		if shape_node and shape_node is CollisionShape2D:
			var rect = shape_node.shape.get_rect()
			spawn_pos += Vector2(rect.size.x / 2, -rect.size.y / 2)
	else:
		spawn_pos = attack_area.global_position

	print("[DamageNumberSpawner] Damage:", damage, "Spawn Position:", spawn_pos)
	spawn_label(damage, spawn_pos)

# --- SPAWNING ---
func spawn_label(number: float, world_pos: Vector2, critical_hit: bool = false) -> void:
	var label: Label = Label.new()

	label.text = str(int(number)) if number == int(number) else str(number)

	if label_settings:
		label.label_settings = label_settings.duplicate()

	if critical_hit and label.label_settings:
		label.label_settings.font_color = critical_hit_color

	label.z_index = 1000
	add_child(label)

	# Get font height safely
	var font_height = 20
	var font = label.get_theme_font("font")
	if font:
		font_height = font.get_height()

	# Position above target
	label.global_position = world_pos + Vector2(0, -font_height)

	label.global_position += Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))

	await label.resized
	label.pivot_offset = label.size / 2.0

	animate_label(label)
	print("[DamageNumberSpawner] Spawned label at", label.global_position)

# --- ANIMATION ---
func animate_label(label: Label) -> void:
	var tween = create_tween()

	label.scale = Vector2(0.6, 0.6)

	var target_pos = label.global_position + Vector2(0, -float_height)
	tween.tween_property(label, "global_position", target_pos, duration)

	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.2)

	tween.finished.connect(func():
		print("[DamageNumberSpawner] Label animation finished, freeing")
		label.queue_free()
	)
	

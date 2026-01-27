extends CanvasLayer
class_name LiveOverlay

@onready var container: Control = Control.new()
@onready var chat_panel: PanelContainer = PanelContainer.new() 
@onready var chat_list: VBoxContainer = VBoxContainer.new()
@onready var top_bar: PanelContainer = PanelContainer.new()
@onready var watcher_count_label: Label = Label.new()
@onready var score_label: Label = Label.new()

var tracker: HypeTracker
var _rng = RandomNumberGenerator.new()
var _watcher_count: int = 1240
var _target_watcher_count: float = 1240.0
var _msg_timer: Timer

# Deduplication History
var _recent_msgs: Array[String] = []
var _recent_users: Array[String] = []
const HISTORY_SIZE: int = 6

const MAX_CHAT_MESSAGES = 8
const USERNAMES = [
	"sk8r_dawg", "good_boy_99", "clout_chaser", "bone_collector",
	"viziz_fan", "woofer", "radical_retriever", "cat_hater_420",
	"speed_demon", "glitch_hunter", "dev_account", "paw_patrol",
	"thrasher_mag_fan", "kickflip_king", "gale_force", "tony_awk"
]

const COMMENTS_TRICK = [
	"SICK!!", "How?? 🤯", "clean ✨", "insane combo",
	"clipped it!", "sheesh", "🔥", "🔥🔥🔥", "Do a kickflip!", "yoooo",
	"ACTUALLY INSANE", "poggers", "🛹🛹🛹", "wicked"
]

const COMMENTS_GRIND = [
	"So smooth", "infinite grind?", "balance check", "rail god",
	"satisfying...", "sparks flying ✨", "grindset", "locked in 🔒",
	"holding it down", "screeeech 🤘"
]

const COMMENTS_BAIL = [
	"RIP 💀", "You okay?", "oof", "that hurt to watch",
	"medic!", "ragdoll physics lol", "F", "💀💀💀💀💀",
	"my ankles hurt watching this", "fail", "wasted", "😭"
]

const COMMENTS_IDLE = [
	"are we lagging?", "go fast again", "hello?", "more tricks pls",
	"boring...", "waiting for content", "💤", "do something cool",
	"IS that a DOG on a skateboard? wtaf !?" 
]

const DONATION_MSGS = [
	"Buy some dog treats 🦴", "New deck fund!", "You're insane!",
	"First time chatter, long time watcher", "Respect +++"
]

func _ready() -> void:
	name = "LiveOverlay"
	_rng.randomize()
	
	tracker = HypeTracker.new()
	tracker.name = "HypeTracker"
	tracker.score_changed.connect(_on_score_changed)
	tracker.combo_dropped.connect(_on_combo_dropped)
	add_child(tracker)
	
	_setup_ui()
	
	# Random periodic messages
	_msg_timer = Timer.new()
	_msg_timer.wait_time = 3.0
	_msg_timer.autostart = true
	_msg_timer.timeout.connect(_on_idle_timer)
	add_child(_msg_timer)

func _process(delta: float) -> void:
	# Smoothly update watcher count (Viewers are visual only, tracked here)
	var elastic_count = lerp(float(_watcher_count), _target_watcher_count, delta * 2.0)
	_watcher_count = int(elastic_count)
	watcher_count_label.text = "👁 %s" % str(_watcher_count)

func _setup_ui() -> void:
	# Root Control
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	# Background style for chat
	var chat_bg = StyleBoxFlat.new()
	chat_bg.bg_color = Color(0.0, 0.0, 0.0, 0.4)
	chat_bg.corner_radius_top_right = 10
	chat_bg.content_margin_left = 12
	chat_bg.content_margin_right = 12
	chat_bg.content_margin_top = 10
	chat_bg.content_margin_bottom = 10
	
	chat_panel.add_theme_stylebox_override("panel", chat_bg)
	chat_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	chat_panel.position = Vector2(20, -20)
	chat_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# Manual position adjustment
	chat_panel.position.y = get_viewport().get_visible_rect().size.y - 40
	chat_panel.custom_minimum_size = Vector2(340, 0)
	chat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(chat_panel)
	
	chat_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_list.add_theme_constant_override("separation", 4)
	chat_panel.add_child(chat_list)
	
	top_bar.position = Vector2(20, 20)
	var top_sb = StyleBoxFlat.new()
	top_sb.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	top_sb.corner_radius_top_left = 4
	top_sb.corner_radius_top_right = 4
	top_sb.corner_radius_bottom_right = 4
	top_sb.corner_radius_bottom_left = 4
	top_sb.content_margin_left = 8
	top_sb.content_margin_right = 12
	top_sb.content_margin_top = 6
	top_sb.content_margin_bottom = 6
	top_bar.add_theme_stylebox_override("panel", top_sb)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	top_bar.add_child(hbox)
	
	# "LIVE" Badge
	var live_pill = PanelContainer.new()
	var pill_sb = StyleBoxFlat.new()
	pill_sb.bg_color = Color(0.9, 0.0, 0.0, 1.0)
	pill_sb.corner_radius_top_left = 4
	pill_sb.corner_radius_top_right = 4
	pill_sb.corner_radius_bottom_right = 4
	pill_sb.corner_radius_bottom_left = 4
	pill_sb.content_margin_left = 6
	pill_sb.content_margin_right = 6
	live_pill.add_theme_stylebox_override("panel", pill_sb)
	var live_lbl = Label.new()
	live_lbl.text = "LIVE"
	live_lbl.add_theme_font_size_override("font_size", 12)
	live_lbl.add_theme_constant_override("font_outline_size", 0)
	live_pill.add_child(live_lbl)
	hbox.add_child(live_pill)
	
	# Watcher Count
	watcher_count_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(watcher_count_label)
	
	# Separator
	var sep = VSeparator.new()
	hbox.add_child(sep)
	
	# Score
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.modulate = Color(1, 0.8, 0.2)
	score_label.text = "HYPE: 0 (x1)"
	hbox.add_child(score_label)
	
	container.add_child(top_bar)
	
	# Add initial welcome
	add_chat_message("StreamBot", "Welcome to the stream! Type !commands for info.")

func _get_unique_item(source_array: Array, history_array: Array) -> String:
	var item = source_array.pick_random()
	var attempts = 0
	# Try up to 5 times to find one not in history
	while item in history_array and attempts < 5:
		item = source_array.pick_random()
		attempts += 1
	
	# Add to history and maintain size
	history_array.append(item)
	if history_array.size() > HISTORY_SIZE:
		history_array.pop_front()
		
	return item

func _get_user_color(username: String) -> Color:
	# Generate a consistent color from username hash
	var hash_val = username.hash()
	var r = (hash_val & 0xFF) / 255.0
	var g = ((hash_val >> 8) & 0xFF) / 255.0
	var b = ((hash_val >> 16) & 0xFF) / 255.0
	return Color(r, g, b).lightened(0.3)

func add_chat_message(username: String, text: String, name_color: Color = Color.WHITE) -> void:
	if not visible:
		return
	
	var avatar_color = _get_user_color(username).to_html(false)
	var avatar = "[color=#%s]■[/color]" % avatar_color
	
	# Name color formatting
	var name_html = name_color.to_html(false)
	
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	# Format: [Avatar] [Name]: Payload
	lbl.text = "%s [color=#%s][b]%s:[/b][/color] %s" % [avatar, name_html, username, text]
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.custom_minimum_size = Vector2(280, 22)
	
	# Shadow
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	
	chat_list.add_child(lbl)
	
	# Animation: simple fade/slide in
	lbl.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.2)
	
	_cleanup_chat()

func add_special_message(username: String, text: String, bg_color: Color) -> void:
	if not visible: return
	
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	
	panel.add_theme_stylebox_override("panel", sb)
	
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = "[b]%s[/b] %s" % [username, text]
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.custom_minimum_size = Vector2(280, 22)
	
	panel.add_child(lbl)
	chat_list.add_child(panel)
	
	# Pop in animation
	panel.scale = Vector2.ONE * 0.1
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_cleanup_chat()

func _spawn_center_notification(title: String, subtitle: String, bg_color: Color) -> void:
	if not visible: return
	
	# Create a flashy center-top popup
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_bottom = 6
	sb.border_color = bg_color.lightened(0.2)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 10
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	vbox.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = subtitle
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 28)
	sub_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	sub_lbl.add_theme_constant_override("shadow_offset_x", 3)
	sub_lbl.add_theme_constant_override("shadow_offset_y", 3)
	sub_lbl.add_theme_constant_override("font_outline_size", 4)
	sub_lbl.add_theme_color_override("font_outline_color", Color(0,0,0,0.5))
	vbox.add_child(sub_lbl)
	
	container.add_child(panel)
	
	# Position: Top Center (anchors don't always behave immediately with pure code spawns)
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	# Force a manual offset down from top
	panel.position.y += 80 
	# Center X manually if anchors lag
	panel.position.x = (get_viewport().get_visible_rect().size.x - panel.size.x) / 2
	
	# Initial Setup
	panel.scale = Vector2.ZERO
	panel.pivot_offset = panel.size / 2
	
	# Setup Sequence
	var tween = create_tween()
	tween.set_parallel(false)
	
	# 1. Elastic Pop In
	tween.tween_property(panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# 2. Hold (Wait)
	tween.tween_interval(1.0)
	
	# 3. Pulse (Attention Grab)
	tween.tween_property(panel, "scale", Vector2.ONE * 1.15, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE)
	
	# 4. Hold more
	tween.tween_interval(1.5)
	
	# 5. Fly Away
	var exit_tween = tween.parallel()
	exit_tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	exit_tween.tween_property(panel, "position:y", panel.position.y - 100, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(panel.queue_free)

func _cleanup_chat() -> void:
	# Remove old messages
	while chat_list.get_child_count() > MAX_CHAT_MESSAGES:
		var old = chat_list.get_child(0)
		chat_list.remove_child(old)
		old.queue_free()
		
	# Re-adjust position
	chat_panel.size.y = 0 
	chat_panel.position.y = get_viewport().get_visible_rect().size.y - chat_panel.get_rect().size.y - 20


func trigger_trick_reaction() -> void:
	var _previous_multiplier = tracker.get_multiplier()
	tracker.add_trick_score(150.0)
	var current_multiplier = tracker.get_multiplier()
	
	_target_watcher_count += _rng.randf_range(10, 50) * current_multiplier
	
	# High combo = High chance of donation or sub
	if current_multiplier > 4 and _rng.randf() > 0.85:
		trigger_donation()
	elif current_multiplier > 2 and _rng.randf() > 0.9:
		trigger_sub()
	
	var count = _rng.randi_range(1, 3)
	for i in count:
		var user = _get_unique_item(USERNAMES, _recent_users)
		var msg = _get_unique_item(COMMENTS_TRICK, _recent_msgs)
		
		# Hype up comments on high chains
		if current_multiplier > 4:
			msg = "🔥 " + msg + " 🔥"
			
		add_chat_message(user, msg, Color.GOLD)

func trigger_grind_start() -> void:
	# Initial burst for locking onto the rail
	tracker.add_trick_score(50.0) 
	_target_watcher_count += _rng.randf_range(5, 10)

	# High chance of initial "Locked in" message
	if _rng.randf() > 0.4:
		var user = _get_unique_item(USERNAMES, _recent_users)
		var msg = "Locked in 🔒"
		add_chat_message(user, msg, Color.ORANGE)

func process_grind_tick(delta: float) -> void:
	# Continuous score per second (e.g. 500 base points per sec)
	tracker.add_grind_score(500.0 * delta)

	# Continuous viewer gain
	_target_watcher_count += 5.0 * delta

	# Occasional chat message (approx every 1.5 seconds)
	if _rng.randf() < (0.6 * delta):
		var user = _get_unique_item(USERNAMES, _recent_users)
		var msg = _get_unique_item(COMMENTS_GRIND, _recent_msgs)
		add_chat_message(user, msg, Color.ORANGE)

	# Kept for backward compatibility if needed, but redirects to start
func trigger_grind_reaction() -> void:
	trigger_grind_start()

func trigger_bail_reaction() -> void:
	tracker.fail_combo()
	
	_target_watcher_count -= _rng.randf_range(50, 200)
	if _target_watcher_count < 0: _target_watcher_count = 0
	
	for i in range(3):
		var user = _get_unique_item(USERNAMES, _recent_users)
		var msg = _get_unique_item(COMMENTS_BAIL, _recent_msgs)
		add_chat_message(user, msg, Color(1, 0.4, 0.4))

func trigger_donation() -> void:
	var user = USERNAMES.pick_random() # Allowed to be duplicate for important event
	var amount = _rng.randi_range(5, 50)
	var msg = DONATION_MSGS.pick_random()
	
	# Donation
	add_special_message(user, "donated $%d: %s" % [amount, msg], Color(0.2, 0.6, 0.2, 0.6))
	_spawn_center_notification("HYPE DONATION!", "$%d from %s" % [amount, user], Color(0.2, 0.7, 0.3, 0.9))
	
	_target_watcher_count += 100

func trigger_sub() -> void:
	var user = USERNAMES.pick_random()
	
	# Subs
	add_special_message(user, "just subscribed! 🎉", Color(0.6, 0.2, 0.6, 0.6))
	_spawn_center_notification("NEW SUBSCRIBER!", user, Color(0.5, 0.2, 0.8, 0.9))

func _on_score_changed(_current_score: float, display_score: float) -> void:
	score_label.text = "HYPE: %d (x%d)" % [int(display_score), tracker.get_multiplier()]
	# Pulse effect on high multiplier
	if tracker.get_multiplier() >= 4:
		score_label.modulate = Color.RED.lerp(Color.GOLD, abs(sin(Time.get_ticks_msec() * 0.005)))
	else:
		score_label.modulate = Color.GOLD

func _on_combo_dropped() -> void:
	add_chat_message("System", "Combo dropped... 💤", Color(1, 1, 1, 0.5))

func _on_idle_timer() -> void:
	if _rng.randf() > 0.7:
		var user = _get_unique_item(USERNAMES, _recent_users)
		var msg = _get_unique_item(COMMENTS_IDLE, _recent_msgs)
		add_chat_message(user, msg, Color.LIGHT_GRAY)

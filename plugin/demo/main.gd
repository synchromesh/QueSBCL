# main.gd - entry point for QueSBCL Demo app.
# File Created: 11 March 2025
# 19 Mar 25 JDP Now based on https://docs.godotengine.org/en/latest/tutorials/xr/setting_up_xr.html
# Ref: https://docs.godotengine.org/en/latest/tutorials/xr/a_better_xr_start_script.html

extends Node3D

signal lost_focus
signal received_focus
signal pose_recentered

@export var maximum_refresh_rate : int = 90
var xr_interface : XRInterface
var xr_is_focused : bool = false
var quesbcl : QueSBCLInterface

func _on_session_begun() -> void:
	var current_refresh_rate = xr_interface.get_display_refresh_rate()
	if current_refresh_rate > 0:
		print("main.gd:_on_session_begun(): Refresh rate reported as %fHz" % current_refresh_rate)
	else:
		push_warning("main.gd:_on_session_begun(): No refresh rate provided by XR runtime.")

	# Check whether a faster refresh rate is available.
	var new_rate = current_refresh_rate
	var available_rates : Array = xr_interface.get_available_display_refresh_rates()
	if available_rates.size() == 0:
		print("main.gd:_on_session_begun(): Target does not support refresh rate extension.")
	elif available_rates.size() == 1:
		new_rate = available_rates[0]
	else:
		for rate in available_rates:
			if rate > new_rate and rate <= maximum_refresh_rate:
				new_rate = rate
	if current_refresh_rate != new_rate:
		print("main.gd:_on_session_begun(): Increasing refresh rate to %fHz." % new_rate)
		xr_interface.set_display_refresh_rate(new_rate)
		current_refresh_rate = new_rate
	Engine.physics_ticks_per_second = current_refresh_rate

func _on_session_visible() -> void:
	# We always pass this state at startup,
	# but the second time we get this it means our player took off their headset
	if xr_is_focused:
		print("main.gd:_on_session_visible(): OpenXR lost focus.")
		xr_is_focused = false
		# pause our game
		get_tree().paused = true
		emit_signal("lost_focus")
	else:
		print("main.gd:_on_session_visible(): Ignoring visible_state.")

func _on_session_focussed() -> void:
	print("main.gd:_on_session_focussed(): OpenXR received focus.")
	xr_is_focused = true
	# unpause our game
	get_tree().paused = false
	emit_signal("received_focus")

func _on_session_stopping() -> void:
	# Our session is being stopped.
	print("main.gd:_on_session_stopping(): OpenXR is stopping.")

func _on_pose_recentered() -> void:
	print("main.gd:_on_pose_recentered(): User has recentred their view.")
	emit_signal("pose_recentered")

func setup_plugin(plugin_name):
	var plugin
	if Engine.has_singleton(plugin_name):
		plugin = Engine.get_singleton(plugin_name)
		print("main.gd:setup_plugin(): Type of Android plugin '%s' is %s." % [plugin_name, type_string(typeof(plugin))])
	else:
		printerr("main.gd:setup_plugin(): Couldn't find plugin '%s'!" % plugin_name)

	return plugin

func setup_xr():
	xr_interface = XRServer.find_interface("OpenXR")
	if not xr_interface or not xr_interface.is_initialized():
		printerr("main.gd:setup_xr(): OpenXR not initialized, please check your headset!")
		await get_tree().create_timer(3.0).timeout
		get_tree().quit()

	print("main.gd:setup_xr(): OpenXR instantiated successfully.")
	var viewport : Viewport = get_viewport()

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	viewport.use_xr = true
	if RenderingServer.get_rendering_device():
		viewport.vrs_mode = Viewport.VRS_XR
	elif int(ProjectSettings.get_setting("xr/openxr/foveation_level")) == 0:
		push_warning("main.gd:setup_xr(): Please set Foveation Level to High in Project Settings.")

	xr_interface.session_begun.connect(_on_session_begun)
	xr_interface.session_visible.connect(_on_session_visible)
	xr_interface.session_focussed.connect(_on_session_focussed)
	xr_interface.session_stopping.connect(_on_session_stopping)
	xr_interface.pose_recentered.connect(_on_pose_recentered)

func set_hand_colour(colour : Color):
	get_node("lhBox").mesh.material.albedo_color = colour
	get_node("rhBox").mesh.material.albedo_color = colour

func _ready():
	print("main.gd:_ready()")
	setup_xr()
	quesbcl = QueSBCLInterface.new()
	if quesbcl.helloWorld():
		set_hand_colour(Color.GREEN)
	get_node("rhBox").mesh.material.albedo_color = Color.BLUE
	print("main.gd:_ready(): Done.")

# End of main.gd

# export_plugin.gd 11 Mar 25 JDP QueSBCL

@tool
extends EditorPlugin

const plugin_name = "QueSBCL"

# A class member to hold the editor export plugin during its lifecycle.
var export_plugin : AndroidExportPlugin

func _enter_tree():
	# Initialization of the plugin goes here.
	print("export_plugin.gd:_enter_tree()")
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree():
	# Clean-up of the plugin goes here.
	print("export_plugin.gd:_exit_tree()")
	remove_export_plugin(export_plugin)
	export_plugin = null

func lib_path(name):
	# This path should match the one(s) in the plugin.gdextension file.
	return plugin_name + "/bin/extra/lib" + name + ".so"

class AndroidExportPlugin extends EditorExportPlugin:
	func _supports_platform(platform):
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform, debug):
		var config = "debug" if debug else "release"
		print("export_plugin.gd:_get_android_libraries(%s, %s)" % [platform, config])
		# These paths are relative to QueSBCL/plugin/demo/addons/.
		var aar_path = plugin_name + "/bin/" + config + "/" + _plugin_name + "-" + config + ".aar"
		
		return PackedStringArray([aar_path, lib_path("core"), lib_path("sbcl"), lib_path("zstd")])

	func _get_name():
		return plugin_name

# End of export_plugin.gd

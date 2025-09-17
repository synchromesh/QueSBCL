# export_plugin.gd 11 Mar 25 JDP QueSBCL
# Ref: https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html#packaging-a-v2-android-plugin

@tool
extends EditorPlugin

const plugin_name : String = "QueSBCL"

# A class member to hold the editor export plugin during its lifecycle.
var export_plugin : AndroidExportPlugin

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	print("export_plugin.gd:_enter_tree()")
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	print("export_plugin.gd:_exit_tree()")
	remove_export_plugin(export_plugin)
	export_plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
	func _lib_path(name : String) -> String:
		# This path should match the one(s) in the plugin.gdextension file.
		return plugin_name + "/bin/extra/lib" + name + ".so"

	func _supports_platform(platform : EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform : EditorExportPlatform, debug : bool) -> PackedStringArray:
		var config = "debug" if debug else "release"
		print("export_plugin.gd:_get_android_libraries(%s, %s)" % [platform, config])
		# These paths are relative to QueSBCL/plugin/demo/addons/.
		var aar_path = plugin_name + "/bin/" + config + "/" + plugin_name + "-" + config + ".aar"
		var result = [aar_path, _lib_path("core"), _lib_path("sbcl"), _lib_path("zstd")]
		print("export_plugin.gd:_get_android_libraries(): Returning [%s, %s, %s, %s]" % result)

		return PackedStringArray(result)

	func _get_name() -> String:
		return plugin_name

	# Other EditorExportPlugin API methods:
	#
	# _supports_platform: returns true if the plugin supports the given
	# platform. For Android plugins, this must return true when platform is
	# EditorExportPlatformAndroid
	#
	# _get_android_libraries: retrieve the local paths of the Android libraries
	# binaries (AAR files) provided by the plugin
	#
	# _get_android_dependencies: retrieve the set of Android maven dependencies
	# (e.g: org.godot.example:my-plugin:0.0.0) provided by the plugin
	#
	# _get_android_dependencies_maven_repos: retrieve the urls of the maven
	# repos for the android dependencies provided by _get_android_dependencies
	#
	# _get_android_manifest_activity_element_contents: update the contents of
	# the <activity> element in the generated Android manifest
	#
	# _get_android_manifest_application_element_contents: update the contents of
	# the <application> element in the generated Android manifest
	#
	# _get_android_manifest_element_contents: update the contents of the
	# <manifest> element in the generated Android manifest
	#
	# The _get_android_manifest_* methods allow the plugin to automatically
	# provide changes to the app's manifest which are preserved when the Godot
	# Editor is updated, resolving a long standing issue with v1 Android
	# plugins.
	#
	# Ref: https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html#packaging-a-v2-android-plugin

# End of export_plugin.gd

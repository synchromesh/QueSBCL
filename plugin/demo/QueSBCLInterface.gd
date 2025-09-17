class_name QueSBCLInterface extends Object

const _plugin_name = "QueSBCL"
var _plugin_singleton

func _init() -> void:
	print("QueSBCLInterface.gd:_init()")
	if Engine.has_singleton(_plugin_name):
		_plugin_singleton = Engine.get_singleton(_plugin_name)
		print("QueSBCLInterface.gd:_init(): Type of Android plugin '%s' is %s." % [_plugin_name, type_string(typeof(_plugin_singleton))])
	else:
		var singletons = Engine.get_singleton_list()
		printerr("QueSBCLInterface.gd:_init(): Error - couldn't find plugin '%s' in %d singleton(s)!" % [_plugin_name, singletons.size()])
		for s in singletons:
			print("QueSBCLInterface.gd:_init(): %s" % s)

func helloWorld() -> bool:
	if _plugin_singleton:
		print("QueSBCLInterface.gd:helloWorld(): Calling into QueSBCL...")
		_plugin_singleton.helloWorld()
		print("QueSBCLInterface.gd:helloWorld(): QueSBCL call returned.")
		return true

	return false

func helloWorldSignal(name : String) -> bool:
	if _plugin_singleton:
		print("QueSBCLInterface.gd:helloWorldSignal('%s'): Calling into QueSBCL..." % name)
		_plugin_singleton.helloWorldSignal(name)
		print("QueSBCLInterface.gd:helloWorldSignal('%s'): QueSBCL call returned." % name)
		return true

	return false

# End of QueSBCLInterface.gd

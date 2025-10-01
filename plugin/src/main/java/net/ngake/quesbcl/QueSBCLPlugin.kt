/* QueSBCLPlugin.kt 11 Mar 25 JDP QueSBCL */

package net.ngake.quesbcl

import android.util.Log
import java.io.File
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class QueSBCLPlugin(godot: Godot): GodotPlugin(godot) {

    companion object {
        val TAG = QueSBCLPlugin::class.java.simpleName

        init {
            try {
                Log.i(TAG, "Loading ${BuildConfig.GODOT_PLUGIN_NAME} library.")
                /* Loads libQueSBCL.so. */
                System.loadLibrary(BuildConfig.GODOT_PLUGIN_NAME)
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Error - unable to load ${BuildConfig.GODOT_PLUGIN_NAME} library!")
            }
        }
    }

    private val pluginSignalInfo = SignalInfo("testSignal", String::class.java)

    override fun getPluginName() = BuildConfig.GODOT_PLUGIN_NAME

    override fun getPluginGDExtensionLibrariesPaths() = setOf("res://addons/${BuildConfig.GODOT_PLUGIN_NAME}/plugin.gdextension")

    /**
     * Example showing how to declare a native method that uses GDExtension C++ bindings and is
     * exposed to gdscript.
     *
     * Print a 'Hello World' message to the logcat.
     */
    @UsedByGodot
    external fun helloWorld()

    external fun initialiseLisp(corePath: String): Int

    @UsedByGodot
    external fun helloLisp(): String

    /**
     * Ref: https://youtu.be/NWxA8Dx_6eo
     */
    override fun getPluginSignals(): Set<SignalInfo> {
        /*val signals: MutableSet<SignalInfo> = mutableSetOf()
        signals.add(SignalInfo("testSignal", String::class.java))
        return signals*/
        Log.i(TAG, "getPluginSignals(): Registering $pluginSignalInfo.")
        return setOf(pluginSignalInfo)
    }

    private fun checkDirForCore(dir: String): String? {
        val libPath = dir + "/libcore.so"

        return if (File(libPath).exists()) libPath else null
    }

    private fun tryCoreDir(dir: String): Int? {
        val libPath = checkDirForCore(dir)

        if (libPath != null) {
            Log.i(TAG, "tryCoreDir(): libcore.so found in $dir.")

            val result = initialiseLisp(libPath)

            Log.i(TAG, "tryCoreDir(): initialiseLisp() returned $result.")

            return result
        }
        else {
            Log.i(TAG, "tryCoreDir(): No core found in $dir.")

            return null
        }
    }

    @UsedByGodot
    private fun setupLisp(): String {
        var result = tryCoreDir(context.applicationInfo.nativeLibraryDir)

        if (result != null) return "$result found ${context.applicationInfo.nativeLibraryDir}"

        val sourceDir = context.applicationInfo.sourceDir + "!/lib/arm64-v8a"

        result = tryCoreDir(sourceDir)

        if (result != null) return "$result found $sourceDir"

        return "-1 not-found $sourceDir"

        /*
        val corePath = context.applicationInfo.nativeLibraryDir + "/libcore.so"
        val file = File(corePath)
        var result = -1
        var foundP = "not-found"

        if (file.exists()) {
            Log.i(TAG, "setupLisp(): Initialising SBCL with '$corePath'...")
            result = initialiseLisp(corePath)
            foundP = "found"
        }
        else {
            Log.e(TAG, "setupLisp(): Error - libcore.so not found at '$corePath'.")
            val directory = File(context.applicationInfo.nativeLibraryDir)
            val files = directory.listFiles()
            if (files != null) {
                Log.i(TAG, "setupLisp(): ${files.size} file(s) found in ${context.applicationInfo.nativeLibraryDir}.")
            }
            else {
                Log.i(TAG, "setupLisp(): Null files? !")
            }
            directory.listFiles()?.forEach {
                Log.i(TAG, "setupLisp(): ", it.name as Throwable?)
            }
        }

        return result.toString() + " " + foundP + " " + corePath
         */
    }

    @UsedByGodot
    private fun helloWorldSignal(name: String) {
        godot.getActivity()?.runOnUiThread {
            emitSignal("testSignal", "Hello $name")
        }
    }
}

/*** End of QueSBCLPlugin.kt ***/

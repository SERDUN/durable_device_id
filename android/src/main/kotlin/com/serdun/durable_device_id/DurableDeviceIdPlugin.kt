package com.serdun.durable_device_id

import android.content.Context
import android.provider.Settings

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

import java.security.MessageDigest

class DurableDeviceIdPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private companion object {
        const val METHOD_CHANNEL_NAME = "durable_device_id"
        const val METHOD_READ = "read"
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == METHOD_READ) {
            result.success(deviceId())
        } else {
            result.notImplemented()
        }
    }

    private fun deviceId(): String? {
        val androidId = try {
            Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
        } catch (e: Exception) {
            null
        }
        if (androidId.isNullOrBlank()) return null

        return DeviceIdDigest.of(context.packageName, androidId)
    }
}

/**
 * The identifier handed to Dart: a digest, so the system value itself never leaves the device.
 *
 * The package name is part of it because below Android 8 ANDROID_ID is one value for every
 * app on the device; from Android 8 on it already differs per signing key.
 */
internal object DeviceIdDigest {
    fun of(packageName: String, androidId: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest("$packageName:$androidId".toByteArray(Charsets.UTF_8))
        return digest.joinToString("") { "%02x".format(it) }
    }
}

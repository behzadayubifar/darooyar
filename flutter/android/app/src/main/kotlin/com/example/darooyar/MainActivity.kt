package com.example.darooyar

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.darooyar/stylus"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        
        // Create a method channel to handle stylus-related methods
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "disableStylusHandwriting" -> {
                    // Just return success - the actual disabling is handled by our custom view
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Disable stylus handwriting in the system properties
        try {
            System.setProperty("flutter.disableStylusHandwriting", "true")
        } catch (e: Exception) {
            // Ignore any errors
        }
    }
}

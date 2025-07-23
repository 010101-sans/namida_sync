package com.sanskar.namidasync

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sanskar.namidasync/intent"
    private var methodChannel: MethodChannel? = null
    private var cachedIntent: Intent? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        // If there was a cached intent, handle it now
        cachedIntent?.let {
            handleIntent(it)
            cachedIntent = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        // 1. Try to get from intent extras
        var backupPath = intent.getStringExtra("backupPath")
        var musicFoldersStr = intent.getStringExtra("musicFolders")
        Log.d("NamidaSync", "Intent data: ${intent.data}")
        // 2. If not present, try to get from URI
        intent.data?.let { uri ->
            if (backupPath == null) backupPath = uri.getQueryParameter("backupPath")
            if (musicFoldersStr == null) musicFoldersStr = uri.getQueryParameter("musicFolders")
        }
        Log.d("NamidaSync", "backupPath: $backupPath")
        Log.d("NamidaSync", "musicFoldersStr: $musicFoldersStr")
        val musicFoldersList = java.util.ArrayList(
            musicFoldersStr?.split(',')?.map { it.trim() }?.filter { it.isNotEmpty() } ?: emptyList()
        )
        Log.d("NamidaSync", "Parsed musicFoldersList: $musicFoldersList")
        if (methodChannel == null) {
            // Flutter is not ready yet, cache the intent
            cachedIntent = intent
            Log.d("NamidaSync", "Flutter not ready, caching intent")
            return
        }
        methodChannel?.invokeMethod(
            "onIntentReceived",
            mapOf(
                "backupPath" to backupPath,
                "musicFolders" to musicFoldersList
            )
        )
    }
}
package io.github.codebyarnob.nexora_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val SERVICE_CHANNEL = "io.github.codebyarnob.nexora/foreground_service"
    private val SHARE_CHANNEL = "io.github.codebyarnob.nexora/share_intent"

    private var initialSharedUris: ArrayList<String>? = null
    private var shareMethodChannel: MethodChannel? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        acquireLocks()
        handleIntent(intent)
    }

    private fun acquireLocks() {
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            if (wifi != null) {
                multicastLock = wifi.createMulticastLock("NexoraMulticastLock").apply {
                    setReferenceCounted(true)
                    acquire()
                }
                @Suppress("DEPRECATION")
                wifiLock = wifi.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "NexoraWifiLock").apply {
                    setReferenceCounted(false)
                    acquire()
                }
            }
        } catch (_: Exception) {
            // Non-critical if lock acquisition is restricted
        }
    }

    override fun onDestroy() {
        try {
            multicastLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
            wifiLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        initialSharedUris?.let { uris ->
            shareMethodChannel?.invokeMethod("onFilesShared", uris)
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            if (uri != null) {
                initialSharedUris = arrayListOf(uri.toString())
            }
        } else if (Intent.ACTION_SEND_MULTIPLE == action && type != null) {
            val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            if (uris != null) {
                initialSharedUris = ArrayList(uris.map { it.toString() })
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Native Foreground Service Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val fileName = call.argument<String>("fileName") ?: "File"
                    val isSending = call.argument<Boolean>("isSending") ?: true
                    NexoraTransferService.startService(applicationContext, fileName, isSending)
                    result.success(true)
                }
                "updateProgress" -> {
                    val fileName = call.argument<String>("fileName") ?: "File"
                    val progress = call.argument<Int>("progress") ?: 0
                    val speed = call.argument<String>("speed") ?: ""
                    NexoraTransferService.updateProgress(applicationContext, fileName, progress, speed)
                    result.success(true)
                }
                "stopService" -> {
                    NexoraTransferService.stopService(applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Share Intent Channel
        shareMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialSharedFiles") {
                    result.success(initialSharedUris)
                    initialSharedUris = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }
}

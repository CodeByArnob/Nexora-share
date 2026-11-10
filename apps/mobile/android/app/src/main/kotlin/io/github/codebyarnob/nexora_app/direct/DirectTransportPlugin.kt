package io.github.codebyarnob.nexora_app.direct

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class DirectTransportPlugin(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "io.github.codebyarnob.nexora/direct_transport"
        const val EVENT_CHANNEL = "io.github.codebyarnob.nexora/direct_transport_events"
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val wifiDirectManager = WifiDirectManager(context)
    private val wifiAwareManager = WifiAwareTransportManager(context)
    private val bleDiscoveryManager = BleDiscoveryManager(context)

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)

        // Wire up Wi-Fi Direct events
        wifiDirectManager.onPeersChangedListener = { peers ->
            sendEvent(mapOf("eventType" to "peersChanged", "peers" to peers))
        }

        wifiDirectManager.onConnectionChangedListener = { info ->
            sendEvent(mapOf("eventType" to "connectionChanged", "connection" to info))
        }

        wifiDirectManager.onStateChangedListener = { enabled ->
            sendEvent(mapOf("eventType" to "p2pStateChanged", "enabled" to enabled))
        }

        // Wire up Wi-Fi Aware events
        wifiAwareManager.onAvailabilityChangedListener = { available ->
            sendEvent(mapOf("eventType" to "awareAvailabilityChanged", "available" to available))
        }

        // Wire up BLE events
        bleDiscoveryManager.onPeerDiscoveredListener = { peer ->
            sendEvent(mapOf("eventType" to "blePeerDiscovered", "peer" to peer))
        }
    }

    private fun sendEvent(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        wifiDirectManager.register()
        wifiAwareManager.register()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        wifiDirectManager.unregister()
        wifiAwareManager.unregister()
        bleDiscoveryManager.stop()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> {
                val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                val isWifiEnabled = wifiManager?.isWifiEnabled == true

                val capabilities = mapOf(
                    "wifiDirectSupported" to wifiDirectManager.isSupported(),
                    "wifiAwareSupported" to wifiAwareManager.isSupported(),
                    "bleSupported" to bleDiscoveryManager.isSupported(),
                    "isWifiEnabled" to isWifiEnabled,
                    "isBleEnabled" to bleDiscoveryManager.isBluetoothEnabled(),
                    "isAwareAvailable" to wifiAwareManager.isAwareAvailable,
                    "sdkInt" to Build.VERSION.SDK_INT
                )
                result.success(capabilities)
            }

            "startWifiDirectDiscovery" -> {
                wifiDirectManager.startDiscovery(
                    onSuccess = { result.success(true) },
                    onError = { err -> result.error("P2P_DISCOVERY_ERROR", err, null) }
                )
            }

            "stopWifiDirectDiscovery" -> {
                wifiDirectManager.stopDiscovery(
                    onSuccess = { result.success(true) },
                    onError = { err -> result.error("P2P_STOP_ERROR", err, null) }
                )
            }

            "createWifiDirectGroup" -> {
                wifiDirectManager.createAutonomousGroup(
                    onSuccess = { groupInfo -> result.success(groupInfo) },
                    onError = { err -> result.error("P2P_CREATE_GROUP_ERROR", err, null) }
                )
            }

            "removeWifiDirectGroup" -> {
                wifiDirectManager.removeGroup(
                    onSuccess = { result.success(true) },
                    onError = { err -> result.error("P2P_REMOVE_GROUP_ERROR", err, null) }
                )
            }

            "connectWifiDirect" -> {
                val deviceAddress = call.argument<String>("deviceAddress")
                if (deviceAddress != null) {
                    wifiDirectManager.connect(
                        deviceAddress = deviceAddress,
                        onSuccess = { result.success(true) },
                        onError = { err -> result.error("P2P_CONNECT_ERROR", err, null) }
                    )
                } else {
                    result.error("INVALID_ARG", "deviceAddress cannot be null", null)
                }
            }

            "cancelConnectWifiDirect" -> {
                wifiDirectManager.cancelConnect(
                    onSuccess = { result.success(true) },
                    onError = { err -> result.error("P2P_CANCEL_CONNECT_ERROR", err, null) }
                )
            }

            "getWifiDirectConnectionInfo" -> {
                wifiDirectManager.getConnectionInfoSync { info ->
                    result.success(info)
                }
            }

            "startBleAdvertising" -> {
                val deviceId = call.argument<String>("deviceId") ?: "nexora-unknown"
                val displayName = call.argument<String>("displayName") ?: "NEXORA Peer"
                val wifiDirectMac = call.argument<String>("wifiDirectMac")

                bleDiscoveryManager.startAdvertising(
                    deviceId = deviceId,
                    displayName = displayName,
                    wifiDirectMac = wifiDirectMac,
                    onSuccess = { result.success(true) },
                    onError = { err -> result.error("BLE_ADVERTISE_ERROR", err, null) }
                )
            }

            "stopBleAdvertising" -> {
                bleDiscoveryManager.stopAdvertising()
                result.success(true)
            }

            "startBleScanning" -> {
                bleDiscoveryManager.startScanning(
                    onSuccess = { result.success(true) },
                    onError = { err -> result.error("BLE_SCAN_ERROR", err, null) }
                )
            }

            "stopBleScanning" -> {
                bleDiscoveryManager.stopScanning()
                result.success(true)
            }

            "getFreeDiskSpace" -> {
                val path = call.argument<String>("path")
                val dir = if (path != null) File(path) else Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                try {
                    val stat = StatFs(dir.absolutePath)
                    val availableBytes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                        stat.availableBytes
                    } else {
                        @Suppress("DEPRECATION")
                        stat.availableBlocks.toLong() * stat.blockSize.toLong()
                    }
                    result.success(availableBytes)
                } catch (e: Exception) {
                    result.error("STAT_ERROR", "Failed to check free disk space: ${e.message}", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    fun destroy() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        wifiDirectManager.unregister()
        wifiAwareManager.unregister()
        bleDiscoveryManager.stop()
    }
}

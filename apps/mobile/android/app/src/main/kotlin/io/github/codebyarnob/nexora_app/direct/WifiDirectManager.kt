package io.github.codebyarnob.nexora_app.direct

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.NetworkInfo
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pGroup
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.Looper
import android.util.Log

class WifiDirectManager(private val context: Context) {

    companion object {
        private const val TAG = "WifiDirectManager"
    }

    private var manager: WifiP2pManager? = null
    private var channel: WifiP2pManager.Channel? = null
    private var receiver: BroadcastReceiver? = null
    private var isReceiverRegistered = false

    var isP2pEnabled: Boolean = false
        private set

    var onPeersChangedListener: ((List<Map<String, Any?>>) -> Unit)? = null
    var onConnectionChangedListener: ((Map<String, Any?>) -> Unit)? = null
    var onStateChangedListener: ((Boolean) -> Unit)? = null

    init {
        manager = context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
        channel = manager?.initialize(context, Looper.getMainLooper()) {
            Log.w(TAG, "Wi-Fi Direct channel disconnected. Reinitializing...")
            channel = manager?.initialize(context, Looper.getMainLooper(), null)
        }
    }

    fun isSupported(): Boolean {
        return manager != null && channel != null
    }

    fun register() {
        if (isReceiverRegistered || manager == null || channel == null) return

        val intentFilter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }

        receiver = object : BroadcastReceiver() {
            @SuppressLint("MissingPermission")
            override fun onReceive(ctx: Context?, intent: Intent?) {
                when (intent?.action) {
                    WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                        val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                        isP2pEnabled = (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED)
                        onStateChangedListener?.invoke(isP2pEnabled)
                    }

                    WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                        requestPeers()
                    }

                    WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                        requestConnectionInfo()
                    }

                    WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                        // Local device Wi-Fi Direct details updated
                    }
                }
            }
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(receiver, intentFilter, Context.RECEIVER_EXPORTED)
            } else {
                context.registerReceiver(receiver, intentFilter)
            }
            isReceiverRegistered = true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register Wi-Fi Direct receiver: ${e.message}")
        }
    }

    fun unregister() {
        if (isReceiverRegistered && receiver != null) {
            try {
                context.unregisterReceiver(receiver)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to unregister receiver: ${e.message}")
            }
            isReceiverRegistered = false
            receiver = null
        }
    }

    @SuppressLint("MissingPermission")
    fun startDiscovery(onSuccess: () -> Unit, onError: (String) -> Unit) {
        val mgr = manager ?: return onError("WifiP2pManager unavailable")
        val ch = channel ?: return onError("WifiP2p Channel unavailable")

        register()

        mgr.discoverPeers(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                onSuccess()
            }

            override fun onFailure(reasonCode: Int) {
                onError("Failed to start peer discovery (Code: $reasonCode)")
            }
        })
    }

    fun stopDiscovery(onSuccess: () -> Unit, onError: (String) -> Unit) {
        val mgr = manager ?: return onSuccess()
        val ch = channel ?: return onSuccess()

        mgr.stopPeerDiscovery(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                onSuccess()
            }

            override fun onFailure(reasonCode: Int) {
                // Non-critical if discovery already stopped
                onSuccess()
            }
        })
    }

    @SuppressLint("MissingPermission")
    fun requestPeers() {
        val mgr = manager ?: return
        val ch = channel ?: return

        mgr.requestPeers(ch) { peers: WifiP2pDeviceList? ->
            val peerList = mutableListOf<Map<String, Any?>>()
            peers?.deviceList?.forEach { device ->
                peerList.add(
                    mapOf(
                        "deviceName" to device.deviceName,
                        "deviceAddress" to device.deviceAddress,
                        "primaryDeviceType" to device.primaryDeviceType,
                        "status" to device.status,
                        "isGroupOwner" to device.isGroupOwner
                    )
                )
            }
            onPeersChangedListener?.invoke(peerList)
        }
    }

    @SuppressLint("MissingPermission")
    fun createAutonomousGroup(onSuccess: (Map<String, Any?>) -> Unit, onError: (String) -> Unit) {
        val mgr = manager ?: return onError("WifiP2pManager unavailable")
        val ch = channel ?: return onError("WifiP2p Channel unavailable")

        register()

        mgr.createGroup(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                // Group creation succeeded, retrieve group credentials and connection info
                mgr.requestGroupInfo(ch) { group: WifiP2pGroup? ->
                    val result = mutableMapOf<String, Any?>(
                        "groupCreated" to true,
                        "networkName" to (group?.networkName ?: "NEXORA-DIRECT"),
                        "passphrase" to (group?.passphrase ?: ""),
                        "interface" to (group?.`interface` ?: "p2p0"),
                        "isGroupOwner" to (group?.isGroupOwner ?: true)
                    )
                    onSuccess(result)
                }
            }

            override fun onFailure(reasonCode: Int) {
                onError("Failed to create autonomous Wi-Fi Direct group (Code: $reasonCode)")
            }
        })
    }

    fun removeGroup(onSuccess: () -> Unit, onError: (String) -> Unit) {
        val mgr = manager ?: return onSuccess()
        val ch = channel ?: return onSuccess()

        mgr.removeGroup(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                onSuccess()
            }

            override fun onFailure(reasonCode: Int) {
                // Non-critical if group already removed
                onSuccess()
            }
        })
    }

    @SuppressLint("MissingPermission")
    fun connect(deviceAddress: String, onSuccess: () -> Unit, onError: (String) -> Unit) {
        val mgr = manager ?: return onError("WifiP2pManager unavailable")
        val ch = channel ?: return onError("WifiP2p Channel unavailable")

        register()

        val config = WifiP2pConfig().apply {
            this.deviceAddress = deviceAddress
        }

        mgr.connect(ch, config, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                onSuccess()
            }

            override fun onFailure(reasonCode: Int) {
                onError("Failed to initiate connection to $deviceAddress (Code: $reasonCode)")
            }
        })
    }

    fun cancelConnect(onSuccess: () -> Unit, onError: (String) -> Unit) {
        val mgr = manager ?: return onSuccess()
        val ch = channel ?: return onSuccess()

        mgr.cancelConnect(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                onSuccess()
            }

            override fun onFailure(reasonCode: Int) {
                onSuccess()
            }
        })
    }

    fun requestConnectionInfo() {
        val mgr = manager ?: return
        val ch = channel ?: return

        mgr.requestConnectionInfo(ch) { info: WifiP2pInfo? ->
            if (info != null) {
                val groupOwnerAddress = info.groupOwnerAddress?.hostAddress
                val map = mapOf(
                    "groupFormed" to info.groupFormed,
                    "isGroupOwner" to info.isGroupOwner,
                    "groupOwnerAddress" to groupOwnerAddress
                )
                onConnectionChangedListener?.invoke(map)
            }
        }
    }

    fun getConnectionInfoSync(callback: (Map<String, Any?>) -> Unit) {
        val mgr = manager ?: return callback(emptyMap())
        val ch = channel ?: return callback(emptyMap())

        mgr.requestConnectionInfo(ch) { info: WifiP2pInfo? ->
            if (info != null) {
                val groupOwnerAddress = info.groupOwnerAddress?.hostAddress
                callback(
                    mapOf(
                        "groupFormed" to info.groupFormed,
                        "isGroupOwner" to info.isGroupOwner,
                        "groupOwnerAddress" to groupOwnerAddress
                    )
                )
            } else {
                callback(emptyMap())
            }
        }
    }
}

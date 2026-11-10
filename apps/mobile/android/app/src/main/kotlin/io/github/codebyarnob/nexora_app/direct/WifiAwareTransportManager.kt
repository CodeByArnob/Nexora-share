package io.github.codebyarnob.nexora_app.direct

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.aware.WifiAwareManager
import android.os.Build
import android.util.Log

class WifiAwareTransportManager(private val context: Context) {

    companion object {
        private const val TAG = "WifiAwareTransport"
    }

    private var awareManager: WifiAwareManager? = null
    private var availabilityReceiver: BroadcastReceiver? = null
    private var isReceiverRegistered = false

    var isAwareAvailable: Boolean = false
        private set

    var onAvailabilityChangedListener: ((Boolean) -> Unit)? = null

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE)) {
                awareManager = context.getSystemService(Context.WIFI_AWARE_SERVICE) as? WifiAwareManager
                isAwareAvailable = awareManager?.isAvailable == true
            }
        }
    }

    fun isSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE) &&
                awareManager != null
    }

    fun register() {
        if (isReceiverRegistered || !isSupported()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val filter = IntentFilter(WifiAwareManager.ACTION_WIFI_AWARE_STATE_CHANGED)
            availabilityReceiver = object : BroadcastReceiver() {
                override fun onReceive(ctx: Context?, intent: Intent?) {
                    isAwareAvailable = awareManager?.isAvailable == true
                    onAvailabilityChangedListener?.invoke(isAwareAvailable)
                }
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.registerReceiver(availabilityReceiver, filter, Context.RECEIVER_EXPORTED)
                } else {
                    context.registerReceiver(availabilityReceiver, filter)
                }
                isReceiverRegistered = true
            } catch (e: Exception) {
                Log.w(TAG, "Failed to register Wi-Fi Aware state receiver: ${e.message}")
            }
        }
    }

    fun unregister() {
        if (isReceiverRegistered && availabilityReceiver != null) {
            try {
                context.unregisterReceiver(availabilityReceiver)
            } catch (_: Exception) {}
            isReceiverRegistered = false
            availabilityReceiver = null
        }
    }
}

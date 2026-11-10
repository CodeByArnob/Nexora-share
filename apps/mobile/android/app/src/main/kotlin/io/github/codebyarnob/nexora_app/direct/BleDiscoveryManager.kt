package io.github.codebyarnob.nexora_app.direct

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import java.nio.charset.StandardCharsets
import java.util.UUID

class BleDiscoveryManager(private val context: Context) {

    companion object {
        private const val TAG = "BleDiscoveryManager"
        // 128-bit NEXORA Service UUID for Low-Energy peer discovery
        val NEXORA_SERVICE_UUID: UUID = UUID.fromString("00004884-0000-1000-8000-00805f9b34fb")
    }

    private var bluetoothManager: BluetoothManager? = null
    private var adapter: BluetoothAdapter? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var scanner: BluetoothLeScanner? = null

    private var isAdvertising = false
    private var isScanning = false

    private var advertiseCallback: AdvertiseCallback? = null
    private var scanCallback: ScanCallback? = null

    var onPeerDiscoveredListener: ((Map<String, Any?>) -> Unit)? = null

    init {
        if (context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            adapter = bluetoothManager?.adapter
        }
    }

    fun isSupported(): Boolean {
        return context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE) &&
                adapter != null
    }

    fun isBluetoothEnabled(): Boolean {
        return adapter?.isEnabled == true
    }

    @SuppressLint("MissingPermission")
    fun startAdvertising(
        deviceId: String,
        displayName: String,
        wifiDirectMac: String?,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        if (!isSupported()) return onError("BLE not supported on this device")
        if (!isBluetoothEnabled()) return onError("Bluetooth is disabled")

        advertiser = adapter?.bluetoothLeAdvertiser
        if (advertiser == null) return onError("BLE Advertiser is unavailable")

        if (isAdvertising) {
            stopAdvertising()
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .setTimeout(0)
            .build()

        // Compact discovery payload: [macLength(1)][macBytes][idLength(1)][idBytes][nameBytes]
        val macBytes = (wifiDirectMac ?: "").toByteArray(StandardCharsets.UTF_8)
        val idBytes = deviceId.toByteArray(StandardCharsets.UTF_8)
        val nameBytes = displayName.toByteArray(StandardCharsets.UTF_8)

        // Keep payload under 24 bytes for BLE advertisement compatibility
        val truncatedName = if (nameBytes.size > 10) nameBytes.copyOfRange(0, 10) else nameBytes
        val truncatedId = if (idBytes.size > 12) idBytes.copyOfRange(0, 12) else idBytes

        val serviceData = ByteArray(1 + macBytes.size + 1 + truncatedId.size + truncatedName.size)
        var pos = 0
        serviceData[pos++] = macBytes.size.toByte()
        System.arraycopy(macBytes, 0, serviceData, pos, macBytes.size)
        pos += macBytes.size

        serviceData[pos++] = truncatedId.size.toByte()
        System.arraycopy(truncatedId, 0, serviceData, pos, truncatedId.size)
        pos += truncatedId.size

        System.arraycopy(truncatedName, 0, serviceData, pos, truncatedName.size)

        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(NEXORA_SERVICE_UUID))
            .addServiceData(ParcelUuid(NEXORA_SERVICE_UUID), serviceData)
            .setIncludeDeviceName(false)
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                isAdvertising = true
                onSuccess()
            }

            override fun onStartFailure(errorCode: Int) {
                isAdvertising = false
                onError("BLE Advertise failed with code $errorCode")
            }
        }

        try {
            advertiser?.startAdvertising(settings, data, advertiseCallback)
        } catch (e: Exception) {
            onError("BLE Advertise exception: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun stopAdvertising() {
        if (isAdvertising && advertiser != null && advertiseCallback != null) {
            try {
                advertiser?.stopAdvertising(advertiseCallback)
            } catch (e: Exception) {
                Log.w(TAG, "Error stopping BLE advertiser: ${e.message}")
            }
            isAdvertising = false
            advertiseCallback = null
        }
    }

    @SuppressLint("MissingPermission")
    fun startScanning(onSuccess: () -> Unit, onError: (String) -> Unit) {
        if (!isSupported()) return onError("BLE not supported")
        if (!isBluetoothEnabled()) return onError("Bluetooth is disabled")

        scanner = adapter?.bluetoothLeScanner
        if (scanner == null) return onError("BLE Scanner is unavailable")

        if (isScanning) {
            stopScanning()
        }

        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(NEXORA_SERVICE_UUID))
            .build()

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult?) {
                result ?: return
                val scanRecord = result.scanRecord ?: return
                val serviceData = scanRecord.getServiceData(ParcelUuid(NEXORA_SERVICE_UUID)) ?: return

                try {
                    var pos = 0
                    if (serviceData.isEmpty()) return
                    val macLen = serviceData[pos++].toInt() and 0xFF
                    val mac = if (macLen > 0 && pos + macLen <= serviceData.size) {
                        val str = String(serviceData, pos, macLen, StandardCharsets.UTF_8)
                        pos += macLen
                        str
                    } else ""

                    val idLen = if (pos < serviceData.size) serviceData[pos++].toInt() and 0xFF else 0
                    val devId = if (idLen > 0 && pos + idLen <= serviceData.size) {
                        val str = String(serviceData, pos, idLen, StandardCharsets.UTF_8)
                        pos += idLen
                        str
                    } else result.device.address ?: "unknown-ble"

                    val nameLen = serviceData.size - pos
                    val devName = if (nameLen > 0) {
                        String(serviceData, pos, nameLen, StandardCharsets.UTF_8)
                    } else result.device.name ?: "Nearby BLE Peer"

                    val peerMap = mapOf<String, Any?>(
                        "deviceId" to devId,
                        "displayName" to devName,
                        "wifiDirectMac" to (if (mac.isNotEmpty()) mac else null),
                        "bluetoothAddress" to result.device.address,
                        "rssi" to result.rssi
                    )
                    onPeerDiscoveredListener?.invoke(peerMap)
                } catch (e: Exception) {
                    Log.w(TAG, "Error parsing BLE scan payload: ${e.message}")
                }
            }

            override fun onScanFailed(errorCode: Int) {
                isScanning = false
                Log.w(TAG, "BLE scan failed with code: $errorCode")
            }
        }

        try {
            scanner?.startScan(listOf(filter), settings, scanCallback)
            isScanning = true
            onSuccess()
        } catch (e: Exception) {
            onError("BLE Scan exception: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun stopScanning() {
        if (isScanning && scanner != null && scanCallback != null) {
            try {
                scanner?.stopScan(scanCallback)
            } catch (e: Exception) {
                Log.w(TAG, "Error stopping BLE scan: ${e.message}")
            }
            isScanning = false
            scanCallback = null
        }
    }

    fun stop() {
        stopAdvertising()
        stopScanning()
    }
}

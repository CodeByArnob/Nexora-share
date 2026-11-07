package io.github.codebyarnob.nexora_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class NexoraTransferService : Service() {

    companion object {
        const val CHANNEL_ID = "nexora_active_transfers"
        const val NOTIFICATION_ID = 48842

        const val ACTION_START = "ACTION_START_TRANSFER"
        const val ACTION_UPDATE = "ACTION_UPDATE_PROGRESS"
        const val ACTION_STOP = "ACTION_STOP_TRANSFER"

        const val EXTRA_FILE_NAME = "EXTRA_FILE_NAME"
        const val EXTRA_PROGRESS = "EXTRA_PROGRESS"
        const val EXTRA_SPEED = "EXTRA_SPEED"
        const val EXTRA_IS_SENDING = "EXTRA_IS_SENDING"

        fun startService(
            context: Context,
            fileName: String,
            isSending: Boolean
        ) {
            val intent = Intent(context, NexoraTransferService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_FILE_NAME, fileName)
                putExtra(EXTRA_IS_SENDING, isSending)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun updateProgress(
            context: Context,
            fileName: String,
            progressPercent: Int,
            speed: String
        ) {
            val intent = Intent(context, NexoraTransferService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_FILE_NAME, fileName)
                putExtra(EXTRA_PROGRESS, progressPercent)
                putExtra(EXTRA_SPEED, speed)
            }
            context.startService(intent)
        }

        fun stopService(context: Context) {
            val intent = Intent(context, NexoraTransferService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val fileName = intent.getStringExtra(EXTRA_FILE_NAME) ?: "File"
                val isSending = intent.getBooleanExtra(EXTRA_IS_SENDING, true)
                val notification = buildNotification(
                    fileName = fileName,
                    statusText = if (isSending) "Sending file..." else "Receiving file...",
                    progress = 0
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            }
            ACTION_UPDATE -> {
                val fileName = intent.getStringExtra(EXTRA_FILE_NAME) ?: "File"
                val progress = intent.getIntExtra(EXTRA_PROGRESS, 0)
                val speed = intent.getStringExtra(EXTRA_SPEED) ?: ""
                val statusText = if (speed.isNotEmpty()) "$progress% • $speed" else "$progress%"
                val notification = buildNotification(fileName, statusText, progress)
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(fileName: String, statusText: String, progress: Int) =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NEXORA Transfer: $fileName")
            .setContentText(statusText)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setProgress(100, progress, false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(
                PendingIntent.getActivity(
                    this,
                    0,
                    Intent(this, MainActivity::class.java),
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
            )
            .build()

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Active File Transfers",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Displays progress for ongoing NEXORA peer-to-peer file transfers"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}

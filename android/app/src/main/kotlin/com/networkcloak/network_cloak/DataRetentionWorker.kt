package com.networkcloak.network_cloak

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import java.io.File

class DataRetentionWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    companion object {
        private const val TAG = "NC-RetentionWorker"
    }

    override suspend fun doWork(): Result {
        Log.i(TAG, "Data retention periodic cleanup job started")
        try {
            // Read retention days setting (default 30 days)
            val prefs = applicationContext.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
            val retentionDays = prefs.getInt("retentionDays", 30)
            Log.i(TAG, "Configured retention window: $retentionDays days")

            // Locate database file
            val filesDirDb = File(applicationContext.filesDir, "network_cloak.sqlite")
            val noBackupDb = File(applicationContext.noBackupFilesDir, "network_cloak.sqlite")
            val dbFile = when {
                filesDirDb.exists() -> filesDirDb
                noBackupDb.exists() -> noBackupDb
                else -> {
                    // Fall back to getDatabasePath if custom folder is not matching
                    val pathDb = applicationContext.getDatabasePath("network_cloak.sqlite")
                    if (pathDb.exists()) pathDb else null
                }
            }

            if (dbFile == null) {
                Log.w(TAG, "Database file not found — skipping cleanup")
                return Result.success()
            }

            Log.i(TAG, "Cleaning up database at path: ${dbFile.absolutePath}")
            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)

            val cutoffMs = System.currentTimeMillis() - (retentionDays * 24L * 60L * 60L * 1000L)

            db.beginTransaction()
            try {
                // Delete connection history rows older than cutoff
                val deletedHistory = db.delete("connection_history", "timestamp < ?", arrayOf(cutoffMs.toString()))
                // Delete alerts rows older than cutoff
                val deletedAlerts = db.delete("alerts", "created_at < ?", arrayOf(cutoffMs.toString()))
                // Delete dns logs rows older than cutoff
                val deletedDns = db.delete("dns_logs", "timestamp < ?", arrayOf(cutoffMs.toString()))

                db.setTransactionSuccessful()
                Log.i(TAG, "Cleanup finished: deleted $deletedHistory history logs, $deletedAlerts alerts, $deletedDns DNS logs")
            } finally {
                db.endTransaction()
                db.close()
            }

            return Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Data retention worker failed: ${e.message}", e)
            return Result.failure()
        }
    }
}

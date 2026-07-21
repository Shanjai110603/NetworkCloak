package com.networkcloak.network_cloak

import android.content.Context
import android.content.pm.PackageManager
import android.util.LruCache

/**
 * Maps Linux UIDs (from /proc/net/tcp) to app package IDs.
 * Results are cached in an LruCache to avoid repeated PackageManager calls.
 */
object UidMapper {
    private val cache = LruCache<Int, String>(512)

    fun getAppId(context: Context, uid: Int): String {
        if (uid < 0) return "unknown"
        cache.get(uid)?.let { return it }

        val pm = context.packageManager
        val packages = pm.getPackagesForUid(uid)
        val appId = packages?.firstOrNull() ?: "uid.$uid"
        cache.put(uid, appId)
        return appId
    }

    fun clearCache() = cache.evictAll()
}

/**
 * Tracks which apps are currently in the foreground vs background.
 * Updated in real-time by ActivityManager.OnUidImportanceListener.
 */
object AppStateTracker {
    private val backgroundUids = HashSet<Int>()
    @Volatile private var listenerRegistered = false

    fun isBackground(uid: Int): Boolean = synchronized(backgroundUids) {
        backgroundUids.contains(uid)
    }

    fun setBackground(uid: Int) = synchronized(backgroundUids) {
        backgroundUids.add(uid)
    }

    fun setForeground(uid: Int) = synchronized(backgroundUids) {
        backgroundUids.remove(uid)
    }

    /**
     * Registers ActivityManager.OnUidImportanceListener dynamically via reflection
     * on Android 8.0+ (API 26+) to monitor real-time app process importance transitions.
     */
    fun startMonitoring(context: Context, onImportanceChanged: (() -> Unit)? = null) {
        if (listenerRegistered) return
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            try {
                val am = context.applicationContext.getSystemService(Context.ACTIVITY_SERVICE) as? android.app.ActivityManager
                val listenerClass = Class.forName("android.app.ActivityManager\$OnUidImportanceListener")
                val proxy = java.lang.reflect.Proxy.newProxyInstance(
                    listenerClass.classLoader,
                    arrayOf(listenerClass)
                ) { _, method, args ->
                    if (method.name == "onUidImportance" && args != null && args.size >= 2) {
                        val uid = args[0] as? Int ?: return@newProxyInstance null
                        val importance = args[1] as? Int ?: return@newProxyInstance null
                        val isBg = importance > android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND_SERVICE
                        val changed = synchronized(backgroundUids) {
                            if (isBg) backgroundUids.add(uid) else backgroundUids.remove(uid)
                        }
                        if (changed) {
                            onImportanceChanged?.invoke()
                        }
                    }
                    null
                }
                val addMethod = am?.javaClass?.getMethod(
                    "addOnUidImportanceListener",
                    listenerClass,
                    Int::class.javaPrimitiveType
                )
                addMethod?.invoke(am, proxy, android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND)
                listenerRegistered = true
            } catch (e: Throwable) {
                android.util.Log.w("NC-AppState", "OnUidImportanceListener setup skipped: ${e.message}")
            }
        }
    }
}

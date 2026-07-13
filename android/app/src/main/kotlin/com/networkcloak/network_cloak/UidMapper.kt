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
 * Updated by the ActivityManager usage stats query on each network change.
 */
object AppStateTracker {
    private val backgroundUids = HashSet<Int>()

    fun isBackground(uid: Int): Boolean = synchronized(backgroundUids) {
        backgroundUids.contains(uid)
    }

    fun setBackground(uid: Int) = synchronized(backgroundUids) {
        backgroundUids.add(uid)
    }

    fun setForeground(uid: Int) = synchronized(backgroundUids) {
        backgroundUids.remove(uid)
    }
}

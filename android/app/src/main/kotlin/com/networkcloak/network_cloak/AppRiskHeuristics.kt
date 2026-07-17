package com.networkcloak.network_cloak

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

object AppRiskHeuristics {

    data class RiskReport(
        val score: Int,
        val level: String,
        val reasons: List<String>
    )

    fun evaluate(context: Context, appInfo: ApplicationInfo): RiskReport {
        var score = 0
        val reasons = mutableListOf<String>()

        // 1. Check if application is debuggable
        if ((appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            score += 25
            reasons.add("Application has the debuggable flag enabled (vulnerable to reverse engineering)")
        }

        // 2. Query application permissions
        val pm = context.packageManager
        try {
            val pkgInfo = pm.getPackageInfo(appInfo.packageName, PackageManager.GET_PERMISSIONS)
            val permissions = pkgInfo.requestedPermissions

            if (permissions != null) {
                if (permissions.contains("android.permission.ACCESS_BACKGROUND_LOCATION")) {
                    score += 15
                    reasons.add("Requests silent background location access")
                }
                if (permissions.contains("android.permission.SYSTEM_ALERT_WINDOW")) {
                    score += 20
                    reasons.add("Requests overlay display permission (potential overlay/hijack vulnerability)")
                }
                if (permissions.contains("android.permission.READ_SMS") ||
                    permissions.contains("android.permission.RECEIVE_SMS") ||
                    permissions.contains("android.permission.SEND_SMS")
                ) {
                    score += 20
                    reasons.add("Requests permissions to read, receive, or send SMS messages")
                }
                if (permissions.contains("android.permission.INSTALL_PACKAGES") ||
                    permissions.contains("android.permission.REQUEST_INSTALL_PACKAGES")
                ) {
                    score += 20
                    reasons.add("Requests permissions to silently install packages")
                }
                if (permissions.contains("android.permission.READ_PHONE_STATE")) {
                    score += 10
                    reasons.add("Requests access to read sensitive device phone states")
                }
                if (permissions.contains("android.permission.PROCESS_OUTGOING_CALLS")) {
                    score += 15
                    reasons.add("Requests access to intercept outgoing phone calls")
                }
            }
        } catch (_: Exception) {
            // Fallback if package manager queries fail
        }

        // Resolve risk category level
        val level = when {
            score > 50  -> "high"
            score > 20  -> "medium"
            else        -> "low"
        }

        return RiskReport(score.coerceAtMost(100), level, reasons)
    }
}

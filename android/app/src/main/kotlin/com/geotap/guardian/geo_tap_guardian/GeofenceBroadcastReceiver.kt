package com.geotap.guardian.geo_tap_guardian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent) ?: return
        if (geofencingEvent.hasError()) {
            return
        }
        if (geofencingEvent.geofenceTransition != Geofence.GEOFENCE_TRANSITION_ENTER) {
            return
        }

        geofencingEvent.triggeringGeofences?.forEach { geofence ->
            val target = GeofenceTargetStore.findTarget(context, geofence.requestId)
            val event = mutableMapOf<String, Any?>(
                "targetId" to geofence.requestId,
                "schoolId" to target?.optString("schoolId"),
                "studentId" to target?.optString("studentId"),
                "guardianId" to target?.optString("guardianId"),
                "studentName" to target?.optString("studentName"),
                "pickupZone" to target?.optString("pickupZone"),
                "occurredAtEpochMs" to System.currentTimeMillis(),
                "isSimulated" to false,
            )
            DeviceEventSink.publishGeofenceEvent(event)
        }
    }
}

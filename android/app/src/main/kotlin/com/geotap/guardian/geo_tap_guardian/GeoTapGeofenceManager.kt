package com.geotap.guardian.geo_tap_guardian

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

class GeoTapGeofenceManager(
    private val context: Context,
) {
    private val geofencingClient = LocationServices.getGeofencingClient(context)

    fun getStatus(): Map<String, Any?> {
        val permissionGranted = hasLocationPermission()
        val locationServicesEnabled = isLocationServicesEnabled()
        val activeTargetCount = GeofenceTargetStore.countTargets(context)
        val detail = when {
            !permissionGranted ->
                "Android location permission is required before geofencing can mark approaching."
            !locationServicesEnabled ->
                "Location services are turned off on this device."
            activeTargetCount == 0 ->
                "No pickup geofence targets are currently registered."
            else ->
                "Android geofencing is monitoring $activeTargetCount configured target(s)."
        }

        return mapOf(
            "supported" to true,
            "permissionGranted" to permissionGranted,
            "locationServicesEnabled" to locationServicesEnabled,
            "activeTargetCount" to activeTargetCount,
            "detail" to detail,
        )
    }

    fun clearTargets(
        onSuccess: () -> Unit,
        onError: (String, String?) -> Unit,
    ) {
        GeofenceTargetStore.clear(context)
        geofencingClient
            .removeGeofences(geofencePendingIntent())
            .addOnSuccessListener { onSuccess() }
            .addOnFailureListener { error ->
                onError("clear_geofences_failed", error.localizedMessage)
            }
    }

    @SuppressLint("MissingPermission")
    fun registerTargets(
        targets: List<Map<String, Any?>>,
        onSuccess: () -> Unit,
        onError: (String, String?) -> Unit,
    ) {
        if (!hasLocationPermission()) {
            onError(
                "location_permission_missing",
                "Android location permission is required before geofencing can start.",
            )
            return
        }

        GeofenceTargetStore.saveTargets(context, targets)
        val geofences = targets.mapNotNull { target ->
            val id = target["id"] as? String ?: return@mapNotNull null
            val latitude = (target["latitude"] as? Number)?.toDouble() ?: return@mapNotNull null
            val longitude = (target["longitude"] as? Number)?.toDouble() ?: return@mapNotNull null
            val radiusMeters = (target["radiusMeters"] as? Number)?.toFloat() ?: 200f

            Geofence
                .Builder()
                .setRequestId(id)
                .setCircularRegion(latitude, longitude, radiusMeters)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .build()
        }

        val request = GeofencingRequest
            .Builder()
            .setInitialTrigger(0)
            .addGeofences(geofences)
            .build()

        geofencingClient
            .removeGeofences(geofencePendingIntent())
            .addOnCompleteListener {
                geofencingClient
                    .addGeofences(request, geofencePendingIntent())
                    .addOnSuccessListener { onSuccess() }
                    .addOnFailureListener { error ->
                        onError("register_geofences_failed", error.localizedMessage)
                    }
            }
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun isLocationServicesEnabled(): Boolean {
        val locationManager =
            context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
            locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    private fun geofencePendingIntent(): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, 4101, intent, flags)
    }
}

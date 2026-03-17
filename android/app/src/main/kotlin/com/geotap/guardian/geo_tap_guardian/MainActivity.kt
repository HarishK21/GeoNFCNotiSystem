package com.geotap.guardian.geo_tap_guardian

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var geofenceManager: GeoTapGeofenceManager
    private lateinit var nfcSessionManager: GeoTapNfcSessionManager
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        geofenceManager = GeoTapGeofenceManager(this)
        nfcSessionManager = GeoTapNfcSessionManager(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "geo_tap_guardian/geofencing/methods",
        ).setMethodCallHandler(::handleGeofencingMethodCall)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "geo_tap_guardian/geofencing/events",
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    DeviceEventSink.attachGeofenceSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    DeviceEventSink.attachGeofenceSink(null)
                }
            },
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "geo_tap_guardian/nfc/methods",
        ).setMethodCallHandler(::handleNfcMethodCall)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "geo_tap_guardian/nfc/events",
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    DeviceEventSink.attachNfcSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    DeviceEventSink.attachNfcSink(null)
                }
            },
        )
    }

    override fun onDestroy() {
        nfcSessionManager.stopSession()
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 4401) {
            return
        }

        val granted = grantResults.any { it == PackageManager.PERMISSION_GRANTED }
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    private fun handleGeofencingMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> result.success(geofenceManager.getStatus())
            "requestPermission" -> requestLocationPermission(result)
            "clearTargets" -> geofenceManager.clearTargets(
                onSuccess = { result.success(null) },
                onError = { code, message -> result.error(code, message, null) },
            )
            "simulateEnter" -> {
                val target = rawMap(call.arguments)
                DeviceEventSink.publishGeofenceEvent(
                    mutableMapOf<String, Any?>(
                        "targetId" to target["id"],
                        "schoolId" to target["schoolId"],
                        "studentId" to target["studentId"],
                        "guardianId" to target["guardianId"],
                        "studentName" to target["studentName"],
                        "pickupZone" to target["pickupZone"],
                        "occurredAtEpochMs" to System.currentTimeMillis(),
                        "isSimulated" to true,
                    ),
                )
                result.success(null)
            }
            "syncTargets" -> {
                @Suppress("UNCHECKED_CAST")
                val targets = (call.argument<List<Map<String, Any?>>>("targets") ?: emptyList())
                geofenceManager.registerTargets(
                    targets = targets,
                    onSuccess = { result.success(null) },
                    onError = { code, message -> result.error(code, message, null) },
                )
            }
            else -> result.notImplemented()
        }
    }

    private fun handleNfcMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> result.success(nfcSessionManager.getStatus())
            "startVerificationSession" -> {
                nfcSessionManager.startSession(rawMap(call.arguments))
                result.success(null)
            }
            "stopVerificationSession" -> {
                nfcSessionManager.stopSession()
                result.success(null)
            }
            "simulateScan" -> {
                nfcSessionManager.simulateScan(rawMap(call.arguments))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun requestLocationPermission(result: MethodChannel.Result) {
        val alreadyGranted =
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
        if (alreadyGranted) {
            result.success(true)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
            4401,
        )
    }

    private fun rawMap(arguments: Any?): Map<String, Any?> {
        @Suppress("UNCHECKED_CAST")
        return (arguments as? Map<String, Any?>) ?: emptyMap()
    }
}

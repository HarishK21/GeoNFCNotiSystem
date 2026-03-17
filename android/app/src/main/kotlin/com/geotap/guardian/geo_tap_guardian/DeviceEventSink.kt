package com.geotap.guardian.geo_tap_guardian

import io.flutter.plugin.common.EventChannel

object DeviceEventSink {
    private var geofenceSink: EventChannel.EventSink? = null
    private var nfcSink: EventChannel.EventSink? = null
    private val pendingGeofenceEvents = mutableListOf<Map<String, Any?>>()
    private val pendingNfcEvents = mutableListOf<Map<String, Any?>>()

    fun attachGeofenceSink(sink: EventChannel.EventSink?) {
        geofenceSink = sink
        flushPendingGeofenceEvents()
    }

    fun attachNfcSink(sink: EventChannel.EventSink?) {
        nfcSink = sink
        flushPendingNfcEvents()
    }

    fun publishGeofenceEvent(event: Map<String, Any?>) {
        val sink = geofenceSink
        if (sink != null) {
            sink.success(event)
            return
        }
        pendingGeofenceEvents.add(event)
    }

    fun publishNfcEvent(event: Map<String, Any?>) {
        val sink = nfcSink
        if (sink != null) {
            sink.success(event)
            return
        }
        pendingNfcEvents.add(event)
    }

    private fun flushPendingGeofenceEvents() {
        val sink = geofenceSink ?: return
        pendingGeofenceEvents.forEach { sink.success(it) }
        pendingGeofenceEvents.clear()
    }

    private fun flushPendingNfcEvents() {
        val sink = nfcSink ?: return
        pendingNfcEvents.forEach { sink.success(it) }
        pendingNfcEvents.clear()
    }
}

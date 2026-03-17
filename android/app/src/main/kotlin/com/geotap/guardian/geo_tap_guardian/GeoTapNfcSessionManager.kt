package com.geotap.guardian.geo_tap_guardian

import android.app.Activity
import android.nfc.NfcAdapter
import android.nfc.Tag

class GeoTapNfcSessionManager(
    private val activity: Activity,
) {
    private val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(activity)
    private var currentTarget: Map<String, Any?>? = null
    private var listening = false

    private val readerCallback = NfcAdapter.ReaderCallback { tag ->
        val target = currentTarget ?: return@ReaderCallback
        DeviceEventSink.publishNfcEvent(
            mutableMapOf<String, Any?>(
                "schoolId" to target["schoolId"],
                "studentId" to target["studentId"],
                "guardianId" to target["guardianId"],
                "studentName" to target["studentName"],
                "tagId" to tag.toHexId(),
                "occurredAtEpochMs" to System.currentTimeMillis(),
                "isSimulated" to false,
            ),
        )
        activity.runOnUiThread { stopSession() }
    }

    fun getStatus(): Map<String, Any?> {
        val detail = when {
            adapter == null ->
                "This Android device does not support NFC."
            !adapter.isEnabled ->
                "Enable NFC in Android settings before verifying a pickup on-site."
            listening ->
                "NFC reader mode is waiting for a tag scan."
            else ->
                "Arm a verification session for a student, then scan a tag on-site."
        }

        return mapOf(
            "supported" to (adapter != null),
            "enabled" to (adapter?.isEnabled == true),
            "listening" to listening,
            "targetStudentId" to currentTarget?.get("studentId"),
            "targetLabel" to currentTarget?.get("studentName"),
            "detail" to detail,
        )
    }

    fun simulateScan(target: Map<String, Any?>) {
        DeviceEventSink.publishNfcEvent(
            mutableMapOf<String, Any?>(
                "schoolId" to target["schoolId"],
                "studentId" to target["studentId"],
                "guardianId" to target["guardianId"],
                "studentName" to target["studentName"],
                "tagId" to "debug-simulated-tag",
                "occurredAtEpochMs" to System.currentTimeMillis(),
                "isSimulated" to true,
            ),
        )
        stopSession()
    }

    fun startSession(target: Map<String, Any?>) {
        currentTarget = target
        val nfcAdapter = adapter ?: return
        if (!nfcAdapter.isEnabled) {
            listening = false
            return
        }

        val flags = NfcAdapter.FLAG_READER_NFC_A or
            NfcAdapter.FLAG_READER_NFC_B or
            NfcAdapter.FLAG_READER_NFC_F or
            NfcAdapter.FLAG_READER_NFC_V or
            NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

        nfcAdapter.enableReaderMode(activity, readerCallback, flags, null)
        listening = true
    }

    fun stopSession() {
        adapter?.disableReaderMode(activity)
        listening = false
        currentTarget = null
    }
}

private fun Tag.toHexId(): String {
    return id.joinToString(separator = "") { byte ->
        "%02X".format(byte)
    }
}

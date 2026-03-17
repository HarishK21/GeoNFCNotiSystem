package com.geotap.guardian.geo_tap_guardian

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object GeofenceTargetStore {
    private const val prefsName = "geo_tap_guardian_geofencing"
    private const val targetsKey = "targets"

    fun saveTargets(context: Context, targets: List<Map<String, Any?>>) {
        val json = JSONArray()
        targets.forEach { json.put(JSONObject(it)) }
        context
            .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putString(targetsKey, json.toString())
            .apply()
    }

    fun clear(context: Context) {
        context
            .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .remove(targetsKey)
            .apply()
    }

    fun countTargets(context: Context): Int {
        val stored = context
            .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getString(targetsKey, null) ?: return 0
        return JSONArray(stored).length()
    }

    fun findTarget(context: Context, id: String): JSONObject? {
        val stored = context
            .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getString(targetsKey, null) ?: return null
        val jsonArray = JSONArray(stored)
        for (index in 0 until jsonArray.length()) {
            val item = jsonArray.getJSONObject(index)
            if (item.optString("id") == id) {
                return item
            }
        }
        return null
    }
}

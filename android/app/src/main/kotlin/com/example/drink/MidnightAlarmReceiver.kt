package com.example.drink

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.*

class MidnightAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("MidnightReceiver", "🕛 Midnight alarm triggered")

        val work = OneTimeWorkRequestBuilder<MidnightWorker>().build()
        WorkManager.getInstance(context).enqueue(work)
    }
}

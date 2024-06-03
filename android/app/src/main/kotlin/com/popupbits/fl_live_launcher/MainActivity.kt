package com.popupbits.fl_live_launcher

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode.transparent

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        intent.putExtra("background_mode", transparent.toString())
        super.onCreate(savedInstanceState)

    }
}
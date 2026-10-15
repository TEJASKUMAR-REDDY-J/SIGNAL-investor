package com.signalinvestor.signal_investor

import android.content.Intent
import android.net.ConnectivityManager
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.net.NetworkCapabilities
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity for local_auth. FLAG_SECURE on the whole app: every screen
// shows financial data; blocks screenshots and the recents thumbnail.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }

    // "signal/net".isWifi: the weekly scan runs on Wi-Fi (or Ethernet) only.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "signal/net").setMethodCallHandler { call, result ->
            if (call.method == "isWifi") {
                val cm = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
                val caps = cm.getNetworkCapabilities(cm.activeNetwork)
                result.success(
                    caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true ||
                        caps?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true
                )
            } else {
                result.notImplemented()
            }
        }
        // "signal/power": background runs need the app exempt from battery optimisation;
        // many phones (Xiaomi, Oppo, Vivo, Samsung) otherwise stop WorkManager jobs once the app is closed.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "signal/power").setMethodCallHandler { call, result ->
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            when (call.method) {
                "isIgnoring" -> result.success(pm.isIgnoringBatteryOptimizations(packageName))
                "request" -> {
                    startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "appSettings" -> {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

package com.local.ludo_global

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.local.ludo_global/privacy"
        ).setMethodCallHandler { call, result ->
            if (call.method == "openPrivacyPolicy") {
                try {
                    val url = Uri.parse("https://paras88dhami.github.io/ludo-privacy/")
                    val intent = Intent(Intent.ACTION_VIEW, url)
                    startActivity(intent)
                    result.success(null)
                } catch (error: Exception) {
                    result.error(
                        "BROWSER_UNAVAILABLE",
                        "Could not open the Privacy Policy.",
                        null
                    )
                }
            } else {
                result.notImplemented()
            }
        }
    }
}

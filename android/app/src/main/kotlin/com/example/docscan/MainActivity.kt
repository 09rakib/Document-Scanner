package com.example.docscan

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val purchaseWorker = java.util.concurrent.Executors.newSingleThreadExecutor()
    private lateinit var documentFiles: DocumentFileBridge
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.docscan/app_info")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "version" -> {
                        @Suppress("DEPRECATION")
                        val info = packageManager.getPackageInfo(packageName, 0)
                        @Suppress("DEPRECATION")
                        result.success("${info.versionName} (${info.versionCode})")
                    }
                    "rate" -> {
                        if (packageName == "com.example.docscan") {
                            result.error("not_published", "Store listing is not configured", null)
                        } else {
                            try {
                                startActivity(Intent(Intent.ACTION_VIEW,
                                    android.net.Uri.parse("https://play.google.com/store/apps/details?id=$packageName")))
                                result.success(null)
                            } catch (_: android.content.ActivityNotFoundException) {
                                result.error("unavailable", "No store or browser available", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.docscan/purchases")
            .setMethodCallHandler { call, result ->
                if (call.method != "verify") { result.notImplemented(); return@setMethodCallHandler }
                val payload = call.argument<String>("payload") ?: ""
                val signature = call.argument<String>("signature") ?: ""
                val key = call.argument<String>("publicKey") ?: ""
                val product = call.argument<String>("productId") ?: ""
                purchaseWorker.execute {
                    val valid = PurchaseVerifier.verify(payload, signature, key, packageName, product)
                    runOnUiThread { result.success(valid) }
                }
            }
        documentFiles = DocumentFileBridge(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.docscan/document_files")
            .setMethodCallHandler(documentFiles::handle)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.docscan/scanner_support")
            .setMethodCallHandler { call, result ->
                if (call.method != "checkAvailability") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val info = ActivityManager.MemoryInfo()
                (getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(info)
                val supported = info.totalMem >= 1_700_000_000L
                val servicesEnabled = try {
                    @Suppress("DEPRECATION")
                    packageManager.getApplicationInfo("com.google.android.gms", 0).enabled
                } catch (_: PackageManager.NameNotFoundException) { false }
                result.success(when {
                    !supported -> "unsupported"
                    !servicesEnabled -> "servicesUnavailable"
                    else -> "available"
                })
            }
    }

    @Deprecated("Android activity result bridge required by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        documentFiles.activityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        if (::documentFiles.isInitialized) documentFiles.close()
        purchaseWorker.shutdown()
        super.onDestroy()
    }
}

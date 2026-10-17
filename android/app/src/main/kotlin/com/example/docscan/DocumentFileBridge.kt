package com.example.docscan

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors
import kotlin.math.min
import kotlin.math.roundToInt

/** Streams exports and renders one bounded page on a worker, never on the UI thread. */
class DocumentFileBridge(private val activity: Activity) {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pending: Pair<File, MethodChannel.Result>? = null
    private val requestCode = 7303

    private fun source(path: String?): File {
        val file = File(requireNotNull(path)).canonicalFile
        val root = File(activity.applicationInfo.dataDir).canonicalFile
        require(file.path.startsWith(root.path + File.separator) && file.isFile)
        file.inputStream().use {
            val header = ByteArray(5)
            require(it.read(header) == 5 && String(header, Charsets.US_ASCII) == "%PDF-")
        }
        return file
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "exportPdf" -> {
                if (pending != null) { result.error("busy", "Export already open", null); return }
                try {
                    val file = source(call.argument<String>("path"))
                    pending = Pair(file, result)
                    activity.startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "document.pdf")
                    }, requestCode)
                } catch (_: Exception) {
                    pending = null
                    result.error("export_failed", "Cannot open export", null)
                }
            }
            "renderPage" -> worker.execute {
                try {
                    val file = source(call.argument<String>("path"))
                    val pageIndex = call.argument<Int>("page") ?: 0
                    val bytes = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                        PdfRenderer(descriptor).use { renderer ->
                            renderer.openPage(pageIndex).use { page ->
                                val scale = min(1200.0 / page.width, 1800.0 / page.height)
                                val bitmap = Bitmap.createBitmap((page.width * scale).roundToInt().coerceAtLeast(1),
                                    (page.height * scale).roundToInt().coerceAtLeast(1), Bitmap.Config.ARGB_8888)
                                try {
                                    bitmap.eraseColor(Color.WHITE)
                                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                    ByteArrayOutputStream().use { output ->
                                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                                        output.toByteArray()
                                    }
                                } finally { bitmap.recycle() }
                            }
                        }
                    }
                    main.post { result.success(bytes) }
                } catch (_: Exception) { main.post { result.error("preview_failed", "Cannot render PDF", null) } }
            }
            else -> result.notImplemented()
        }
    }

    fun activityResult(request: Int, code: Int, data: Intent?) {
        if (request != requestCode) return
        val export = pending ?: return
        pending = null
        val uri = data?.data
        if (code != Activity.RESULT_OK || uri == null) { export.second.success(false); return }
        worker.execute {
            try {
                activity.contentResolver.openOutputStream(uri, "w").use { output ->
                    requireNotNull(output)
                    export.first.inputStream().use { it.copyTo(output) }
                }
                main.post { export.second.success(true) }
            } catch (_: Exception) {
                try { DocumentsContract.deleteDocument(activity.contentResolver, uri) } catch (_: Exception) { }
                main.post { export.second.error("export_failed", "Cannot save PDF", null) }
            }
        }
    }

    fun close() { worker.shutdown() }
}

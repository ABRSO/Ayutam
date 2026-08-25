package com.ayutam.ayutam

import android.content.ContentValues
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val chartExportChannel = "com.ayutam.ayutam/chart_export"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, chartExportChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePngToDocuments" -> {
                        val fileName = call.argument<String>("fileName")
                        val relativeDir = call.argument<String>("relativeDir")
                            ?: "Ayutam/export-png"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (fileName.isNullOrBlank() || bytes == null) {
                            result.error("bad_args", "fileName and bytes required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val displayPath = savePngToDocuments(fileName, relativeDir, bytes)
                            result.success(displayPath)
                        } catch (e: Exception) {
                            result.error("save_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Writes [bytes] under public Documents/[relativeDir]/[fileName] via MediaStore
     * (scoped storage–safe on API 29+). Returns a user-facing path string.
     */
    private fun savePngToDocuments(
        fileName: String,
        relativeDir: String,
        bytes: ByteArray,
    ): String {
        val safeName = sanitizeExportFileName(fileName)
        val safeDir = sanitizeExportRelativeDir(relativeDir)
        val relativePath =
            "${Environment.DIRECTORY_DOCUMENTS.trimEnd('/')}/$safeDir"
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, safeName)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val collection: Uri =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Files.getContentUri("external")
            }

        val resolver = applicationContext.contentResolver
        val item = resolver.insert(collection, values)
            ?: throw IOException("MediaStore insert returned null")

        try {
            resolver.openOutputStream(item)?.use { out ->
                out.write(bytes)
                out.flush()
            } ?: throw IOException("Could not open output stream for $item")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(item, values, null, null)
            }
        } catch (e: Exception) {
            resolver.delete(item, null, null)
            throw e
        }

        return "$relativePath/$safeName"
    }

    private fun sanitizeExportFileName(fileName: String): String {
        val base = fileName.substringAfterLast('/').substringAfterLast('\\')
        val cleaned = base.replace(Regex("[^A-Za-z0-9._-]"), "_")
            .trimStart('.')
            .ifBlank { "chart.png" }
        return if (cleaned.endsWith(".png", ignoreCase = true)) cleaned else "$cleaned.png"
    }

    private fun sanitizeExportRelativeDir(relativeDir: String): String {
        val joined = relativeDir
            .split('/', '\\')
            .filter { part -> part.isNotEmpty() && part != "." && part != ".." }
            .joinToString("/")
        return joined.ifEmpty { "Ayutam/export-png" }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyEdgeToEdge()
    }

    override fun onPostResume() {
        super.onPostResume()
        // FlutterActivity can reset window flags during engine attach.
        applyEdgeToEdge()
    }

    private fun applyEdgeToEdge() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.navigationBarDividerColor = Color.TRANSPARENT
        }
    }
}

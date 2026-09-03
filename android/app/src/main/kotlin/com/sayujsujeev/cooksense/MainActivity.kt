package com.sayujsujeev.cooksense

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.sayujsujeev.cooksense/share"
        private const val MAX_VIDEO_BYTES = 150L * 1024L * 1024L
    }

    private val pendingShares = mutableListOf<Map<String, Any?>>()
    private var shareChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureShareIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "drainPendingShares" -> {
                        synchronized(pendingShares) {
                            result.success(pendingShares.toList())
                            pendingShares.clear()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (captureShareIntent(intent)) {
            shareChannel?.invokeMethod("shareAvailable", null)
        }
    }

    private fun captureShareIntent(intent: Intent?): Boolean {
        if (intent == null || (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE)) {
            return false
        }

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?: intent.clipData?.let { clip ->
                (0 until clip.itemCount)
                    .mapNotNull { clip.getItemAt(it).coerceToText(this)?.toString() }
                    .firstOrNull { it.isNotBlank() }
            }
        val uri = sharedUris(intent).firstOrNull()
        val declaredMime = intent.type
        val resolvedMime = uri?.let { contentResolver.getType(it) } ?: declaredMime

        val payload = mutableMapOf<String, Any?>()
        if (!text.isNullOrBlank()) payload["text"] = text

        if (uri != null && (resolvedMime?.startsWith("video/") == true || declaredMime?.startsWith("video/") == true)) {
            try {
                payload["filePath"] = copySharedVideo(uri, resolvedMime)
                payload["mimeType"] = resolvedMime ?: "video/mp4"
            } catch (error: Exception) {
                payload["error"] = error.message ?: "CookSense could not read the shared video."
            }
        }

        if (payload.isEmpty()) return false
        synchronized(pendingShares) { pendingShares.add(payload) }
        return true
    }

    @Suppress("DEPRECATION")
    private fun sharedUris(intent: Intent): List<Uri> {
        return if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java).orEmpty()
            } else {
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM).orEmpty()
            }
        } else {
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            }
            listOfNotNull(uri)
        }
    }

    private fun copySharedVideo(uri: Uri, mimeType: String?): String {
        val directory = File(cacheDir, "shared-recipe-videos").apply { mkdirs() }
        val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
            ?.takeIf { it.matches(Regex("[A-Za-z0-9]{1,8}")) }
            ?: "mp4"
        val destination = File(directory, "${UUID.randomUUID()}.$extension")

        try {
            contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "CookSense could not open the shared video." }
                FileOutputStream(destination).use { output ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var total = 0L
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        total += count
                        if (total > MAX_VIDEO_BYTES) {
                            throw IllegalArgumentException("Choose a shared video smaller than 150 MB.")
                        }
                        output.write(buffer, 0, count)
                    }
                    if (total == 0L) throw IllegalArgumentException("The shared video is empty.")
                }
            }
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
        return destination.absolutePath
    }
}

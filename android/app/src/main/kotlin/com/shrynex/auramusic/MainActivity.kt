package com.shrynex.auramusic

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.localization.Localization
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.shrynex.auramusic/newpipe"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NewPipe.init(DownloaderImpl(), Localization.DEFAULT)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStreamInfo" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                val extractor = ServiceList.YouTube.getStreamExtractor(url)
                                extractor.fetchPage()
                                val audioStreams = extractor.audioStreams
                                val audioUrl = audioStreams.maxByOrNull { it.averageBitrate }?.url
                                val info = mapOf(
                                    "name" to extractor.name,
                                    "url" to extractor.url,
                                    "audioUrl" to audioUrl
                                )
                                withContext(Dispatchers.Main) {
                                    result.success(info)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("STREAM_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URL is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

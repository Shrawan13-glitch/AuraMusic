package com.shrynex.auramusic

import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

class DownloaderImpl : Downloader() {
    @Throws(IOException::class, ReCaptchaException::class)
    override fun execute(request: Request): Response {
        val url = URL(request.url())
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = request.httpMethod()
        connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        request.headers().forEach { (key, values) ->
            values.forEach { value -> connection.addRequestProperty(key, value) }
        }
        request.dataToSend()?.let {
            connection.doOutput = true
            connection.outputStream.write(it)
        }
        connection.connectTimeout = 30000
        connection.readTimeout = 30000
        
        val responseCode = connection.responseCode
        val responseBody = if (responseCode in 200..299) {
            connection.inputStream.bufferedReader().use { it.readText() }
        } else {
            connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
        }
        
        return Response(responseCode, null, connection.headerFields.mapValues { it.value.toList() }, responseBody, request.url())
    }
}

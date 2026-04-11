package com.example.player_app

import android.content.ContentUris
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {

    private val CHANNEL = "com.example.player_app/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAudioFiles" -> {
                        try {
                            result.success(queryAudioFiles())
                        } catch (e: Exception) {
                            result.error("MEDIA_STORE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun queryAudioFiles(): List<Map<String, Any?>> {
        val audioList = mutableListOf<Map<String, Any?>>()

        val collection: Uri =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
            } else {
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.ALBUM_ID,   // ← NEW: needed for album art
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        contentResolver.query(collection, projection, selection, null, sortOrder)
            ?.use { cursor ->

                val idCol       = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val nameCol     = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
                val titleCol    = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                val artistCol   = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                val albumIdCol  = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

                while (cursor.moveToNext()) {
                    val id       = cursor.getLong(idCol)
                    val name     = cursor.getString(nameCol) ?: ""
                    val title    = cursor.getString(titleCol)?.takeIf { it.isNotBlank() } ?: name
                    val artist   = cursor.getString(artistCol)?.takeIf {
                        it.isNotBlank() && it != "<unknown>"
                    }
                    val duration = cursor.getLong(durationCol)
                    val albumId  = cursor.getLong(albumIdCol)

                    val contentUri = ContentUris.withAppendedId(
                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                        id
                    ).toString()

                    // Resolve album art to a cached file path Flutter can load
                    // with FileImage. The content:// albumart URI is not directly
                    // accessible from Dart's standard image providers.
                    val albumArtPath = getAlbumArtPath(albumId)

                    audioList.add(
                        mapOf(
                            "id"       to contentUri,
                            "path"     to contentUri,
                            "title"    to title,
                            "artist"   to artist,
                            "duration" to duration,
                            "albumArt" to albumArtPath,  // ← NEW
                        )
                    )
                }
            }

        return audioList
    }

    /**
     * Returns a local file path for the album art of [albumId], writing it to
     * the app's cache directory the first time. Returns null if there is no
     * album art or an error occurs.
     *
     * The content:// albumart URI scheme is not supported by Flutter's
     * FileImage / NetworkImage, so we copy the bytes to a regular JPEG file
     * and return that path instead.
     */
    private fun getAlbumArtPath(albumId: Long): String? {
        if (albumId <= 0) return null
        return try {
            val cacheDir = cacheDir
            val file = File(cacheDir, "albumart_$albumId.jpg")
            // Return cached file immediately to avoid redundant IO on every scan.
            if (file.exists() && file.length() > 0) return file.absolutePath

            val albumArtUri = ContentUris.withAppendedId(
                Uri.parse("content://media/external/audio/albumart"),
                albumId
            )
            contentResolver.openInputStream(albumArtUri)?.use { input ->
                file.outputStream().use { output -> input.copyTo(output) }
            }
            if (file.exists() && file.length() > 0) file.absolutePath else null
        } catch (_: Exception) {
            null
        }
    }
}
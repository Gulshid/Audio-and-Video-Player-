package com.example.player_app

import android.content.ContentUris
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

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

        val collection: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
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
            MediaStore.Audio.Media.DATA,         // absolute file path
        )

        // Only include music (excludes ringtones, notifications, alarms)
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        contentResolver.query(
            collection,
            projection,
            selection,
            null,
            sortOrder
        )?.use { cursor ->
            val idCol       = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val nameCol     = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val titleCol    = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol   = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataCol     = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

            while (cursor.moveToNext()) {
                val id       = cursor.getLong(idCol)
                val name     = cursor.getString(nameCol) ?: ""
                val title    = cursor.getString(titleCol)?.takeIf { it.isNotBlank() } ?: name
                val artist   = cursor.getString(artistCol)?.takeIf {
                    it.isNotBlank() && it != "<unknown>"
                }
                val duration = cursor.getLong(durationCol)
                val path     = cursor.getString(dataCol) ?: continue  // skip if no path

                // Build content URI as a stable reference (path can become stale on Android Q+)
                val contentUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id
                ).toString()

                audioList.add(
                    mapOf(
                        "id"          to contentUri,
                        "path"        to path,
                        "title"       to title,
                        "artist"      to artist,
                        "duration"    to duration,
                    )
                )
            }
        }

        return audioList
    }
}
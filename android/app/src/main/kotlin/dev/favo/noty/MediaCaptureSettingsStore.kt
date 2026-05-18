package dev.favo.noty

import android.content.Context

object MediaCaptureSettingsStore {
    private const val PREFS_NAME = "noty_media_capture_settings"
    private const val KEY_SAVE_STICKERS = "save_stickers"
    private const val KEY_SAVE_PHOTOS = "save_photos"

    data class Settings(
        val saveStickers: Boolean,
        val savePhotos: Boolean,
    ) {
        val enabled: Boolean
            get() = saveStickers || savePhotos
    }

    fun get(context: Context): Settings {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return Settings(
            saveStickers = prefs.getBoolean(KEY_SAVE_STICKERS, false),
            savePhotos = prefs.getBoolean(KEY_SAVE_PHOTOS, false),
        )
    }

    fun update(context: Context, saveStickers: Boolean, savePhotos: Boolean) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_SAVE_STICKERS, saveStickers)
            .putBoolean(KEY_SAVE_PHOTOS, savePhotos)
            .apply()
    }
}

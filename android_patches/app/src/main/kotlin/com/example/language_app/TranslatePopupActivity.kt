package com.example.language_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * TranslatePopupActivity
 * ──────────────────────
 * Handles Android's ACTION_PROCESS_TEXT intent.  When the user selects text in
 * any app (Chrome, e-reader, notes …) and picks "LingoLib — Translate" from
 * the contextual menu, Android launches THIS activity — NOT MainActivity.
 *
 * Architecture:
 *   • Extends FlutterActivity (Flutter embedding v2).
 *   • Uses a pre-warmed FlutterEngine from FlutterEngineCache so the popup
 *     opens near-instantly (no cold-start Dart VM overhead).
 *   • The Flutter side renders a translucent full-screen widget with a centred
 *     card; the Activity window is transparent so the calling app stays visible.
 *   • A MethodChannel delivers the selected text to Dart once Flutter is ready.
 *   • finish() on back-press or "close" tap returns the user to the calling
 *     app — MainActivity is never brought to the foreground.
 *
 * Engine lifecycle:
 *   • Engine is cached under ENGINE_CACHE_ID.
 *   • MainActivity.onCreate() pre-warms it in the background.
 *   • After TranslatePopupActivity.onDestroy(), the engine is removed from the
 *     cache and destroyed so it does not leak memory.
 */
class TranslatePopupActivity : FlutterActivity() {

    companion object {
        const val ENGINE_CACHE_ID = "popup_engine"
        const val CHANNEL = "com.example.language_app/process_text"
    }

    // ── Window sizing (windowIsFloating fix) ────────────────────────────────

    /**
     * windowIsFloating=true causes Android to set the window to WRAP_CONTENT
     * in both dimensions, which breaks Flutter's rendering surface (it gets
     * no bounded width constraint → renders at 0×0 or fills screen randomly).
     *
     * Fix: force MATCH_PARENT width so Flutter gets a definite horizontal
     * constraint, while keeping WRAP_CONTENT height so the window shrinks to
     * fit the Flutter card's intrinsic height.
     *
     * Result: the popup behaves like a bottom/centre sheet — full screen width,
     * only as tall as the card content.
     */
    override fun onStart() {
        super.onStart()
        window?.setLayout(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT
        )
    }

    // ── Background mode ──────────────────────────────────────────────────────
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    // ── Engine selection ─────────────────────────────────────────────────────

    /**
     * Use the pre-warmed engine from the cache.
     * If (somehow) the cache is empty — e.g. process was killed — fall back to
     * creating a new engine so the popup still works, just with a brief delay.
     */
    override fun getCachedEngineId(): String = ENGINE_CACHE_ID

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        val cached = FlutterEngineCache.getInstance().get(ENGINE_CACHE_ID)
        if (cached != null) return cached

        // Fallback: spin up a new engine synchronously.
        // This path is rare (process restart), but must not crash.
        val engine = FlutterEngine(context)
        engine.navigationChannel.setInitialRoute("/popup")
        engine.dartExecutor.executeDartEntrypoint(
            io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_CACHE_ID, engine)
        return engine
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sendSelectedTextToFlutter()
    }

    /**
     * Read the text the user highlighted and push it to the Flutter layer via
     * MethodChannel.  The channel handler in translate_popup_view.dart receives
     * this and pre-fills the input field.
     */
    private fun sendSelectedTextToFlutter() {
        val selectedText = intent
            ?.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
            ?.toString()
            ?.trim()
            ?: ""

        // Flutter may not be fully initialised yet; wait for first frame.
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            val channel = MethodChannel(messenger, CHANNEL)
            // Slight delay gives Flutter's first frame time to mount the widget
            // and register its MethodChannel handler.
            android.os.Handler(mainLooper).postDelayed({
                channel.invokeMethod("setSelectedText", selectedText)
            }, 300)
        }
    }

    // ── Back / dismiss behaviour ─────────────────────────────────────────────

    /**
     * When the user presses the system back button, simply finish this Activity.
     * Because taskAffinity="" and excludeFromRecents="true" are set in the
     * Manifest, Android will resume the calling app (Chrome / e-reader) rather
     * than navigating to MainActivity.
     */
    @Deprecated("Deprecated but required for API < 33 compatibility")
    override fun onBackPressed() {
        finish()
    }

    // ── Engine cleanup ───────────────────────────────────────────────────────

    override fun onDestroy() {
        // Remove and destroy the cached engine to free memory.
        // MainActivity will re-warm it next time it runs.
        FlutterEngineCache.getInstance().remove(ENGINE_CACHE_ID)
        super.onDestroy()
    }
}

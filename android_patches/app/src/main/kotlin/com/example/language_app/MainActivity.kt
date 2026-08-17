package com.example.language_app

import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * MainActivity
 * ────────────
 * Standard Flutter host activity for the main application.
 *
 * Additional responsibility: pre-warms the FlutterEngine used by
 * TranslatePopupActivity so that the popup opens near-instantly when triggered.
 *
 * Pre-warm strategy:
 *   • Done in onCreate() — only if the engine is not already cached.
 *   • The engine executes the default Dart entrypoint (main()) with the
 *     initial route set to "/popup" BEFORE dartExecutor.executeDartEntrypoint
 *     is called (route must be set first, cannot be changed afterwards).
 *   • No custom Application subclass is required; FlutterEngineCache is a
 *     global singleton accessible from any Context.
 *
 * Engine lifecycle:
 *   • Cached engine outlives the Activity — this is intentional so it is
 *     ready when TranslatePopupActivity is launched.
 *   • TranslatePopupActivity.onDestroy() removes + destroys the engine.
 *   • onDestroy() of MainActivity also cleans up if the engine is still
 *     around (e.g. user never opened the popup).
 */
class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        warmUpPopupEngine(this)
    }

    override fun onDestroy() {
        // Clean up the popup engine if it was not already destroyed by the popup.
        val cached = FlutterEngineCache.getInstance()
            .get(TranslatePopupActivity.ENGINE_CACHE_ID)
        if (cached != null) {
            FlutterEngineCache.getInstance()
                .remove(TranslatePopupActivity.ENGINE_CACHE_ID)
            cached.destroy()
        }
        super.onDestroy()
    }

    companion object {
        /**
         * Initialises and caches a FlutterEngine for the popup route.
         * Safe to call multiple times — returns immediately if already cached.
         */
        fun warmUpPopupEngine(context: Context) {
            if (FlutterEngineCache.getInstance()
                    .contains(TranslatePopupActivity.ENGINE_CACHE_ID)) return

            val engine = FlutterEngine(context)

            // CRITICAL: set the route BEFORE executeDartEntrypoint.
            // Once Dart starts running, the initial route cannot be changed.
            engine.navigationChannel.setInitialRoute("/popup")

            // Start executing Dart code in the background.
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )

            // Register in the global cache so TranslatePopupActivity can pick it up.
            FlutterEngineCache.getInstance()
                .put(TranslatePopupActivity.ENGINE_CACHE_ID, engine)
        }
    }
}

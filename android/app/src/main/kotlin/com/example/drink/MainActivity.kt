package com.example.drink

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {

    private var registered = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register GoogleMobileAds native ad factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            NativeAdFactoryExample(layoutInflater)
        )
        registered = true
    }

    override fun onDestroy() {
        flutterEngine?.let {
            if (registered) {
                GoogleMobileAdsPlugin.unregisterNativeAdFactory(it, "listTile")
                registered = false
            }
        }
        super.onDestroy()
    }
}

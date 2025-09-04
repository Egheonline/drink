package com.example.drink

import android.view.LayoutInflater
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory
import com.example.drink.R

class NativeAdFactoryExample(private val inflater: LayoutInflater) : NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: Map<String, Any>?): NativeAdView {
        val adView = inflater.inflate(R.layout.native_ad_layout, null) as NativeAdView

        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)

        (adView.headlineView as TextView).text = nativeAd.headline
        (adView.bodyView as TextView).text = nativeAd.body

        adView.setNativeAd(nativeAd)
        return adView
    }
}

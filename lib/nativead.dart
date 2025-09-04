import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdContainer extends StatefulWidget {
  const NativeAdContainer({super.key});

  @override
  State<NativeAdContainer> createState() => _NativeAdContainerState();
}

class _NativeAdContainerState extends State<NativeAdContainer> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId:
          'ca-app-pub-3940256099942544/2247696110', // Test ID, replace in production
      factoryId: 'listTile', // Match this with your NativeAdFactory
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          print('Native Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _nativeAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) return const SizedBox();
    return Container(
      alignment: Alignment.center,
      height: 100,
      child: AdWidget(ad: _nativeAd!),
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

bool get isIosMobile =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isAndroidMobile =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

String healthProviderDisplayName() {
  if (isIosMobile) return 'Apple Health';
  if (isAndroidMobile) return 'Health Connect';
  return 'Health';
}

String connectHealthCtaLabel() {
  if (isIosMobile) return 'Connect Apple Health';
  if (isAndroidMobile) return 'Connect Health Connect';
  return 'Connect health';
}

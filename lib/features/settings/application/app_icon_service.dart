import 'package:flutter/services.dart';

const defaultAppIconKey = 'lifer';
const alternateAppIconKey = 'logo';

class AppIconService {
  static const MethodChannel _channel = MethodChannel('com.allinist.lifer/app_icon');

  Future<void> setAppIcon(String iconKey) async {
    await _channel.invokeMethod<void>('setAppIcon', {
      'iconKey': iconKey,
    });
  }
}

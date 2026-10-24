import 'package:flutter/services.dart';

import '../../domain/repositories/device_gateway.dart';

class MethodChannelDeviceGateway implements DeviceGateway {
  static const channel = MethodChannel('dashtconnect/device');

  Future<String> storagePath() async {
    final path = await channel.invokeMethod<String>('storagePath');
    if (path == null || path.isEmpty) {
      throw PlatformException(
        code: 'storage',
        message: 'Penyimpanan tidak tersedia.',
      );
    }
    return path;
  }

  @override
  Future<Map<String, String>> deviceInfo() async {
    final result = await channel.invokeMapMethod<String, String>('deviceInfo');
    if (result == null) {
      throw PlatformException(
        code: 'device',
        message: 'Informasi perangkat tidak tersedia.',
      );
    }
    return result;
  }

  @override
  Future<void> setDimmed(bool enabled) =>
      channel.invokeMethod<void>('setDimmed', {'enabled': enabled});

  @override
  Future<void> openSettings(DeviceSettings section) =>
      channel.invokeMethod<void>('openSettings', {'section': section.name});
}

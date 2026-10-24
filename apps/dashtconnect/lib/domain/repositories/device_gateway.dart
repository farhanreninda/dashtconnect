enum DeviceSettings { wifi, bluetooth }

abstract interface class DeviceGateway {
  Future<Map<String, String>> deviceInfo();
  Future<void> setDimmed(bool enabled);
  Future<void> openSettings(DeviceSettings section);
}

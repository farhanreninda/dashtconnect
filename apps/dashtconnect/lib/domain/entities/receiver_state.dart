class ReceiverPhone {
  const ReceiverPhone({required this.id, required this.name});
  final String id;
  final String name;
}

class ReceiverPreparation {
  const ReceiverPreparation({
    required this.authenticationAvailable,
    required this.internetAvailable,
    required this.bluetoothEnabled,
    required this.missingPermissions,
    required this.phones,
    this.wifiEnabled = true,
    this.preferredPhoneId,
  });
  final bool authenticationAvailable;
  final bool internetAvailable;
  final bool bluetoothEnabled;
  final List<String> missingPermissions;
  final List<ReceiverPhone> phones;
  final bool wifiEnabled;
  final String? preferredPhoneId;

  String? get automaticPhoneId =>
      phones.any((phone) => phone.id == preferredPhoneId)
      ? preferredPhoneId
      : phones.length == 1
      ? phones.single.id
      : null;

  bool get canStart =>
      authenticationAvailable &&
      bluetoothEnabled &&
      wifiEnabled &&
      missingPermissions.isEmpty;
}

enum ReceiverPhase {
  surfaceReady,
  surfaceLost,
  connecting,
  connected,
  error,
  stopped,
}

class ReceiverEvent {
  const ReceiverEvent(this.viewId, this.phase, this.message, {this.wifi});
  final int viewId;
  final ReceiverPhase phase;
  final String message;
  final ReceiverWifi? wifi;
}

class ReceiverWifi {
  const ReceiverWifi(this.ssid, this.passphrase);
  final String ssid, passphrase;
}

/// How far the USB link to the head unit has come, replacing the T-Link phone app.
enum HeadUnitLink { absent, detected, waiting, streaming }

class HeadUnitStatus {
  const HeadUnitStatus(this.link, {this.problem});
  final HeadUnitLink link;

  /// Why the last attempt ended or never started; null when nothing went wrong.
  final String? problem;
}

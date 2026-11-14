enum AndroidAutoPhase { unavailable, disabled, identityMissing, ready }

enum AndroidAutoSession {
  idle,
  connecting,
  waitingVideo,
  projecting,
  failed,
  ended;

  bool get active =>
      this == connecting || this == waitingVideo || this == projecting;
}

class AndroidAutoState {
  const AndroidAutoState({
    required this.sdk,
    required this.installed,
    required this.enabled,
    required this.usbAccessory,
    required this.usbHostDevice,
    required this.version,
    this.identity = false,
    this.session = AndroidAutoSession.idle,
    this.sessionDetail = '',
  });
  final int sdk;
  final bool installed, enabled, usbAccessory, usbHostDevice, identity;
  final String version, sessionDetail;
  final AndroidAutoSession session;

  AndroidAutoPhase get phase {
    if (!installed) return AndroidAutoPhase.unavailable;
    if (!enabled) return AndroidAutoPhase.disabled;
    if (!identity) return AndroidAutoPhase.identityMissing;
    return AndroidAutoPhase.ready;
  }
}

import 'package:flutter/services.dart';

import '../../domain/entities/android_auto_state.dart';
import '../../domain/repositories/android_auto_gateway.dart';

class MethodChannelAndroidAutoGateway implements AndroidAutoGateway {
  static const channel = MethodChannel('dashtconnect/android_auto');
  static const eventChannel = EventChannel('dashtconnect/android_auto_events');
  late final _events = eventChannel.receiveBroadcastStream().map(parse);

  static const _sessions = {
    'idle': AndroidAutoSession.idle,
    'connecting': AndroidAutoSession.connecting,
    'waiting_video': AndroidAutoSession.waitingVideo,
    'projecting': AndroidAutoSession.projecting,
    'failed': AndroidAutoSession.failed,
    'ended': AndroidAutoSession.ended,
  };

  @override
  Stream<AndroidAutoState> get events => _events;

  @override
  Future<AndroidAutoState> refresh() async =>
      parse(await channel.invokeMethod<Object?>('refresh'));

  @override
  Future<void> openSettings() => channel.invokeMethod<void>('openSettings');

  @override
  Future<void> start() => channel.invokeMethod<void>('start');

  @override
  Future<void> stop() => channel.invokeMethod<void>('stop');

  static AndroidAutoState parse(Object? raw) {
    if (raw is! Map ||
        raw['sdk'] is! int ||
        (raw['sdk'] as int) < 1 ||
        raw['installed'] is! bool ||
        raw['enabled'] is! bool ||
        raw['version'] is! String ||
        raw['usbAccessory'] is! bool ||
        raw['usbHostDevice'] is! bool ||
        raw['identity'] is! bool ||
        !_sessions.containsKey(raw['session']) ||
        raw['sessionDetail'] is! String) {
      throw const FormatException('Status Android Auto tidak valid.');
    }
    return AndroidAutoState(
      sdk: raw['sdk'] as int,
      installed: raw['installed'] as bool,
      enabled: raw['enabled'] as bool,
      version: raw['version'] as String,
      usbAccessory: raw['usbAccessory'] as bool,
      usbHostDevice: raw['usbHostDevice'] as bool,
      identity: raw['identity'] as bool,
      session: _sessions[raw['session']]!,
      sessionDetail: raw['sessionDetail'] as String,
    );
  }
}

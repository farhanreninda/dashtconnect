import 'package:flutter/services.dart';

import '../../domain/entities/receiver_state.dart';
import '../../domain/repositories/receiver_gateway.dart';

class MethodChannelReceiverGateway implements ReceiverGateway {
  static const _methods = MethodChannel('dashtconnect/receiver');
  static const _events = EventChannel('dashtconnect/receiver_events');
  late final Stream<ReceiverEvent> _stream = _events
      .receiveBroadcastStream()
      .map((value) {
        if (value
            case {
              'viewId': int id,
              'phase': String phase,
              'message': String message,
            }
            when id >= 0 && message.length <= 2048) {
          final wifi = switch (value['wifi']) {
            null => null,
            {'ssid': String ssid, 'passphrase': String passphrase}
                when phase == 'connecting' &&
                    ssid.isNotEmpty &&
                    ssid.length <= 32 &&
                    passphrase.length >= 8 &&
                    passphrase.length <= 63 &&
                    !ssid.contains('\u0000') &&
                    !passphrase.contains('\u0000') =>
              ReceiverWifi(ssid, passphrase),
            _ => throw const FormatException(
              'Jaringan lokal receiver tidak valid.',
            ),
          };
          return ReceiverEvent(
            id,
            switch (phase) {
              'surface_ready' => ReceiverPhase.surfaceReady,
              'connecting' => ReceiverPhase.connecting,
              'connected' => ReceiverPhase.connected,
              'error' => ReceiverPhase.error,
              'stopped' => ReceiverPhase.stopped,
              _ => throw const FormatException('Fase receiver tidak dikenal.'),
            },
            message,
            wifi: wifi,
          );
        }
        throw const FormatException('Status receiver tidak valid.');
      });

  @override
  Stream<ReceiverEvent> get events => _stream;

  @override
  Future<ReceiverPreparation> preparation() async =>
      _parse(await _methods.invokeMethod<Object?>('preparation'));

  @override
  Future<ReceiverPreparation> requestPermissions() async =>
      _parse(await _methods.invokeMethod<Object?>('requestPermissions'));

  ReceiverPreparation _parse(Object? value) {
    if (value
        case {
          'authenticationAvailable': bool auth,
          'internetAvailable': bool internet,
          'bluetoothEnabled': bool bluetooth,
          'missingPermissions': List permissions,
          'phones': List phones,
        }
        when permissions.length <= 8 && phones.length <= 128) {
      final ids = <String>{};
      return ReceiverPreparation(
        authenticationAvailable: auth,
        internetAvailable: internet,
        bluetoothEnabled: bluetooth,
        missingPermissions: List.unmodifiable(
          permissions.map((item) {
            if (item is! String || item.isEmpty || item.length > 128) {
              throw const FormatException('Izin receiver tidak valid.');
            }
            return item;
          }),
        ),
        phones: List.unmodifiable(
          phones.map((item) {
            if (item case {'id': String id, 'name': String name}
                when RegExp(r'^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$')
                        .hasMatch(id) &&
                    name.isNotEmpty &&
                    name.length <= 248 &&
                    ids.add(id.toUpperCase())) {
              return ReceiverPhone(id: id, name: name);
            }
            throw const FormatException('Daftar iPhone tidak valid.');
          }),
        ),
      );
    }
    throw const FormatException('Persiapan receiver tidak valid.');
  }

  @override
  Future<void> start({required int viewId, required String phoneId}) async {
    if (viewId < 0 ||
        !RegExp(r'^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$').hasMatch(phoneId)) {
      throw ArgumentError('Layar atau iPhone tidak valid.');
    }
    await _methods.invokeMethod<void>('start', {
      'viewId': viewId,
      'phoneId': phoneId,
    });
  }

  @override
  Future<void> stop(int viewId) =>
      _methods.invokeMethod<void>('stop', {'viewId': viewId});
}

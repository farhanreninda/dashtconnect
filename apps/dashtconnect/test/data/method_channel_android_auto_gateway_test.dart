import 'package:dashtconnect/data/platform/method_channel_android_auto_gateway.dart';
import 'package:dashtconnect/domain/entities/android_auto_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final valid = <String, Object>{
    'sdk': 34,
    'installed': true,
    'enabled': true,
    'version': '17.4',
    'usbAccessory': false,
    'usbHostDevice': false,
    'identity': true,
    'session': 'waiting_video',
    'sessionDetail': '',
  };
  tearDown(
    () => messenger.setMockMethodCallHandler(
      MethodChannelAndroidAutoGateway.channel,
      null,
    ),
  );
  test('validates native state and routes only real host actions', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(
      MethodChannelAndroidAutoGateway.channel,
      (call) async {
        calls.add(call.method);
        return call.method == 'refresh' ? valid : null;
      },
    );
    final gateway = MethodChannelAndroidAutoGateway();
    final state = await gateway.refresh();
    expect(state.version, '17.4');
    expect(state.session, AndroidAutoSession.waitingVideo);
    await gateway.openSettings();
    await gateway.start();
    await gateway.stop();
    expect(calls, ['refresh', 'openSettings', 'start', 'stop']);
    for (final invalid in [
      null,
      {},
      {...valid, 'version': 9},
      {...valid, 'installed': 'true'},
      {...valid, 'sdk': -2},
      {...valid, 'usbAccessory': 1},
      {...valid, 'session': 'connected'},
      {...valid, 'identity': null},
    ]) {
      expect(
        () => MethodChannelAndroidAutoGateway.parse(invalid),
        throwsFormatException,
      );
    }
    messenger.setMockMethodCallHandler(
      MethodChannelAndroidAutoGateway.channel,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    expect(gateway.refresh(), throwsA(isA<PlatformException>()));
  });
}

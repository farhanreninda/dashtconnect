import 'package:dashtconnect/data/platform/method_channel_device_gateway.dart';
import 'package:dashtconnect/domain/repositories/device_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final gateway = MethodChannelDeviceGateway();

  tearDown(() {
    messenger.setMockMethodCallHandler(
      MethodChannelDeviceGateway.channel,
      null,
    );
  });

  test('opens only the requested Android settings section', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(MethodChannelDeviceGateway.channel, (
      call,
    ) async {
      calls.add(call);
      return null;
    });
    await gateway.openSettings(DeviceSettings.wifi);
    await gateway.openSettings(DeviceSettings.bluetooth);
    expect(calls.map((call) => call.method), ['openSettings', 'openSettings']);
    expect(calls[0].arguments, {'section': 'wifi'});
    expect(calls[1].arguments, {'section': 'bluetooth'});
  });

  test('preserves unavailable settings errors for retry', () async {
    messenger.setMockMethodCallHandler(MethodChannelDeviceGateway.channel, (
      _,
    ) async {
      throw PlatformException(code: 'settings_unavailable');
    });
    await expectLater(
      gateway.openSettings(DeviceSettings.wifi),
      throwsA(isA<PlatformException>()),
    );
  });

  test(
    'retains storage, device info, and brightness channel contracts',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(MethodChannelDeviceGateway.channel, (
        call,
      ) async {
        calls.add(call);
        return switch (call.method) {
          'storagePath' => '/private/files',
          'deviceInfo' => {'Model Android': 'Test device'},
          _ => null,
        };
      });

      expect(await gateway.storagePath(), '/private/files');
      expect(await gateway.deviceInfo(), {'Model Android': 'Test device'});
      await gateway.setDimmed(true);
      expect(calls.last.method, 'setDimmed');
      expect(calls.last.arguments, {'enabled': true});
    },
  );
}

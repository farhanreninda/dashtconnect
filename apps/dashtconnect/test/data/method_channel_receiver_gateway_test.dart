import 'package:dashtconnect/data/platform/method_channel_receiver_gateway.dart';
import 'package:dashtconnect/domain/entities/receiver_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dashtconnect/receiver');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final valid = <String, Object>{
    'authenticationAvailable': true,
    'internetAvailable': false,
    'bluetoothEnabled': true,
    'missingPermissions': <String>[],
    'phones': [
      {'id': 'AA:BB:CC:DD:EE:FF', 'name': 'iPhone uji'},
    ],
  };
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'local Wi-Fi events validate credentials and keep legacy events working',
    () async {
      const eventChannel = MethodChannel('dashtconnect/receiver_events');
      messenger.setMockMethodCallHandler(eventChannel, (_) async => null);
      final events = <ReceiverEvent>[];
      final errors = <Object>[];
      final subscription = MethodChannelReceiverGateway().events.listen(
        events.add,
        onError: errors.add,
      );
      await Future<void>.delayed(Duration.zero);
      final base = {
        'viewId': 1,
        'phase': 'connecting',
        'message': 'Menunggu Wi-Fi',
      };
      for (final value in [
        base,
        {
          ...base,
          'wifi': {'ssid': 'DIRECT-test', 'passphrase': 'test-passphrase'},
        },
        {
          ...base,
          'wifi': {'ssid': '', 'passphrase': 'test-passphrase'},
        },
        {
          ...base,
          'wifi': {'ssid': 'DIRECT-test', 'passphrase': 'short'},
        },
        {
          ...base,
          'phase': 'stopped',
          'wifi': {'ssid': 'DIRECT-test', 'passphrase': 'test-passphrase'},
        },
      ]) {
        ServicesBinding.instance.channelBuffers.push(
          'dashtconnect/receiver_events',
          const StandardMethodCodec().encodeSuccessEnvelope(value),
          (_) {},
        );
        await Future<void>.delayed(Duration.zero);
      }
      expect(events, hasLength(2));
      expect(events.first.wifi, isNull);
      expect(events.last.wifi!.ssid, 'DIRECT-test');
      expect(errors, hasLength(3));
      expect(errors, everyElement(isA<FormatException>()));
      await subscription.cancel();
      messenger.setMockMethodCallHandler(eventChannel, null);
    },
  );

  test(
    'validates native preparation and fails closed on internet or missing auth',
    () async {
      var response = Map.of(valid);
      messenger.setMockMethodCallHandler(channel, (_) async => response);
      final gateway = MethodChannelReceiverGateway();
      final prepared = await gateway.preparation();
      expect(prepared.canStart, isTrue);
      expect(prepared.phones.single.name, 'iPhone uji');
      response['internetAvailable'] = true;
      expect((await gateway.preparation()).canStart, isFalse);
      response = {...valid, 'authenticationAvailable': false};
      expect((await gateway.preparation()).canStart, isFalse);
      response = {
        ...valid,
        'missingPermissions': ['android.permission.BLUETOOTH_CONNECT'],
      };
      expect((await gateway.preparation()).canStart, isFalse);
    },
  );

  test(
    'rejects malformed and duplicate native devices instead of selecting one',
    () async {
      final responses = [
        {...valid, 'authenticationAvailable': 'true'},
        {
          ...valid,
          'phones': [
            {'id': 'not-an-address', 'name': 'iPhone'},
          ],
        },
        {
          ...valid,
          'phones': [
            {'id': 'AA:BB:CC:DD:EE:FF', 'name': 'one'},
            {'id': 'aa:bb:cc:dd:ee:ff', 'name': 'two'},
          ],
        },
        {
          ...valid,
          'missingPermissions': [true],
        },
      ];
      for (final response in responses) {
        messenger.setMockMethodCallHandler(channel, (_) async => response);
        await expectLater(
          MethodChannelReceiverGateway().preparation(),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'start validates its destination and forwards native startup failures',
    () async {
      var requests = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        requests++;
        expect(call.method, 'start');
        expect(call.arguments, {'viewId': 4, 'phoneId': 'AA:BB:CC:DD:EE:FF'});
        throw PlatformException(
          code: 'receiver',
          message: 'Autentikasi belum tersedia',
        );
      });
      final gateway = MethodChannelReceiverGateway();
      await expectLater(
        gateway.start(viewId: -1, phoneId: 'bad'),
        throwsArgumentError,
      );
      expect(requests, 0);
      await expectLater(
        gateway.start(viewId: 4, phoneId: 'AA:BB:CC:DD:EE:FF'),
        throwsA(isA<PlatformException>()),
      );
      expect(requests, 1);
    },
  );
}

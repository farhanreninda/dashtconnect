import 'package:dashtconnect/domain/entities/receiver_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const first = ReceiverPhone(id: 'AA:BB:CC:DD:EE:01', name: 'iPhone A');
  const second = ReceiverPhone(id: 'AA:BB:CC:DD:EE:02', name: 'iPhone B');
  ReceiverPreparation ready(
    List<ReceiverPhone> phones, {
    String? last,
    bool wifi = true,
  }) => ReceiverPreparation(
    authenticationAvailable: true,
    internetAvailable: true,
    bluetoothEnabled: true,
    wifiEnabled: wifi,
    preferredPhoneId: last,
    missingPermissions: [],
    phones: phones,
  );

  test('selects only a bonded remembered phone or the sole paired phone', () {
    expect(ready([]).automaticPhoneId, isNull);
    expect(ready([first]).automaticPhoneId, first.id);
    expect(ready([first, second]).automaticPhoneId, isNull);
    expect(ready([first, second], last: second.id).automaticPhoneId, second.id);
    expect(
      ready([first, second], last: 'AA:BB:CC:DD:EE:03').automaticPhoneId,
      isNull,
    );
  });

  test('Wi-Fi readiness still gates start while internet does not', () {
    expect(ready([first]).canStart, isTrue);
    expect(ready([first], wifi: false).canStart, isFalse);
  });
}

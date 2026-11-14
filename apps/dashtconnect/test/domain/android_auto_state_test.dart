import 'package:dashtconnect/domain/entities/android_auto_state.dart';
import 'package:dashtconnect/domain/entities/connection_mode.dart';
import 'package:dashtconnect/data/models/notebook_codec.dart';
import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('USB, host package and Android version do not replace the head unit identity', () {
    for (final sdk in [28, 34]) {
      final state = AndroidAutoState(
        sdk: sdk,
        installed: true,
        enabled: true,
        version: '17.4',
        usbAccessory: true,
        usbHostDevice: true,
      );
      expect(state.phase, AndroidAutoPhase.identityMissing);
    }
  });
  test(
    'identity makes the session startable without implying a session runs',
    () {
      const ready = AndroidAutoState(
        sdk: 34,
        installed: true,
        enabled: true,
        version: '17.9',
        usbAccessory: false,
        usbHostDevice: false,
        identity: true,
      );
      expect(ready.phase, AndroidAutoPhase.ready);
      expect(ready.session.active, isFalse);
      expect(AndroidAutoSession.waitingVideo.active, isTrue);
      expect(AndroidAutoSession.failed.active, isFalse);
    },
  );
  test(
    'missing and disabled Android Auto remain distinct from missing receiver',
    () {
      const missing = AndroidAutoState(
        sdk: 34,
        installed: false,
        enabled: false,
        version: '',
        usbAccessory: false,
        usbHostDevice: false,
      );
      const disabled = AndroidAutoState(
        sdk: 34,
        installed: true,
        enabled: false,
        version: '17.4',
        usbAccessory: false,
        usbHostDevice: false,
      );
      expect(missing.phase, AndroidAutoPhase.unavailable);
      expect(disabled.phase, AndroidAutoPhase.disabled);
    },
  );

  test(
    'saved mode round trips without discarding old data or breaking schema 1',
    () {
      const old = Notebook(
        inventory: {'model': 'kept'},
        theme: 'dark',
        tutorialCompleted: true,
      );
      final encoded = NotebookCodec.toMap(old);
      expect(NotebookCodec.fromMap(encoded).lastMode, isNull);
      final restored = NotebookCodec.fromMap(
        NotebookCodec.toMap(old.copyWith(lastMode: 'androidAuto')),
      );
      expect(restored.lastMode, 'androidAuto');
      expect(restored.inventory, old.inventory);
      expect(restored.theme, 'dark');
      expect(restored.tutorialCompleted, isTrue);
      encoded['lastMode'] = 'future-mode';
      expect(
        ConnectionMode.fromId(NotebookCodec.fromMap(encoded).lastMode),
        isNull,
      );
      encoded['lastMode'] = 12;
      expect(() => NotebookCodec.fromMap(encoded), throwsFormatException);
    },
  );
}

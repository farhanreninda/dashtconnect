import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashtconnect/domain/entities/android_auto_state.dart';
import 'package:dashtconnect/domain/repositories/android_auto_gateway.dart';
import 'package:dashtconnect/data/models/notebook_codec.dart';
import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:dashtconnect/domain/repositories/device_gateway.dart';
import 'package:dashtconnect/domain/repositories/notebook_repository.dart';
import 'package:dashtconnect/domain/entities/receiver_state.dart';
import 'package:dashtconnect/domain/repositories/receiver_gateway.dart';

Future<void> selectCarPlayIfNeeded(WidgetTester tester) async {
  if (find.text('Koneksi ke head unit').evaluate().isNotEmpty) {
    await openModeChoices(tester);
  }
  final selector = find.descendant(
    of: find.byKey(const Key('mode-carplay')),
    matching: find.text('Apple CarPlay'),
  );
  if (selector.evaluate().isNotEmpty) {
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
  }
}

Future<void> openModeChoices(WidgetTester tester) async {
  if (find.text('Pilih cara terhubung.').evaluate().isNotEmpty) return;
  final home = find.text('Beranda');
  if (home.evaluate().isNotEmpty) {
    await tester.ensureVisible(home);
    await tester.tap(home);
    await tester.pumpAndSettle();
  }
  final action = find.text('Pilih mode koneksi');
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

class TestAndroidAutoGateway implements AndroidAutoGateway {
  final updates = StreamController<AndroidAutoState>.broadcast(sync: true);
  AndroidAutoState state = const AndroidAutoState(
    sdk: 34,
    installed: true,
    enabled: true,
    version: '17.4',
    usbAccessory: false,
    usbHostDevice: false,
  );
  bool fail = false, failSettings = false;
  int reads = 0, settingsOpened = 0, starts = 0, stops = 0;
  Completer<AndroidAutoState>? pending;
  @override
  Stream<AndroidAutoState> get events => updates.stream;
  @override
  Future<AndroidAutoState> refresh() async {
    reads++;
    if (fail) throw StateError('unavailable');
    if (pending != null) return pending!.future;
    return state;
  }

  @override
  Future<void> openSettings() async {
    if (failSettings) throw StateError('unavailable');
    settingsOpened++;
  }

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async => stops++;
}

class TestReceiverGateway implements ReceiverGateway {
  ReceiverPreparation value = const ReceiverPreparation(
    authenticationAvailable: false,
    internetAvailable: false,
    bluetoothEnabled: false,
    missingPermissions: [],
    phones: [],
  );
  final updates = StreamController<ReceiverEvent>.broadcast();
  int starts = 0, stops = 0, requests = 0;
  bool failStart = false;
  int prepares = 0;
  String? startedPhoneId;
  Future<ReceiverPreparation> Function()? onPrepare;
  @override
  Stream<ReceiverEvent> get events => updates.stream;
  @override
  Future<ReceiverPreparation> preparation() async => value;
  @override
  Future<ReceiverPreparation> requestPermissions() async {
    requests++;
    return value;
  }

  @override
  Future<ReceiverPreparation> prepareConnection() async {
    prepares++;
    return onPrepare == null ? value : await onPrepare!();
  }

  @override
  Future<void> start({required int viewId, required String phoneId}) async {
    starts++;
    startedPhoneId = phoneId;
    if (failStart) throw StateError('Test startup failure');
  }

  @override
  Future<void> stop(int viewId) async {
    stops++;
  }
}

class TestDeviceGateway implements DeviceGateway {
  bool dimmed = false;
  bool failInfo = false;
  bool failSettings = false;
  bool failDim = false;
  int infoReads = 0;
  DeviceSettings? lastSettings;

  @override
  Future<Map<String, String>> deviceInfo() async {
    infoReads++;
    if (failInfo) throw StateError('Fixture info tidak tersedia');
    return {'Model Android': 'Perangkat uji'};
  }

  @override
  Future<void> setDimmed(bool enabled) async {
    if (failDim) throw StateError('Fixture kecerahan tidak tersedia');
    dimmed = enabled;
  }

  @override
  Future<void> openSettings(DeviceSettings section) async {
    if (failSettings) throw StateError('Fixture pengaturan tidak tersedia');
    lastSettings = section;
  }
}

class MemoryNotebookRepository implements NotebookRepository {
  Notebook data = const Notebook();
  bool failLoad = false;
  bool failSave = false;

  @override
  Future<Notebook> load() async {
    if (failLoad) throw const FormatException('Fixture rusak');
    return data;
  }

  @override
  Future<void> save(Notebook notebook) async {
    if (failSave) throw StateError('Fixture gagal disimpan');
    data = notebook;
  }

  @override
  String exportReport(Notebook notebook) => NotebookCodec.report(notebook);
}

import 'package:flutter/material.dart';

import 'data/platform/method_channel_device_gateway.dart';
import 'data/platform/method_channel_receiver_gateway.dart';
import 'data/repositories/file_notebook_repository.dart';
import 'presentation/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final device = MethodChannelDeviceGateway();
  runApp(
    ResearchApp(
      repository: FileNotebookRepository(directoryPath: device.storagePath),
      device: device,
      receiver: MethodChannelReceiverGateway(),
    ),
  );
}

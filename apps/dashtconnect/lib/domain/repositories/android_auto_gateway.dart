import '../entities/android_auto_state.dart';

abstract interface class AndroidAutoGateway {
  Stream<AndroidAutoState> get events;
  Future<AndroidAutoState> refresh();
  Future<void> openSettings();

  /// Opens the projection screen, which connects to the phone's head unit server.
  Future<void> start();
  Future<void> stop();
}

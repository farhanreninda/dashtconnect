import '../entities/receiver_state.dart';

abstract interface class ReceiverGateway {
  Stream<ReceiverEvent> get events;
  Future<ReceiverPreparation> preparation();
  Future<ReceiverPreparation> requestPermissions();
  Future<ReceiverPreparation> prepareConnection();
  Future<void> start({required int viewId, required String phoneId});
  Future<void> stop(int viewId);

  /// Opens the share sheet for the on-device session log; false when none is recorded yet.
  Future<bool> shareDiagnostics();
}

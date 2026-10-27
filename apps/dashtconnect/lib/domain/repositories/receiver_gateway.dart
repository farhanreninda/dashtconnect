import '../entities/receiver_state.dart';

abstract interface class ReceiverGateway {
  Stream<ReceiverEvent> get events;
  Future<ReceiverPreparation> preparation();
  Future<ReceiverPreparation> requestPermissions();
  Future<ReceiverPreparation> prepareConnection();
  Future<void> start({required int viewId, required String phoneId});
  Future<void> stop(int viewId);
}

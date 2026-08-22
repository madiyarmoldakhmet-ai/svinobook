import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/services/call_service.dart';

void main() {
  test('rejectCall marks an incoming call as rejected', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('calls').doc('call-1').set({'status': 'calling'});
    final service = CallService(firestore: firestore);

    await service.rejectCall('call-1');

    expect((await firestore.collection('calls').doc('call-1').get()).data()?['status'], 'rejected');
  });

  test('endCall marks an active call as ended', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('calls').doc('call-2').set({'status': 'connected'});
    final service = CallService(firestore: firestore);

    await service.endCall('call-2');

    expect((await firestore.collection('calls').doc('call-2').get()).data()?['status'], 'ended');
  });

  test('unauthenticated users cannot start a call', () async {
    final service = CallService(firestore: FakeFirebaseFirestore());

    expect(
      () => service.makeCall('callee-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('unauthenticated users receive an empty incoming-call stream', () {
    final service = CallService(firestore: FakeFirebaseFirestore());

    expect(service.listenForCalls(), emitsDone);
  });
}

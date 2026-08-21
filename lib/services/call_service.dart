import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallSession {
  final String callId;
  final RTCPeerConnection peer;
  final MediaStream localStream;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> signaling;
  final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> candidates;

  CallSession({
    required this.callId,
    required this.peer,
    required this.localStream,
    required this.localRenderer,
    required this.remoteRenderer,
    required this.signaling,
    required this.candidates,
  });

  Future<void> dispose() async {
    await signaling.cancel();
    await candidates.cancel();
    for (final track in localStream.getTracks()) {
      track.stop();
    }
    await peer.close();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}

class CallService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingSubscription;

  CallService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  Stream<QueryDocumentSnapshot<Map<String, dynamic>>> listenForCalls() {
    if (_uid.isEmpty) return const Stream.empty();
    return _db
        .collection('calls')
        .where('calleeId', isEqualTo: _uid)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .expand((snapshot) => snapshot.docChanges
            .where((change) => change.type == DocumentChangeType.added)
            .map((change) => change.doc));
  }

  Future<CallSession> makeCall(String targetUserId, {bool video = true}) async {
    if (_uid.isEmpty) throw StateError('You must be signed in to call');
    final callRef = _db.collection('calls').doc();
    final session = await _createSession(callRef.id, video);
    final offer = await session.peer.createOffer();
    await session.peer.setLocalDescription(offer);
    await callRef.set({
      'callerId': _uid,
      'calleeId': targetUserId,
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'status': 'calling',
      'type': video ? 'video' : 'audio',
      'timestamp': FieldValue.serverTimestamp(),
      'candidates': <Map<String, dynamic>>[],
    });
    return session;
  }

  Future<CallSession> acceptCall(String callId, {bool video = true}) async {
    final callRef = _db.collection('calls').doc(callId);
    final snapshot = await callRef.get();
    final data = snapshot.data();
    if (data == null || data['offer'] == null) throw StateError('Call no longer exists');
    final session = await _createSession(callId, video);
    final offer = Map<String, dynamic>.from(data['offer'] as Map);
    await session.peer.setRemoteDescription(RTCSessionDescription(offer['sdp'] as String, offer['type'] as String));
    final answer = await session.peer.createAnswer();
    await session.peer.setLocalDescription(answer);
    await callRef.update({
      'answer': {'sdp': answer.sdp, 'type': answer.type},
      'status': 'connected',
    });
    return session;
  }

  Future<void> rejectCall(String callId) => _db.collection('calls').doc(callId).update({'status': 'rejected'});

  Future<void> endCall(String callId) => _db.collection('calls').doc(callId).update({'status': 'ended'});

  Future<CallSession> _createSession(String callId, bool video) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };
    final peer = await createPeerConnection(config);
    final localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': video});
    for (final track in localStream.getTracks()) {
      await peer.addTrack(track, localStream);
    }
    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    localRenderer.srcObject = localStream;
    peer.onTrack = (event) {
      if (event.streams.isNotEmpty) remoteRenderer.srcObject = event.streams.first;
    };
    peer.onIceCandidate = (candidate) async {
      if (candidate.candidate == null) return;
      await _db.collection('calls').doc(callId).update({
        'candidates': FieldValue.arrayUnion([{
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }]),
      });
    };

    final signaling = _db.collection('calls').doc(callId).snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;
      final answer = data['answer'];
      if (answer is Map && (await peer.getRemoteDescription()) == null) {
        await peer.setRemoteDescription(RTCSessionDescription(answer['sdp'] as String, answer['type'] as String));
      }
      if (data['status'] == 'rejected' || data['status'] == 'ended') await peer.close();
    });
    final candidates = _db.collection('calls').doc(callId).snapshots().listen((snapshot) async {
      final values = snapshot.data()?['candidates'];
      if (values is! List) return;
      for (final value in values) {
        final item = Map<String, dynamic>.from(value as Map);
        try {
          await peer.addCandidate(RTCIceCandidate(item['candidate'] as String?, item['sdpMid'] as String?, item['sdpMLineIndex'] as int?));
        } catch (_) {}
      }
    });
    return CallSession(callId: callId, peer: peer, localStream: localStream, localRenderer: localRenderer, remoteRenderer: remoteRenderer, signaling: signaling, candidates: candidates);
  }

  void dispose() {
    _incomingSubscription?.cancel();
  }
}

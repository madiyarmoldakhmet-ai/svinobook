import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/call_service.dart';
import '../utils/app_theme.dart';

class CallScreen extends StatefulWidget {
  final String targetUserId;
  final String? callId;
  final String chatName;
  final bool video;

  const CallScreen({super.key, required this.targetUserId, this.callId, required this.chatName, this.video = true});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _service = CallService();
  CallSession? _session;
  bool _muted = false;
  bool _cameraEnabled = true;
  String _status = 'Calling...';
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() { super.initState(); _start(); }

  Future<void> _start() async {
    try {
        final session = widget.callId == null
          ? await _service.makeCall(widget.targetUserId, video: widget.video)
          : await _service.acceptCall(widget.callId!, video: widget.video);
      if (!mounted) return;
      setState(() { _session = session; _status = 'Waiting for answer'; });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _seconds++); });
    } catch (e) { if (mounted) setState(() => _status = 'Call failed: $e'); }
  }

  @override
  void dispose() { _timer?.cancel(); _session?.dispose(); _service.dispose(); super.dispose(); }

  void _toggleMute() {
    final stream = _session?.localStream;
    if (stream == null) return;
    setState(() => _muted = !_muted);
    for (final track in stream.getAudioTracks()) { track.enabled = !_muted; }
  }

  void _toggleCamera() {
    final stream = _session?.localStream;
    if (stream == null || !widget.video) return;
    setState(() => _cameraEnabled = !_cameraEnabled);
    for (final track in stream.getVideoTracks()) { track.enabled = _cameraEnabled; }
  }

  Future<void> _end() async {
    final id = _session?.callId;
    if (id != null) await _service.endCall(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        if (session != null && widget.video)
          RTCVideoView(session.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
        else
          Center(child: Text(widget.chatName, style: const TextStyle(color: Colors.white, fontSize: 30))),
        if (session != null && widget.video)
          Positioned(right: 16, top: MediaQuery.of(context).padding.top + 16, width: 110, height: 150, child: RTCVideoView(session.localRenderer, mirror: true)),
        Positioned(top: MediaQuery.of(context).padding.top + 20, left: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.chatName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('$_status  ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70)),
        ])),
        Positioned(bottom: 35, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Control(icon: _muted ? Icons.mic_off : Icons.mic, onTap: _toggleMute),
          if (widget.video) _Control(icon: _cameraEnabled ? Icons.videocam : Icons.videocam_off, onTap: _toggleCamera),
          _Control(icon: Icons.call_end, color: Colors.red, onTap: _end),
        ])),
      ]),
    );
  }
}

class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String callerName;
  final bool video;
  final VoidCallback onAccepted;

  const IncomingCallScreen({super.key, required this.callId, required this.callerName, required this.video, required this.onAccepted});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(decoration: const BoxDecoration(gradient: AppColors.backgroundGradient), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(video ? Icons.videocam : Icons.phone, size: 64, color: AppColors.neonCyan),
      const SizedBox(height: 16), Text('$callerName is calling', style: const TextStyle(fontSize: 24, color: AppColors.textPrimary)),
      const SizedBox(height: 28), Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FloatingActionButton(backgroundColor: Colors.red, onPressed: () async { await CallService().rejectCall(callId); if (context.mounted) Navigator.pop(context); }, child: const Icon(Icons.call_end)),
        const SizedBox(width: 28), FloatingActionButton(backgroundColor: Colors.green, onPressed: onAccepted, child: const Icon(Icons.call)),
      ]),
    ]))),
  );
}

class _Control extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _Control({required this.icon, required this.onTap, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: IconButton(onPressed: onTap, icon: Icon(icon, color: color, size: 28), style: IconButton.styleFrom(backgroundColor: Colors.white24, padding: const EdgeInsets.all(16))));
}

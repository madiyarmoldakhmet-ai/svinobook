import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final String chatName;

  const CallScreen({super.key, required this.channelId, required this.chatName});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoEnabled = true;
  bool _isInitialized = false;
  String _statusText = "Initializing call...";
  Timer? _durationTimer;
  int _durationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _disposeAgora();
    super.dispose();
  }

  Future<void> _disposeAgora() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }
  }

  Future<void> _initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: "c2c5443e098846be82bbfa56930d6cb2",
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() {
              _localUserJoined = true;
              _statusText = "Connected";
              _startTimer();
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUid = remoteUid;
              _statusText = "In call with ${widget.chatName}";
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            setState(() {
              _remoteUid = null;
              _statusText = "User went offline";
            });
            _endCall();
          },
          onError: (ErrorCodeType err, String msg) {
            setState(() {
              _statusText = "Agora Error: $msg";
            });
          },
        ),
      );

      await _engine!.enableVideo();
      await _engine!.startPreview();

      await _engine!.joinChannel(
        token: "",
        channelId: widget.channelId.replaceAll(' ', '_'),
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print("Agora Init error: $e");
      setState(() {
        _statusText = "Simulation Mode (Agora SDK init offline)";
        _isInitialized = true;
        _localUserJoined = true;
        _startTimer();
      });
      // Simulate remote user joining after 3 seconds for demo purposes
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _remoteUid = 8888;
            _statusText = "Connected (Simulated)";
          });
        }
      });
    }
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _durationSeconds++;
      });
    });
  }

  String _formatDuration() {
    final minutes = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_durationSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine?.muteLocalAudioStream(_muted);
  }

  void _toggleVideo() {
    setState(() {
      _videoEnabled = !_videoEnabled;
    });
    if (_videoEnabled) {
      _engine?.enableVideo();
      _engine?.startPreview();
    } else {
      _engine?.disableVideo();
      _engine?.stopPreview();
    }
  }

  void _endCall() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video
          _remoteUid != null
              ? (_engine != null && _statusText != "Connected (Simulated)"
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine!,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection: RtcConnection(channelId: widget.channelId.replaceAll(' ', '_')),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF1A1A1A),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 60,
                              backgroundColor: Color(0xFF8B0000),
                              child: Icon(Icons.person, size: 60, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.chatName,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ))
              : Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF8B0000)),
                        const SizedBox(height: 24),
                        Text(
                          _statusText,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

          // Local video
          if (_localUserJoined && _videoEnabled)
            Positioned(
              right: 16,
              top: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: _engine != null && _statusText != "Connected (Simulated)"
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2D2D2D),
                          child: const Icon(Icons.camera_front, color: Colors.white54),
                        ),
                ),
              ),
            ),

          // Duration Timer
          Positioned(
            left: 16,
            top: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B0000),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Channel: ${widget.channelId}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Bottom control panel
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _muted ? Colors.white : Colors.white24,
                  child: IconButton(
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic, color: _muted ? Colors.black : Colors.white),
                    onPressed: _toggleMute,
                  ),
                ),
                const SizedBox(width: 24),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF8B0000),
                  child: IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.white, size: 28),
                    onPressed: _endCall,
                  ),
                ),
                const SizedBox(width: 24),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _videoEnabled ? Colors.white24 : Colors.white,
                  child: IconButton(
                    icon: Icon(_videoEnabled ? Icons.videocam : Icons.videocam_off, color: _videoEnabled ? Colors.white : Colors.black),
                    onPressed: _toggleVideo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

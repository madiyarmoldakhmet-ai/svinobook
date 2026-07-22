import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../utils/app_theme.dart';

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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            // Remote Video / Loading
            _remoteUid != null
                ? (_engine != null && _statusText != "Connected (Simulated)"
                    ? AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _engine!,
                          canvas: VideoCanvas(uid: _remoteUid),
                          connection: RtcConnection(channelId: widget.channelId.replaceAll(' ', '_')),
                        ),
                      )
                    : _buildSimulatedRemoteView())
                : _buildConnectingView(),

            // Local video
            if (_localUserJoined && _videoEnabled)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 110,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.4),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: _engine != null && _statusText != "Connected (Simulated)"
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine!,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : Container(
                            color: AppColors.bgMid,
                            child: const Icon(Icons.camera_front,
                                color: AppColors.neonCyan),
                          ),
                  ),
                ),
              ),

            // Duration Timer & Status
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.glassBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.glassBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonGreen
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        color: AppColors.neonCyan.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Remote name overlay
            if (_remoteUid != null && _statusText == "Connected (Simulated)")
              Positioned(
                bottom: 180,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.chatName.isNotEmpty
                              ? widget.chatName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.bgDarkest,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.chatName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom control panel
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    onPressed: _toggleMute,
                    isActive: _muted,
                  ),
                  const SizedBox(width: 24),
                  // End call button
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_end_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _buildControlButton(
                    icon: _videoEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    onPressed: _toggleVideo,
                    isActive: !_videoEnabled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? AppColors.neonCyan : AppColors.glassBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? AppColors.neonCyan
                : AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.bgDarkest : AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.chatName.isNotEmpty
                    ? widget.chatName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.bgDarkest,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.neonCyan,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Calling ${widget.chatName}...',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _statusText,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedRemoteView() {
    return Container(
      color: AppColors.bgDarkest,
      child: const SizedBox.expand(),
    );
  }
}
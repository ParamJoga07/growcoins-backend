import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import 'video_kyc_review_screen.dart';

class VideoKycRecordingScreen extends StatefulWidget {
  const VideoKycRecordingScreen({super.key});

  @override
  State<VideoKycRecordingScreen> createState() =>
      _VideoKycRecordingScreenState();
}

class _VideoKycRecordingScreenState extends State<VideoKycRecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isPermissionGranted = false;
  String? _videoPath;
  int _recordingDuration = 0;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Check current permission status
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      debugPrint('Camera permission status: $cameraStatus');
      debugPrint('Microphone permission status: $microphoneStatus');

      // Request permissions if not granted
      PermissionStatus finalCameraStatus = cameraStatus;
      PermissionStatus finalMicrophoneStatus = microphoneStatus;

      if (!cameraStatus.isGranted) {
        finalCameraStatus = await Permission.camera.request();
        debugPrint('Camera permission requested, new status: $finalCameraStatus');
      }

      if (!microphoneStatus.isGranted) {
        finalMicrophoneStatus = await Permission.microphone.request();
        debugPrint('Microphone permission requested, new status: $finalMicrophoneStatus');
      }

      if (finalCameraStatus.isGranted && finalMicrophoneStatus.isGranted) {
        setState(() {
          _isPermissionGranted = true;
        });

        try {
          _cameras = await availableCameras();
          if (_cameras != null && _cameras!.isNotEmpty) {
            _cameraController = CameraController(
              _cameras![0], // Use front camera
              ResolutionPreset.high,
              enableAudio: true,
            );

            await _cameraController!.initialize();

            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          }
        } catch (e) {
          debugPrint('Error initializing camera: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error initializing camera: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      } else {
        setState(() {
          _isPermissionGranted = false;
        });
        
        // Don't show snackbar here - the UI will show the permission prompt
        debugPrint('Permissions not granted. Camera: $finalCameraStatus, Microphone: $finalMicrophoneStatus');
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _cameraController == null) return;

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start timer
      _startTimer();

      // Stop recording after 30 seconds max
      Future.delayed(const Duration(seconds: 30), () {
        if (_isRecording) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) return;

    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = videoFile.path;
      });

      // Navigate to review screen
      if (mounted && _videoPath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoKycReviewScreen(
              videoPath: _videoPath!,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration++;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Video KYC Recording',
          style: AppTheme.headingSmall.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _cameraController != null)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            )
          else if (!_isPermissionGranted)
            _buildPermissionPrompt()
          else
            _buildLoadingState(),

          // Instructions Overlay
          if (_showInstructions && !_isRecording)
            _buildInstructionsOverlay(),

          // Recording Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildRecordingControls(),
          ),

          // Recording Timer
          if (_isRecording)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: _buildRecordingTimer(),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionPrompt() {
    return FutureBuilder<Map<Permission, PermissionStatus>>(
      future: Future.wait([
        Permission.camera.status,
        Permission.microphone.status,
      ]).then((statuses) => {
        Permission.camera: statuses[0],
        Permission.microphone: statuses[1],
      }),
      builder: (context, snapshot) {
        final cameraStatus = snapshot.data?[Permission.camera] ?? PermissionStatus.denied;
        final micStatus = snapshot.data?[Permission.microphone] ?? PermissionStatus.denied;
        final isPermanentlyDenied = cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied;

        return Container(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPermanentlyDenied ? Icons.settings_outlined : Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPermanentlyDenied
                        ? 'Permissions Required in Settings'
                        : 'Camera Permission Required',
                    style: AppTheme.headingMedium.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPermanentlyDenied
                        ? 'Camera and microphone permissions were denied. Please enable them in your device Settings to continue with video KYC.'
                        : 'We need access to your camera and microphone to record your video KYC',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!isPermanentlyDenied)
                    ElevatedButton(
                      onPressed: () async {
                        // Try requesting permissions again
                        await _initializeCamera();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Request Permissions'),
                    ),
                  if (isPermanentlyDenied) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final opened = await openAppSettings();
                          debugPrint('Settings opened: $opened');
                        } catch (e) {
                          debugPrint('Error opening app settings: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please go to Settings > Growcoins > Camera & Microphone'),
                                backgroundColor: AppTheme.errorColor,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.settings, size: 20),
                      label: const Text('Open Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildInstructionsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Recording Instructions',
                style: AppTheme.headingSmall.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please state the following clearly:\n\n'
                '1. Your full name\n'
                '2. Your date of birth\n'
                '3. "I confirm this is my identity"',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showInstructions = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got It, Start Recording'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isRecording)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isInitialized ? _startRecording : null,
                  icon: const Icon(Icons.videocam_rounded, size: 24),
                  label: const Text(
                    'Start Recording',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _stopRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.stop_rounded, size: 32),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              _isRecording
                  ? 'Tap stop when you\'re done'
                  : 'Minimum 10 seconds, Maximum 30 seconds',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingTimer() {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'pip_video_player.dart';

class VideoOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void show({
    required BuildContext context,
    required String videoId,
    required String title,
  }) {
    if (_isShowing) {
      hide();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Semi-transparent background
          GestureDetector(
            onTap: hide,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // PiP Video Player
          PipVideoPlayer(
            videoId: videoId,
            title: title,
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;
  }

  static void hide() {
    if (_overlayEntry != null && _isShowing) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }
}


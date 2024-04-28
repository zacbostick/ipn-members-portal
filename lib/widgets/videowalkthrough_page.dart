import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalkthroughHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> shouldShowWalkthrough() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return true;
    }

    DocumentSnapshot userDoc =
        await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      return true;
    }
    Map<String, dynamic> userData =
        userDoc.data() as Map<String, dynamic>? ?? {};
    bool hasSeenWalkthrough = userData['hasSeenWalkthrough'] as bool? ?? false;
    return !hasSeenWalkthrough;
  }

  static Future<void> markWalkthroughAsSeen() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({
        'hasSeenWalkthrough': true,
      });
    }
  }
}

class VideoWalkthroughScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const VideoWalkthroughScreen({super.key, required this.onFinished});

  @override
  _VideoWalkthroughScreenState createState() => _VideoWalkthroughScreenState();
}

class _VideoWalkthroughScreenState extends State<VideoWalkthroughScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/walkthrough.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
    _controller.addListener(() {
      if (!_controller.value.isPlaying &&
          _controller.value.isInitialized &&
          _controller.value.position == _controller.value.duration) {
        widget.onFinished();
        WalkthroughHelper.markWalkthroughAsSeen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 33, 36),
      body: _controller.value.isInitialized
          ? SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

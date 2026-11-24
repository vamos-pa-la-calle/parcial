import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();

  final List<String> _videos = [
    'assets/videos/video1.mp4',
    'assets/videos/video2.mp4',
    'assets/videos/video3.mp4',
    'assets/videos/video4.mp4',
  ];

  final List<VideoPlayerController?> _controllers = [null, null, null, null];

  final Set<int> _likedVideos = {};
  final Map<int, String> _videoErrors = {};

  int _currentIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo(0);
  }

  Future<void> _initializeVideo(int index) async {
    if (_controllers[index] != null) return;

    final controller = VideoPlayerController.asset(_videos[index]);
    _controllers[index] = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _videoErrors.remove(index);
      });

      if (index == _currentIndex) {
        await controller.play();
      }
    } catch (e) {
      debugPrint('Error cargando video $index: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _videoErrors[index] = e.toString();
      });
    }
  }

  Future<void> _changeVideo(int index) async {
    final previousIndex = _currentIndex;
    final previousController = _controllers[previousIndex];

    if (previousController != null && previousController.value.isInitialized) {
      await previousController.pause();
    }

    if (!mounted) return;

    setState(() {
      _currentIndex = index;
      _loading = _controllers[index] == null;
    });

    await _initializeVideo(index);

    final controller = _controllers[index];

    if (mounted &&
        index == _currentIndex &&
        controller != null &&
        controller.value.isInitialized) {
      await controller.seekTo(Duration.zero);
      await controller.play();
    }
  }

  void _togglePlay() {
    final controller = _controllers[_currentIndex];

    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    for (final controller in _controllers) {
      controller?.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: _changeVideo,
        itemBuilder: (context, index) {
          final controller = _controllers[index];
          final isCurrent = index == _currentIndex;

          return GestureDetector(
            onTap: isCurrent ? _togglePlay : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.black),

                if (_videoErrors.containsKey(index))
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No se pudo cargar el video ${index + 1}.\n'
                        '${_videoErrors[index]}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (controller == null || !controller.value.isInitialized)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.pink),
                  )
                else
                  Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),

                if (isCurrent &&
                    controller != null &&
                    controller.value.isInitialized &&
                    !controller.value.isPlaying)
                  const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 85,
                    ),
                  ),

                Positioned(
                  top: 35,
                  left: 15,
                  right: 15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PARCIAL VIDEOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 35,
                  left: 15,
                  right: 15,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '@${user?.displayName ?? user?.email ?? 'usuario'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Disfrutando del video ${index + 1} '
                              '#Flutter #Videos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if (_likedVideos.contains(index)) {
                                  _likedVideos.remove(index);
                                } else {
                                  _likedVideos.add(index);
                                }
                              });
                            },
                            icon: Icon(
                              _likedVideos.contains(index)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _likedVideos.contains(index)
                                  ? Colors.red
                                  : Colors.white,
                              size: 35,
                            ),
                          ),
                          const Text(
                            'Me gusta',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 18),
                          const Icon(
                            Icons.comment,
                            color: Colors.white,
                            size: 32,
                          ),
                          const Text(
                            'Comentar',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 18),
                          const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 32,
                          ),
                          const Text(
                            'Compartir',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

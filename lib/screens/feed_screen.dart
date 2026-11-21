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

  final List<VideoPlayerController> _controllers = [];

  int _currentIndex = 0;
  bool _ready = false;
  String? _error;

  final Set<int> _likedVideos = {};

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    try {
      for (final video in _videos) {
        final controller = VideoPlayerController.asset(video);
        _controllers.add(controller);

        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(1);
      }

      if (!mounted) return;

      setState(() {
        _ready = true;
      });

      await _controllers[0].play();
    } catch (e) {
      debugPrint('Error cargando videos: $e');

      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los videos. Revisa los archivos MP4.';
        });
      }
    }
  }

  void _changeVideo(int index) {
    _controllers[_currentIndex].pause();

    setState(() {
      _currentIndex = index;
    });

    _controllers[index].seekTo(Duration.zero);
    _controllers[index].play();
  }

  void _togglePlay() {
    final controller = _controllers[_currentIndex];

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
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: _changeVideo,
        itemBuilder: (context, index) {
          final controller = _controllers[index];

          return GestureDetector(
            onTap: index == _currentIndex ? _togglePlay : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),

                if (index == _currentIndex && !controller.value.isPlaying)
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
                              'Disfrutando del video ${index + 1} #Flutter #Videos',
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

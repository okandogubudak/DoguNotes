import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideoViewer extends StatefulWidget {
  final String videoPath;

  const FullScreenVideoViewer({
    super.key,
    required this.videoPath,
  });

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _animationController;
  bool _isControlsVisible = true;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationController.forward();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _initializeVideo();
    
    // Auto-hide controls after 3 seconds
    _autoHideControls();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        _showError('Video dosyası bulunamadı');
        return;
      }

      _videoController = VideoPlayerController.file(file);
      
      // Video initialization'ı timeout ile koru
      await _videoController.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Video yükleme zaman aşımına uğradı');
        },
      );
      
      if (!_videoController.value.isInitialized) {
        _showError('Video başlatılamadı');
        return;
      }
      
      _videoController.addListener(() {
        if (mounted) {
          setState(() {
            _isBuffering = _videoController.value.isBuffering;
          });
          
          // Video bittiğinde kontrolleri göster
          if (_videoController.value.position >= _videoController.value.duration) {
            setState(() {
              _isControlsVisible = true;
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Video'yu otomatik başlat
        await _videoController.play();
      }
      
    } catch (e) {
      _showError('Video yükleme hatası: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isControlsVisible) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
    
    if (_isControlsVisible) {
      _autoHideControls();
    }
  }

  void _togglePlayPause() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
    _autoHideControls();
  }

  void _seekTo(double value) {
    final duration = _videoController.value.duration;
    final position = duration * value;
    _videoController.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  void _closeViewer() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _animationController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          // Restore system UI when popping
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
              overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _hasError 
          ? _buildErrorWidget()
          : !_isInitialized 
            ? _buildLoadingWidget()
            : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error,
              color: Colors.red,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'Video Hatası',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          
          ElevatedButton.icon(
            onPressed: _closeViewer,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.9),
              foregroundColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Video Yükleniyor...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          const CircularProgressIndicator(
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // Video Player
          Center(
            child: AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            ),
          ),
          
          // Buffering indicator
          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          
          // Controls overlay
          AnimatedOpacity(
            opacity: _isControlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Top controls
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _closeViewer,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                                                     Expanded(
                             child: Text(
                               widget.videoPath.split('/').last,
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 16,
                                 fontWeight: FontWeight.w600,
                               ),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Center play/pause button
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _videoController.value.isPlaying 
                            ? Icons.pause 
                            : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Bottom controls
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Progress bar
                          ValueListenableBuilder(
                            valueListenable: _videoController,
                            builder: (context, VideoPlayerValue value, child) {
                              return Row(
                                children: [
                                  Text(
                                    _formatDuration(value.position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.white.withOpacity(0.2),
                                        trackHeight: 3,
                                      ),
                                      child: Slider(
                                        value: value.duration.inMilliseconds > 0
                                            ? value.position.inMilliseconds / 
                                              value.duration.inMilliseconds
                                            : 0.0,
                                        onChanged: _seekTo,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDuration(value.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Control buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  final currentPosition = _videoController.value.position;
                                  final newPosition = currentPosition - const Duration(seconds: 10);
                                  _videoController.seekTo(newPosition);
                                },
                                icon: const Icon(
                                  Icons.replay_10,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 40),
                              IconButton(
                                onPressed: _togglePlayPause,
                                icon: Icon(
                                  _videoController.value.isPlaying 
                                    ? Icons.pause_circle_filled 
                                    : Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 56,
                                ),
                              ),
                              const SizedBox(width: 40),
                              IconButton(
                                onPressed: () {
                                  final currentPosition = _videoController.value.position;
                                  final newPosition = currentPosition + const Duration(seconds: 10);
                                  _videoController.seekTo(newPosition);
                                },
                                icon: const Icon(
                                  Icons.forward_10,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
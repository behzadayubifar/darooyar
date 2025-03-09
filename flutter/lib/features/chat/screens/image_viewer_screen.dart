import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final bool isNetworkImage;
  final String? heroTag;

  const ImageViewerScreen({
    Key? key,
    required this.imageUrl,
    required this.isNetworkImage,
    this.heroTag,
  }) : super(key: key);

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final TransformationController _transformationController =
      TransformationController();
  late TapDownDetails _doubleTapDetails;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    // Set preferred orientations to allow rotation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset to portrait only when closing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // If already zoomed in, zoom out
      _transformationController.value = Matrix4.identity();
    } else {
      // If zoomed out, zoom in on the tapped point
      final position = _doubleTapDetails.localPosition;
      // Zoom to 2.5x at the tap position
      final Matrix4 newMatrix = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
      _transformationController.value = newMatrix;
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('مشاهده تصویر',
                  style: TextStyle(color: Colors.white)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _toggleFullScreen,
                  tooltip: 'تمام صفحه',
                ),
              ],
            ),
      body: GestureDetector(
        onTap: _isFullScreen ? _toggleFullScreen : null,
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onDoubleTapDown: _handleDoubleTapDown,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: widget.isNetworkImage
                      ? Hero(
                          tag: widget.heroTag ?? 'image_default',
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            cacheKey: "${widget.imageUrl.hashCode}_key",
                            memCacheWidth: 1200,
                            memCacheHeight: 1200,
                            maxHeightDiskCache: 1200,
                            maxWidthDiskCache: 1200,
                            useOldImageOnUrlChange: true,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error,
                                    color: Colors.white, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'خطا در بارگذاری تصویر',
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            fit: BoxFit.contain,
                          ),
                        )
                      : Hero(
                          tag: widget.heroTag ?? 'image_default',
                          child: Image.file(
                            File(widget.imageUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error,
                                    color: Colors.white, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'خطا در نمایش تصویر\n$error',
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            if (_isFullScreen)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  onPressed: _toggleFullScreen,
                  tooltip: 'خروج از حالت تمام صفحه',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

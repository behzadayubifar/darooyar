import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/image_viewer_screen.dart';

class ChatImageWidget extends StatelessWidget {
  final String content;

  const ChatImageWidget({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a unique tag for Hero animation
    final String heroTag = 'image_${content.hashCode}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(
                  imageUrl: content,
                  isNetworkImage: content.startsWith('http'),
                  heroTag: heroTag,
                ),
                // Preserve state when returning from image viewer
                maintainState: true,
              ),
            );
          },
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: content.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: content,
                      cacheKey: "${content.hashCode}_key",
                      memCacheWidth: 800,
                      memCacheHeight: 800,
                      maxHeightDiskCache: 800,
                      maxWidthDiskCache: 800,
                      useOldImageOnUrlChange: true,
                      httpHeaders: {
                        'Accept': '*/*', // Try accepting all content types
                      },
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => SizedBox(
                        height: 160,
                        width: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              const Flexible(
                                child: Text(
                                  'در حال بارگذاری تصویر...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        // Log error for debugging
                        print('Error loading image from $url: $error');

                        return GestureDetector(
                          onTap: () {
                            // Attempt to redownload the image on tap
                            CachedNetworkImage.evictFromCache(url);
                            // Force rebuild
                            (context as Element).markNeedsBuild();
                          },
                          child: Container(
                            height: 160,
                            width: 200,
                            color: Colors.grey[800],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white, size: 32),
                                  const SizedBox(height: 8),
                                  Flexible(
                                    child: Text(
                                      'خطا در بارگذاری تصویر\nلمس برای بارگذاری مجدد',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 10),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      fit: BoxFit.contain,
                      imageBuilder: (context, imageProvider) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          child: Image(
                            image: imageProvider,
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    )
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: Image.file(
                        File(content),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Log error for debugging
                          print(
                              'Error loading local image from $content: $error');
                          return Container(
                            height: 160,
                            width: 200,
                            color: Colors.grey[800],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white, size: 32),
                                  const SizedBox(height: 8),
                                  Flexible(
                                    child: Text(
                                      'خطا در نمایش تصویر\n${error.toString().substring(0, error.toString().length > 40 ? 40 : error.toString().length)}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 10),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تصویر نسخه',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            if (content.startsWith('http')) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  try {
                    // Try opening the image URL in browser
                    final Uri url = Uri.parse(content);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    print('Error launching URL: $e');
                  }
                },
                child: const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

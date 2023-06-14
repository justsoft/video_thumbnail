import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/src/video_thumbnail.dart';

/// Video thumbnail image provider
class VideoThumbnailImage extends ImageProvider<VideoThumbnailImage> {
  /// Video Uri
  final String videoUri;

  /// Http request headers
  final Map<String, String>? headers;

  /// Specify which time to get the thumbnail (unit: milliseconds)
  final int timeMs;

  final ImageFormat imageFormat;

  /// Specify the maximum width for the thumbnail or 0 for same resolution as
  /// the original video.
  final int maxWidth;

  /// Specify the maximum height for the thumbnail or 0 for same resolution as
  /// the original video.
  final int maxHeight;

  /// The lower quality value creates lower quality of the thumbnail image, but
  /// it gets ignored for PNG format.
  final int quality;

  /// Whether to enable caching thumbnails to disk
  /// default: false
  final bool enableDiskCache;

  /// The path to cache thumbnails
  ///
  /// Generates a thumbnail file under specified thumbnail folder or given full
  /// path and name which matches expected ext.
  ///
  /// If the thumbnailPath is ommited or null, a thumbnail image file will be
  /// created under the same folder as the video file.
  ///
  /// example:
  /// - /path/to/thumbnail_cache/
  /// - /path/to/thumbnail_cache/thumbnail01.jpg
  final String? diskCachePath;

  const VideoThumbnailImage(
    this.videoUri, {
    this.timeMs = 0,
    this.maxWidth = 0,
    this.maxHeight = 0,
    this.quality = 10,
    this.imageFormat = ImageFormat.PNG,
    this.headers,
    this.enableDiskCache = false,
    this.diskCachePath,
  });

  @override
  Future<VideoThumbnailImage> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
      VideoThumbnailImage key, DecoderBufferCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(
    VideoThumbnailImage key,
    DecoderBufferCallback decode,
  ) async {
    assert(key == this);

    final buffer = await _loadThumbnailBuffer(key);
    final codec = await decode(buffer);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    return ImageInfo(image: image);
  }

  Future<ImmutableBuffer> _loadThumbnailBuffer(VideoThumbnailImage key) async {
    if (enableDiskCache) {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUri,
        thumbnailPath: diskCachePath,
        headers: headers,
        imageFormat: key.imageFormat,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        timeMs: timeMs,
      );
      if (thumbnail == null) {
        throw Exception('Not found thumbnail[file] at ${timeMs}ms');
      }
      return ImmutableBuffer.fromFilePath(thumbnail);
    }

    final thumbnail = await VideoThumbnail.thumbnailData(
      video: videoUri,
      headers: headers,
      imageFormat: key.imageFormat,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
      timeMs: timeMs,
    );
    if (thumbnail == null) {
      throw Exception('Not found thumbnail at ${timeMs}ms');
    }
    return ImmutableBuffer.fromUint8List(thumbnail);
  }

  @override
  int get hashCode =>
      Object.hash(videoUri, timeMs, maxWidth, maxHeight, quality, imageFormat);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is VideoThumbnailImage &&
        other.videoUri == videoUri &&
        other.timeMs == timeMs &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight &&
        other.quality == quality &&
        other.imageFormat == imageFormat;
  }
}

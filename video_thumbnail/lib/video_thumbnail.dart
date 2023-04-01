/// The Flutter plugin for creating thumbnail from video
///
/// To use, import `package:video_thumbnail/video_thumbnail.dart`.
///
/// See also:
///
///  * [video_thumbnail](https://pub.dev/packages/video_thumbnail)
///
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Support most popular image formats.
/// Uses libwebp to encode WebP image on iOS platform.
enum ImageFormat { JPEG, PNG, WEBP }

class VideoThumbnail {
  static const MethodChannel _channel =
      const MethodChannel('plugins.justsoft.xyz/video_thumbnail');

  /// Generates a thumbnail file under specified thumbnail folder or given full path and name which matches expected ext.
  /// The video can be a local video file, or an URL repreents iOS or Android native supported video format.
  /// If the thumbnailPath is ommited or null, a thumbnail image file will be created under the same folder as the video file.
  /// Specify the maximum height or width for the thumbnail or 0 for same resolution as the original video.
  /// The lower quality value creates lower quality of the thumbnail image, but it gets ignored for PNG format.
  static Future<String?> thumbnailFile(
      {required String video,
      Map<String, String>? headers,
      String? thumbnailPath,
      ImageFormat imageFormat = ImageFormat.PNG,
      int maxHeight = 0,
      int maxWidth = 0,
      int timeMs = 0,
      int quality = 10}) async {
    assert(video.isNotEmpty);
    if (video.isEmpty) return null;
    final reqMap = <String, dynamic>{
      'video': video,
      'headers': headers,
      'path': thumbnailPath,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': timeMs,
      'quality': quality
    };
    return await _channel.invokeMethod('file', reqMap);
  }

  /// Generates a thumbnail image data in memory as UInt8List, it can be easily used by Image.memory(...).
  /// The video can be a local video file, or an URL repreents iOS or Android native supported video format.
  /// Specify the maximum height or width for the thumbnail or 0 for same resolution as the original video.
  /// The lower quality value creates lower quality of the thumbnail image, but it gets ignored for PNG format.
  static Future<Uint8List?> thumbnailData({
    required String video,
    Map<String, String>? headers,
    ImageFormat imageFormat = ImageFormat.PNG,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    assert(video.isNotEmpty);
    final reqMap = <String, dynamic>{
      'video': video,
      'headers': headers,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': timeMs,
      'quality': quality,
    };
    return await _channel.invokeMethod('data', reqMap);
  }
}

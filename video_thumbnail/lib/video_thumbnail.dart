/// The Flutter plugin for creating thumbnail from video
///
/// To use, import `package:video_thumbnail/video_thumbnail.dart`.
///
/// See also:
///
///  * [video_thumbnail](https://pub.dev/packages/video_thumbnail)
///
import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail_platform_interface/video_thumbnail_platform_interface.dart';

export 'package:cross_file/cross_file.dart' show XFile;
export 'package:video_thumbnail_platform_interface/video_thumbnail_platform_interface.dart'
    show ImageFormat;

class VideoThumbnail {
  /// Generates a thumbnail file under specified thumbnail folder or given full path and name which matches expected ext.
  /// The video can be a local video file, or an URL repreents iOS or Android native supported video format.
  /// If the thumbnailPath is ommited or null, a thumbnail image file will be created under the same folder as the video file.
  /// Specify the maximum height or width for the thumbnail or 0 for same resolution as the original video.
  /// The lower quality value creates lower quality of the thumbnail image, but it gets ignored for PNG format.
  static Future<XFile> thumbnailFile({
    required String video,
    Map<String, String>? headers,
    String? thumbnailPath,
    ImageFormat imageFormat = ImageFormat.PNG,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    assert(video.isNotEmpty);

    return VideoThumbnailPlatform.instance.thumbnailFile(
      video: video,
      headers: headers,
      thumbnailPath: thumbnailPath,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );
  }

  /// Generates a thumbnail image data in memory as UInt8List, it can be easily used by Image.memory(...).
  /// The video can be a local video file, or an URL repreents iOS or Android native supported video format.
  /// Specify the maximum height or width for the thumbnail or 0 for same resolution as the original video.
  /// The lower quality value creates lower quality of the thumbnail image, but it gets ignored for PNG format.
  static Future<Uint8List> thumbnailData({
    required String video,
    Map<String, String>? headers,
    ImageFormat imageFormat = ImageFormat.PNG,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    assert(video.isNotEmpty);

    return VideoThumbnailPlatform.instance.thumbnailData(
      video: video,
      headers: headers,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );
  }
}

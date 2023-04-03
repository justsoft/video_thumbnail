import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail_platform_interface/src/image_format.dart';
import 'package:video_thumbnail_platform_interface/src/video_thumbnail_platform.dart';

/// An implementation of [VideoThumbnailPlatform] that uses method channels.
class MethodChannelVideoThumbnail extends VideoThumbnailPlatform {
  /// The method channel used to interact with the native platform.
  static const methodChannel =
      MethodChannel('plugins.justsoft.xyz/video_thumbnail');

  @override
  Future<XFile?> thumbnailFile({
    required String video,
    required Map<String, String>? headers,
    required String? thumbnailPath,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) async {
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

    final path = await methodChannel.invokeMethod<String>('file', reqMap);
    return path == null ? null : XFile(path);
  }

  @override
  Future<Uint8List?> thumbnailData({
    required String video,
    required Map<String, String>? headers,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) {
    final reqMap = <String, dynamic>{
      'video': video,
      'headers': headers,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': timeMs,
      'quality': quality,
    };
    return methodChannel.invokeMethod('data', reqMap);
  }
}

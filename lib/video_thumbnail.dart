import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ImageFormat { JPEG, PNG, WEBP }

class VideoThumbnail {
  static const MethodChannel _channel = const MethodChannel('video_thumbnail');

  static Future<String> thumbnailFile(
      {@required String video,
      String thumbnailPath,
      ImageFormat imageFormat,
      int maxHeightOrWidth = 0,
      int quality}) async {
    assert(video != null && video.isNotEmpty);
    final reqMap = <String, dynamic>{
      'video': video,
      'path': thumbnailPath,
      'format': imageFormat.index,
      'maxhow': maxHeightOrWidth,
      'quality': quality
    };
    return await _channel.invokeMethod('file', reqMap);
  }

  // quality has 0 - 100, higher then 70 will generate a bigger thumbnail
  static Future<Uint8List> thumbnailData(
      {@required String video,
      ImageFormat imageFormat,
      int maxHeightOrWidth = 0,
      int quality}) async {
    assert(video != null && video.isNotEmpty);
    final reqMap = <String, dynamic>{
      'video': video,
      'format': imageFormat.index,
      'maxhow': maxHeightOrWidth,
      'quality': quality
    };
    return await _channel.invokeMethod('data', reqMap);
  }
}

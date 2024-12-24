import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

void main() {
  const MethodChannel channel =
      MethodChannel('plugins.justsoft.xyz/video_thumbnail');

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      final m = methodCall.method;
      final a = methodCall.arguments;

      return '$m=${a["video"]}:${a["path"]}:${a["format"]}:${a["maxh"]}:${a["maxw"]}:${a["quality"]}';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('thumbnailData', () async {
    expect(
        await VideoThumbnail.thumbnailFile(
            video: 'video',
            thumbnailPath: 'path',
            imageFormat: ImageFormat.JPEG,
            maxHeight: 123,
            maxWidth: 124,
            quality: 45),
        'file=video:path:0:123:124:45');
  });
}

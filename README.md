# video_thumbnail

This plugin generates image thumbnails from video files or URLs on both Android and iOS. It returns an image in memory or saves it as a file with customizable format, resolution, and quality.

  [![pub ver](https://img.shields.io/badge/pub-v0.5.6-blue)](https://pub.dev/packages/video_thumbnail)
  [![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/justsoft/)

![video-file](https://github.com/justsoft/video_thumbnail/blob/master/video_file.png?raw=true) ![video-url](https://github.com/justsoft/video_thumbnail/blob/master/video_url.png?raw=true)

## Methods
|function|parameter|description|return|
|--|--|--|--|
|thumbnailData|String `[video]`, optional Map<String, dynamic> `[headers]`, ImageFormat `[imageFormat]`(JPEG/PNG/WEBP), int `[maxHeight]`(0: for the original resolution of the video, or scaled by the source aspect ratio), [maxWidth]`(0: for the original resolution of the video, or scaled by the source aspect ratio), int `[timeMs]` generates the thumbnail from the frame around the specified millisecond, int `[quality]`(0-100)|generates thumbnail from `[video]`|`[Future<Uint8List>]`|
|thumbnailFile|String `[video]`, optional Map<String, dynamic> `[headers]`, String `[thumbnailPath]`(folder or full path where to store the thumbnail file, null to save to same folder as the video file), ImageFormat `[imageFormat]`(JPEG/PNG/WEBP), int `[maxHeight]`(0: for the original resolution of the video, or scaled by the source aspect ratio), int `[maxWidth]`(0: for the original resolution of the video, or scaled by the source aspect ratio), int `[timeMs]` generates the thumbnail from the frame around the specified millisecond, int `[quality]`(0-100)|creates a file of the thumbnail from the `[video]` |`[Future<String>]`|

Warning:
> Giving both the `maxHeight` and `maxWidth` has different result on Android platform, it actually scales the thumbnail to the specified maxHeight and maxWidth.
> To generate the thumbnail from a network resource, the `video` must be properly URL encoded.

## Usage

**Installing**
add [video_thumbnail](https://pub.dev/packages/video_thumbnail) as a dependency in your pubspec.yaml file.
```yaml
dependencies:
  video_thumbnail: ^0.5.6
```
**import**
```dart
import 'package:video_thumbnail/video_thumbnail.dart';
```
**Generate a thumbnail in memory from video file**
```dart
final uint8list = await VideoThumbnail.thumbnailData(
  video: videofile.path,
  imageFormat: ImageFormat.JPEG,
  maxWidth: 128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
  quality: 25,
);
```

**Generate a thumbnail file from video URL**
```dart
final fileName = await VideoThumbnail.thumbnailFile(
  video: "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
  thumbnailPath: (await getTemporaryDirectory()).path,
  imageFormat: ImageFormat.WEBP,
  maxHeight: 64, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
  quality: 75,
);
```

**Generate a thumbnail file from video Assets declared in pubspec.yaml**
```dart
final byteData = await rootBundle.load("assets/my_video.mp4");
Directory tempDir = await getTemporaryDirectory();

File tempVideo = File("${tempDir.path}/assets/my_video.mp4")
  ..createSync(recursive: true)
  ..writeAsBytesSync(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

final fileName = await VideoThumbnail.thumbnailFile(
  video: tempVideo.path,
  thumbnailPath: (await getTemporaryDirectory()).path,
  imageFormat: ImageFormat.PNG,  
  quality: 100,
);
```

## Notes
Fork or pull requests are always welcome. Currently it seems have a little performance issue while generating WebP thumbnail by using libwebp under iOS.

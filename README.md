# video_thumbnail

This plugin generates thumbnail from video file or URL.  It returns image in memory or writes into a file.  It offers rich options to control the image format, resolution and quality.  Supports iOS and Android.

  [![pub ver](https://img.shields.io/badge/pb-v0.1.3-blue.svg)](https://pub.dev/packages/video_thumbnail)
  [![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/justsoft/)

## Methods
|function|parameter|description|return|
|--|--|--|--|
|thumbnailData|String `[video]`, ImageFormat `[imageFormat]`(JPEG/PNG/WEBP), int `[maxHeightOrWidth]`(0: for the original resolution of the video), int `[quality]`(0-100)|generates thumbnail from `[video]`|`[Future<Uint8List>]`|
|thumbnailFile|String `[video]`, String `[thumbnailPath]`(folder or full path where to store the thumbnail file, null to save to same folder as the video file), ImageFormat `[imageFormat]`(JPEG/PNG/WEBP), int `[maxHeightOrWidth]`(0: for the original resolution of the video), int `[quality]`(0-100)|creates a file of the thumbnail from the `[video]` |`[Future<String>]`|

## Usage

**Installing**
add [video_thumbnail](https://pub.dev/packages/video_thumbnail) as a dependency in your pubspec.yaml file.
```yaml
dependencies:
  video_thumbnail: ^0.1.3
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
  maxHeightOrWidth: 128,
  quality: 25,
);
```

**Generate a thumbnail file from video URL**
```dart
final uint8list = await VideoThumbnail.thumbnailFile(
  video: "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
  thumbnailPath: (await getTemporaryDirectory()).path,
  imageFormat: ImageFormat.WEBP,
  maxHeightOrWidth: 0, // the original resolution of the video
  quality: 75,
);
```

## Notes
Fork or pull requests are alway welcome. It seems have little performance issue while generating WebP thumbnail by libwebp under iOS.

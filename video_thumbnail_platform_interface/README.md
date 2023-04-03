# video_thumbnail_platform_interface

A common platform interface for the [`video_thumbnail`][1] plugin.

This interface allows platform-specific implementations of the `video_thumbnail` plugin, as well as the plugin itself, to ensure they are supporting the same interface.

# Usage

To implement a new platform-specific implementation of `video_thumbnail`, extend [`VideoThumbnailPlatform`][2] with an implementation that performs the platform-specific behavior, and when you register your plugin, set the default `VideoThumbnailPlatform` by calling `VideoThumbnailPlatform.instance = MyPlatformVideoThumbnail()`.

[1]: ../video_thumbnail
[2]: lib/video_thumbnail_platform_interface.dart
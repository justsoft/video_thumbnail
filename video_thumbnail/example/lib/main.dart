import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DemoHome(),
    );
  }
}

class ThumbnailRequest {
  const ThumbnailRequest({
    required this.video,
    required this.thumbnailPath,
    required this.imageFormat,
    required this.maxHeight,
    required this.maxWidth,
    required this.timeMs,
    required this.quality,
    required this.attachHeaders,
  });

  final String video;
  final String? thumbnailPath;
  final ImageFormat imageFormat;
  final int maxHeight;
  final int maxWidth;
  final int timeMs;
  final int quality;
  final bool attachHeaders;
}

class ThumbnailResult {
  const ThumbnailResult({
    required this.image,
    required this.dataSize,
    required this.height,
    required this.width,
  });

  final Image image;
  final int dataSize;
  final int height;
  final int width;
}

Future<ThumbnailResult> genThumbnail(ThumbnailRequest r) async {
  Uint8List bytes;
  final completer = Completer<ThumbnailResult>();
  if (r.thumbnailPath != null) {
    final thumbnailFile = await VideoThumbnail.thumbnailFile(
      video: r.video,
      headers: r.attachHeaders
          ? const {
              'USERHEADER1': 'user defined header1',
              'USERHEADER2': 'user defined header2',
            }
          : null,
      thumbnailPath: r.thumbnailPath,
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    );

    debugPrint('thumbnail file is located: $thumbnailFile');

    bytes = await thumbnailFile!.readAsBytes();
  } else {
    bytes = (await VideoThumbnail.thumbnailData(
      video: r.video,
      headers: r.attachHeaders
          ? const {
              'USERHEADER1': 'user defined header1',
              'USERHEADER2': 'user defined header2',
            }
          : null,
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    ))!;
  }

  final imageDataSize = bytes.length;
  debugPrint('image size: $imageDataSize');

  final image = Image.memory(bytes);
  image.image.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener(
          (ImageInfo info, bool _) {
            completer.complete(
              ThumbnailResult(
                image: image,
                dataSize: imageDataSize,
                height: info.image.height,
                width: info.image.width,
              ),
            );
          },
          onError: completer.completeError,
        ),
      );
  return completer.future;
}

class GenThumbnailImage extends StatefulWidget {
  const GenThumbnailImage({
    Key? key,
    required this.thumbnailRequest,
  }) : super(key: key);
  final ThumbnailRequest thumbnailRequest;

  @override
  State<GenThumbnailImage> createState() => _GenThumbnailImageState();
}

class _GenThumbnailImageState extends State<GenThumbnailImage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThumbnailResult>(
      future: genThumbnail(widget.thumbnailRequest),
      builder: (BuildContext context, AsyncSnapshot<ThumbnailResult> snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          final image = data.image;
          final width = data.width;
          final height = data.height;
          final dataSize = data.dataSize;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Text(
                  "Image ${widget.thumbnailRequest.thumbnailPath == null ? 'data size' : 'file size'}: $dataSize, width:$width, height:$height",
                ),
              ),
              Container(color: Colors.grey),
              image,
            ],
          );
        } else if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red,
            child: Text('Error:\n${snapshot.error}\n\n${snapshot.stackTrace}'),
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Generating the thumbnail for: ${widget.thumbnailRequest.video}...',
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(),
            ],
          );
        }
      },
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({Key? key}) : super(key: key);

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  final _editNode = FocusNode();
  final _video = TextEditingController(
    text:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  );
  ImageFormat _format = ImageFormat.JPEG;
  int _quality = 50;
  bool _attachHeaders = false;
  int _sizeH = 0;
  int _sizeW = 0;
  int _timeMs = 0;

  GenThumbnailImage? _futureImage;

  String? _tempDir;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      getTemporaryDirectory().then((d) => _tempDir = d.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = <Widget>[
      Slider(
        value: _sizeH * 1.0,
        onChanged: (v) => setState(() {
          _editNode.unfocus();
          _sizeH = v.toInt();
        }),
        max: 256,
        divisions: 256,
        label: '$_sizeH',
      ),
      Center(
        child: (_sizeH == 0)
            ? const Text(
                "Original of the video's height or scaled by the source aspect ratio",
              )
            : Text('Max height: $_sizeH(px)'),
      ),
      Slider(
        value: _sizeW * 1.0,
        onChanged: (v) => setState(() {
          _editNode.unfocus();
          _sizeW = v.toInt();
        }),
        max: 256,
        divisions: 256,
        label: '$_sizeW',
      ),
      Center(
        child: (_sizeW == 0)
            ? const Text(
                "Original of the video's width or scaled by source aspect ratio",
              )
            : Text('Max width: $_sizeW(px)'),
      ),
      Slider(
        value: _timeMs * 1.0,
        onChanged: (v) => setState(() {
          _editNode.unfocus();
          _timeMs = v.toInt();
        }),
        max: 10.0 * 1000,
        divisions: 1000,
        label: '$_timeMs',
      ),
      Center(
        child: (_timeMs == 0)
            ? const Text('The beginning of the video')
            : Text('The closest frame at $_timeMs(ms) of the video'),
      ),
      Slider(
        value: _quality * 1.0,
        onChanged: (v) => setState(() {
          _editNode.unfocus();
          _quality = v.toInt();
        }),
        max: 100,
        divisions: 100,
        label: '$_quality',
      ),
      Center(child: Text('Quality: $_quality')),
      SwitchListTile(
        title: const Text('Attach Headers'),
        value: _attachHeaders,
        onChanged: (value) => setState(() => _attachHeaders = value),
        secondary: const Icon(Icons.http),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            isDense: true,
            labelText: 'Thumbnail Format',
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Radio<ImageFormat>(
                    groupValue: _format,
                    value: ImageFormat.JPEG,
                    onChanged: (v) => setState(() {
                      _format = v!;
                      _editNode.unfocus();
                    }),
                  ),
                  const Text('JPEG'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Radio<ImageFormat>(
                    groupValue: _format,
                    value: ImageFormat.PNG,
                    onChanged: (v) => setState(() {
                      _format = v!;
                      _editNode.unfocus();
                    }),
                  ),
                  const Text('PNG'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Radio<ImageFormat>(
                    groupValue: _format,
                    value: ImageFormat.WEBP,
                    onChanged: (v) => setState(() {
                      _format = v!;
                      _editNode.unfocus();
                    }),
                  ),
                  const Text('WebP'),
                ],
              ),
            ],
          ),
        ),
      )
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thumbnail Plugin example'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                isDense: true,
                labelText: 'Video URI',
              ),
              maxLines: null,
              controller: _video,
              focusNode: _editNode,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onEditingComplete: _editNode.unfocus,
            ),
          ),
          for (var i in settings) i,
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  if (_futureImage != null) _futureImage! else const SizedBox(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () async {
              final video =
                  await ImagePicker().pickVideo(source: ImageSource.camera);
              setState(() {
                _video.text = video?.path ?? '';
              });
            },
            tooltip: 'Capture a video',
            child: const Icon(Icons.videocam),
          ),
          const SizedBox(
            width: 5,
          ),
          FloatingActionButton(
            onPressed: () async {
              final video =
                  await ImagePicker().pickVideo(source: ImageSource.gallery);
              setState(() {
                _video.text = video?.path ?? '';
              });
            },
            tooltip: 'Pick a video',
            child: const Icon(Icons.local_movies),
          ),
          const SizedBox(
            width: 20,
          ),
          FloatingActionButton(
            tooltip: 'Generate a data of thumbnail',
            onPressed: () async {
              setState(() {
                _futureImage = GenThumbnailImage(
                  thumbnailRequest: ThumbnailRequest(
                    video: _video.text,
                    thumbnailPath: null,
                    imageFormat: _format,
                    maxHeight: _sizeH,
                    maxWidth: _sizeW,
                    timeMs: _timeMs,
                    quality: _quality,
                    attachHeaders: _attachHeaders,
                  ),
                );
              });
            },
            child: const Text('Data'),
          ),
          const SizedBox(
            width: 5,
          ),
          FloatingActionButton(
            tooltip: 'Generate a file of thumbnail',
            onPressed: () async {
              setState(() {
                _futureImage = GenThumbnailImage(
                  thumbnailRequest: ThumbnailRequest(
                    video: _video.text,
                    thumbnailPath: _tempDir,
                    imageFormat: _format,
                    maxHeight: _sizeH,
                    maxWidth: _sizeW,
                    timeMs: _timeMs,
                    quality: _quality,
                    attachHeaders: _attachHeaders,
                  ),
                );
              });
            },
            child: const Text('File'),
          ),
        ],
      ),
    );
  }
}

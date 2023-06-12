# Video Player plugin for Flutter

[![pub package](https://img.shields.io/pub/v/video_player.svg)](https://pub.dev/packages/video_player)

A Flutter plugin for iOS, Android and Web for playing back video on a Widget surface.

![The example app running in iOS](https://github.com/flutter/plugins/blob/master/packages/video_player/video_player/doc/demo_ipod.gif?raw=true)

## Installation

First, add `video_player` as a [dependency in your pubspec.yaml file](https://flutter.dev/using-packages/).

### iOS

This plugin requires iOS 9.0 or higher. Add the following entry to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

This entry allows your app to access video files by URL.

### Android

Ensure the following permission is present in your Android Manifest file, located in `<project root>/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

The Flutter project template adds it, so it may already be there.

### Web

This plugin compiles for the web platform since version `0.10.5`, in recent enough versions of Flutter (`>=1.12.13+hotfix.4`).

> The Web platform does **not** suppport `dart:io`, so avoid using the `VideoPlayerController.file` constructor for the plugin. Using the constructor attempts to create a `VideoPlayerController.file` that will throw an `UnimplementedError`.

Different web browsers may have different video-playback capabilities (supported formats, autoplay...). Check [package:video_player_web](https://pub.dev/packages/video_player_web) for more web-specific information.

The `VideoPlayerOptions.mixWithOthers` option can't be implemented in web, at least at the moment. If you use this option in web it will be silently ignored.

## Supported Formats

- On iOS, the backing player is [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer).
  The supported formats vary depending on the version of iOS, [AVURLAsset](https://developer.apple.com/documentation/avfoundation/avurlasset) class
  has [audiovisualTypes](https://developer.apple.com/documentation/avfoundation/avurlasset/1386800-audiovisualtypes?language=objc) that you can query for supported av formats.
- On Android, the backing player is [ExoPlayer](https://google.github.io/ExoPlayer/),
  please refer [here](https://google.github.io/ExoPlayer/supported-formats.html) for list of supported formats.
- On Web, available formats depend on your users' browsers (vendor and version). Check [package:video_player_web](https://pub.dev/packages/video_player_web) for more specific information.

## Example

```dart
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

void main() => runApp(VideoApp());

class VideoApp extends StatefulWidget {
  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: Center(
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : Container(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
```

## Usage

The following section contains usage information that goes beyond what is included in the
documentation in order to give a more elaborate overview of the API.

This is not complete as of now. You can contribute to this section by [opening a pull request](https://github.com/flutter/plugins/pulls).

### Playback speed

You can set the playback speed on your `_controller` (instance of `VideoPlayerController`) by
calling `_controller.setPlaybackSpeed`. `setPlaybackSpeed` takes a `double` speed value indicating
the rate of playback for your video.  
For example, when given a value of `2.0`, your video will play at 2x the regular playback speed
and so on.

To learn about playback speed limitations, see the [`setPlaybackSpeed` method documentation](https://pub.dev/documentation/video_player/latest/video_player/VideoPlayerController/setPlaybackSpeed.html).

Furthermore, see the example app for an example playback speed implementation.

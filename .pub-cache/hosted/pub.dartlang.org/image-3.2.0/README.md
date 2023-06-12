# image

[![Build Status](https://travis-ci.org/brendan-duncan/image.svg?branch=master)](https://travis-ci.org/brendan-duncan/image)

## Overview

A Dart library providing the ability to load, save and manipulate images in a variety of different file formats.

The library is written entirely in Dart and has no reliance on `dart:io`, so it can be used for both 
server and web applications.

### Performance Warning
Because this library is written entirely in Dart and is a not native executed library, its performance
will not be as fast as a native library.

### Supported Image Formats

**Read/Write**

- PNG / Animated APNG
- JPEG
- Targa
- GIF / Animated GIF
- PVR(PVRTC)
- ICO
- BMP

**Read Only**

- WebP / Animated WebP
- TIFF
- Photoshop PSD
- OpenEXR

**Write Only**

- CUR

## [Documentation](https://github.com/brendan-duncan/image/wiki)

## [API](https://pub.dev/documentation/image/latest/image/image-library.html)

## [Examples](https://github.com/brendan-duncan/image/wiki/Examples)

## [Format Decoding Functions](https://github.com/brendan-duncan/image/wiki#format-decoding-functions)

## Example

Load an image asynchronously and resize it as a thumbnail. 
```dart
import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart';

class DecodeParam {
  final File file;
  final SendPort sendPort;
  DecodeParam(this.file, this.sendPort);
}

void decodeIsolate(DecodeParam param) {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  var image = decodeImage(param.file.readAsBytesSync())!;
  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  var thumbnail = copyResize(image, width: 120);
  param.sendPort.send(thumbnail);
}

// Decode and process an image file in a separate thread (isolate) to avoid
// stalling the main UI thread.
void main() async {
  var receivePort = ReceivePort();

  await Isolate.spawn(
      decodeIsolate, DecodeParam(File('test.webp'), receivePort.sendPort));

  // Get the processed image from the isolate.
  var image = await receivePort.first as Image;

  await File('thumbnail.png').writeAsBytes(encodePng(image));
}
```

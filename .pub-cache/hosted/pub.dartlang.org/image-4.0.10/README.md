# Dart Image Library
[![Dart CI](https://github.com/brendan-duncan/image/actions/workflows/build.yaml/badge.svg?branch=4.0)](https://github.com/brendan-duncan/image/actions/workflows/build.yaml)
[![pub package](https://img.shields.io/pub/v/image.svg)](https://pub.dev/packages/image)

## Overview

The Dart Image Library provides the ability to load, save, and
[manipulate](https://github.com/brendan-duncan/image/blob/main/doc/filters.md) images
in a variety of image file [formats](https://github.com/brendan-duncan/image/blob/main/doc/formats.md).

The library can be used with both dart:io and dart:html, for command-line, Flutter, and
web applications.

NOTE: 4.0 is a major revision from the previous version of the library.

## [Documentation](https://github.com/brendan-duncan/image/blob/main/doc/README.md)

### [Supported Image Formats](https://github.com/brendan-duncan/image/blob/main/doc/formats.md)

**Read/Write**

- JPG
- PNG / Animated APNG
- GIF / Animated GIF
- BMP
- TIFF
- TGA
- PVR
- ICO

**Read Only**

- WebP / Animated WebP
- PSD
- EXR

**Write Only**

- CUR

## Examples

Create an image, set pixel values, save it to a PNG.
```dart
import 'dart:io';
import 'package:image/image.dart' as img;
void main() async {
  // Create a 256x256 8-bit (default) rgb (default) image.
  final image = img.Image(width: 256, height: 256);
  // Iterate over its pixels
  for (var pixel in image) {
    // Set the pixels red value to its x position value, creating a gradient.
    pixel..r = pixel.x
    // Set the pixels green value to its y position value.
    ..g = pixel.y;
  }
  // Encode the resulting image to the PNG image format.
  final png = img.encodePng(image);
  // Write the PNG formatted data to a file.
  await File('image.png').writeAsBytes(png);
}
```

To asynchronously load an image file, resize it, and save it as a thumbnail: 
```dart
import 'package:image/image.dart' as img;

void main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'test.png';
  final cmd = img.Command()
    // Decode the image file at the given path
    ..decodeImageFile(path)
    // Resize the image to a width of 64 pixels and a height that maintains the aspect ratio of the original. 
    ..copyResize(width: 64)
    // Write the image to a PNG file (determined by the suffix of the file path). 
    ..writeToFile('thumbnail.png');
  // On platforms that support Isolates, execute the image commands asynchronously on an isolate thread.
  // Otherwise, the commands will be executed synchronously.
  await cmd.executeThread();
}
```

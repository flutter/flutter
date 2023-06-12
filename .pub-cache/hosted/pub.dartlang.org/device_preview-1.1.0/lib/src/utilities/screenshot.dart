import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:device_frame/device_frame.dart';

/// A screenshot from a preview.
class DeviceScreenshot {
  /// Creates a new preview screenshot with its associated [bytes] data, encoded with
  /// the given image [format] for the current [device] preview.
  const DeviceScreenshot({
    required this.device,
    required this.bytes,
    required this.format,
  });

  /// The device from which the screenshot was taken from.
  final DeviceInfo device;

  /// The binary content of the resulting image file.
  final Uint8List bytes;

  /// The format in which image bytes should be returned when using.
  final ui.ImageByteFormat format;
}

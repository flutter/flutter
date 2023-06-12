import 'dart:typed_data';

import '../../color/color.dart';
import '../../util/_internal.dart';
import '../decode_info.dart';
import 'png_frame.dart';

class PngColorType {
  static const grayscale = 0;
  static const rgb = 2;
  static const indexed = 3;
  static const grayscaleAlpha = 4;
  static const rgba = 6;

  static bool isValid(int? value) =>
      value == grayscale ||
      value == rgb ||
      value == indexed ||
      value == grayscaleAlpha ||
      value == rgba;

  const PngColorType(this.value);
  final int value;
}

enum PngFilterType { none, sub, up, average, paeth }

class PngInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  int bits = 0;
  int colorType = -1;
  int compressionMethod = 0;
  int filterMethod = 0;
  int interlaceMethod = 0;
  List<int?>? palette;
  List<int>? transparency;
  double? gamma;
  @override
  Color? backgroundColor;
  String iccpName = '';
  int iccpCompression = 0;
  Uint8List? iccpData;
  Map<String, String> textData = {};

  // APNG extensions
  @override
  int numFrames = 1;
  int repeat = 0;
  final frames = <PngFrame>[];

  final _idat = <int>[];

  bool get isAnimated => frames.isNotEmpty;
}

@internal
class InternalPngInfo extends PngInfo {
  List<int> get idat => _idat;
}

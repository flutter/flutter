import 'dart:typed_data';

import '../../color/color.dart';
import '../../util/input_buffer.dart';
import '../decode_info.dart';

class TgaInfo implements DecodeInfo {
  @override
  int get numFrames => 1;

  @override
  Color? get backgroundColor => null;

  // Header
  int idLength = 0;
  int colorMapType = 0;
  TgaImageType imageType = TgaImageType.none;
  int colorMapOrigin = 0;
  int colorMapLength = 0;
  int colorMapDepth = 0;
  int offsetX = 0;
  int offsetY = 0;
  @override
  int width = 0;
  @override
  int height = 0;
  int pixelDepth = 0;
  int flags = 0;
  Uint8List? colorMap;

  int screenOrigin = 0;

  bool get hasColorMap =>
      imageType == TgaImageType.palette || imageType == TgaImageType.paletteRle;

  // Offset in the input file the image data starts at.
  int imageOffset = 0;

  void read(InputBuffer header) {
    if (header.length < 18) {
      return;
    }
    idLength = header.readByte(); // 0
    colorMapType = header.readByte(); // 1
    final it = header.readByte();
    imageType = it < TgaImageType.values.length
        ? TgaImageType.values[it]
        : TgaImageType.none; // 2
    colorMapOrigin = header.readUint16(); // 3
    colorMapLength = header.readUint16(); // 5
    colorMapDepth = header.readByte(); // 7
    offsetX = header.readUint16(); // 8
    offsetY = header.readUint16(); // 10
    width = header.readUint16(); // 12
    height = header.readUint16(); // 14
    pixelDepth = header.readByte(); // 16
    flags = header.readByte(); // 17

    screenOrigin = (flags & 0x30) >> 4;
  }

  bool isValid() {
    if (pixelDepth != 8 &&
        pixelDepth != 16 &&
        pixelDepth != 24 &&
        pixelDepth != 32) {
      return false;
    }

    if (hasColorMap) {
      if (colorMapLength > 256 || colorMapType != 1) {
        return false;
      }
      if (colorMapDepth != 16 && colorMapDepth != 24 && colorMapDepth != 32) {
        return false;
      }
    } else if (colorMapType == 1) {
      return false;
    }

    return true;
  }
}

enum TgaImageType {
  none,
  palette,
  rgb,
  gray,
  reserved4,
  reserved5,
  reserved6,
  reserved7,
  reserved8,
  paletteRle,
  rgbRle,
  grayRle
}

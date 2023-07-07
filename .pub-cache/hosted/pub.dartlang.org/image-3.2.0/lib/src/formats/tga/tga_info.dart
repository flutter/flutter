import '../decode_info.dart';

class TgaInfo extends DecodeInfo {
  // The number of frames that can be decoded.
  @override
  int get numFrames => 1;

  // Offset in the input file the image data starts at.
  int? imageOffset;

  // Bits per pixel.
  int? bpp;
}

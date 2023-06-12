import '../../color/color.dart';
import '../decode_info.dart';

class Pvr2Info implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  int mipCount = 0;
  int flags = 0;
  int texDataSize = 0;
  int bitsPerPixel = 0;
  int redMask = 0;
  int greenMask = 0;
  int blueMask = 0;
  int alphaMask = 0;
  int magic = 0;
  int numTex = 0;
  @override
  Color? backgroundColor;

  @override
  int get numFrames => 1;
}

class Pvr3Info implements DecodeInfo {
  int flags = 0;
  int format = 0;
  List<int> order = [0, 0, 0, 0];
  int colorSpace = 0;
  int channelType = 0;
  @override
  int height = 0;
  @override
  int width = 0;
  int depth = 0;
  int numSurfaces = 0;
  int numFaces = 0;
  int mipCount = 0;
  int metadataSize = 0;
  @override
  Color? backgroundColor;

  @override
  int get numFrames => 1;
}

class PvrAppleInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  int mipCount = 0;
  int flags = 0;
  int texDataSize = 0;
  int bitsPerPixel = 0;
  int redMask = 0;
  int greenMask = 0;
  int blueMask = 0;
  int magic = 0;
  @override
  Color? backgroundColor;

  @override
  int get numFrames => 1;
}

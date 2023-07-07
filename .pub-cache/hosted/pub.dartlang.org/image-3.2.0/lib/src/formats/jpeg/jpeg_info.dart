import '../decode_info.dart';

class JpegInfo extends DecodeInfo {
  // The number of frames that can be decoded.
  @override
  int get numFrames => 1;
}

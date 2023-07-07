import '../../color/color.dart';
import '../decode_info.dart';

class JpegInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  @override
  int get numFrames => 1;
  @override
  Color? get backgroundColor => null;
}

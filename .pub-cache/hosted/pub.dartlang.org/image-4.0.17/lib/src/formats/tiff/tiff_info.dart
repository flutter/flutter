import '../../color/color.dart';
import '../../formats/decode_info.dart';
import 'tiff_image.dart';

class TiffInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  bool? bigEndian;
  int? signature;

  int? ifdOffset;
  List<TiffImage> images = [];

  @override
  int get numFrames => images.length;

  @override
  Color? get backgroundColor => null;
}

import '../../formats/decode_info.dart';
import 'tiff_image.dart';

class TiffInfo extends DecodeInfo {
  bool? bigEndian;
  int? signature;

  int? ifdOffset;
  List<TiffImage> images = [];

  @override
  int get numFrames => images.length;
}

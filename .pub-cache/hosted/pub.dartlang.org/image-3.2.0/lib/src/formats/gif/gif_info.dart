import '../decode_info.dart';
import 'gif_color_map.dart';
import 'gif_image_desc.dart';

class GifInfo extends DecodeInfo {
  int colorResolution = 0;
  GifColorMap? globalColorMap;
  bool isGif89 = false;
  List<GifImageDesc> frames = [];

  @override
  int get numFrames => frames.length;
}

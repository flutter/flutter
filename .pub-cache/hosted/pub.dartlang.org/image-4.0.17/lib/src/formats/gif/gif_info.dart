import '../../color/color.dart';
import '../decode_info.dart';
import 'gif_color_map.dart';
import 'gif_image_desc.dart';

class GifInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  @override
  Color? backgroundColor;

  int colorResolution = 0;
  GifColorMap? globalColorMap;
  bool isGif89 = false;
  List<GifImageDesc> frames = [];

  @override
  int get numFrames => frames.length;
}

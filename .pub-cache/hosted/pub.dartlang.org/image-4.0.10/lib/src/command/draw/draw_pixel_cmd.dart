import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/blend_mode.dart';
import '../../draw/draw_pixel.dart';
import '../command.dart';

class DrawPixelCmd extends Command {
  int x;
  int y;
  Color color;
  final Color? _filter;
  double? alpha;
  BlendMode blend;
  bool linearBlend;
  Command? mask;
  Channel maskChannel;

  DrawPixelCmd(Command? input, this.x, this.y, this.color,
      {Color? filter,
      this.alpha,
      this.blend = BlendMode.alpha,
      this.linearBlend = false,
      this.mask,
      this.maskChannel = Channel.luminance})
      : _filter = filter,
        super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? drawPixel(img, x, y, color,
            filter: _filter,
            alpha: alpha,
            blend: blend,
            linearBlend: linearBlend,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

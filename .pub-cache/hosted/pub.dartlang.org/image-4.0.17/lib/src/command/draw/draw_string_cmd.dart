import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/draw_string.dart';
import '../../font/bitmap_font.dart';
import '../command.dart';

class DrawStringCmd extends Command {
  BitmapFont font;
  int x;
  int y;
  String string;
  bool rightJustify;
  bool wrap;
  Color? color;
  Command? mask;
  Channel maskChannel;

  DrawStringCmd(Command? input, this.string,
      {required this.font,
      required this.x,
      required this.y,
      this.color,
      this.wrap = false,
      this.rightJustify = false,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? drawString(img, string,
            font: font,
            x: x,
            y: y,
            color: color,
            rightJustify: rightJustify,
            wrap: wrap,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

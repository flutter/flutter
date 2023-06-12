import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/fill_flood.dart';
import '../command.dart';

class FillFloodCmd extends Command {
  int x;
  int y;
  Color color;
  num threshold;
  bool compareAlpha;
  Command? mask;
  Channel maskChannel;

  FillFloodCmd(Command? input,
      {required this.x,
      required this.y,
      required this.color,
      this.threshold = 0.0,
      this.compareAlpha = false,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? fillFlood(img,
            x: x,
            y: y,
            color: color,
            threshold: threshold,
            compareAlpha: compareAlpha,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

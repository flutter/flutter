import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/draw_circle.dart';
import '../command.dart';

class DrawCircleCmd extends Command {
  int x;
  int y;
  int radius;
  Color color;
  bool antialias;
  Command? mask;
  Channel maskChannel;

  DrawCircleCmd(Command? input,
      {required this.x,
      required this.y,
      required this.radius,
      required this.color,
      this.antialias = false,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? drawCircle(img,
            x: x,
            y: y,
            radius: radius,
            color: color,
            antialias: antialias,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

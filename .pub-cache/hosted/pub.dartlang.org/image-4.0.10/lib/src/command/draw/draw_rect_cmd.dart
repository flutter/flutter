import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/draw_rect.dart';
import '../command.dart';

class DrawRectCmd extends Command {
  int x1;
  int y1;
  int x2;
  int y2;
  Color color;
  num radius;
  num thickness;
  Command? mask;
  Channel maskChannel;

  DrawRectCmd(Command? input,
      {required this.x1,
      required this.y1,
      required this.x2,
      required this.y2,
      required this.color,
      this.thickness = 1,
      this.radius = 0,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? drawRect(img,
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            color: color,
            thickness: thickness,
            radius: radius,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

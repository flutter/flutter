import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/draw_polygon.dart';
import '../../util/point.dart';
import '../command.dart';

class DrawPolygonCmd extends Command {
  List<Point> vertices;
  Color color;
  Command? mask;
  Channel maskChannel;

  DrawPolygonCmd(Command? input,
      {required this.vertices,
      required this.color,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? drawPolygon(img,
            vertices: vertices,
            color: color,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

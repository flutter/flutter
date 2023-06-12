import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/fill_polygon.dart';
import '../../util/point.dart';
import '../command.dart';

class FillPolygonCmd extends Command {
  List<Point> vertices;
  Color color;
  Command? mask;
  Channel maskChannel;

  FillPolygonCmd(Command? input,
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
        ? fillPolygon(img,
            vertices: vertices,
            color: color,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

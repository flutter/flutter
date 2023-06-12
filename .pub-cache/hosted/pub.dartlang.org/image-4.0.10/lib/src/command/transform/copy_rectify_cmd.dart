import '../../image/interpolation.dart';
import '../../transform/copy_rectify.dart';
import '../../util/point.dart';
import '../command.dart';

class CopyRectifyCmd extends Command {
  Point topLeft;
  Point topRight;
  Point bottomLeft;
  Point bottomRight;
  Interpolation interpolation;

  CopyRectifyCmd(Command? input,
      {required this.topLeft,
      required this.topRight,
      required this.bottomLeft,
      required this.bottomRight,
      this.interpolation = Interpolation.nearest})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? copyRectify(img,
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight)
        : null;
  }
}

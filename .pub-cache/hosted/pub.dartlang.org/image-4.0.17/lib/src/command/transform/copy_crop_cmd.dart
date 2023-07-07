import '../../transform/copy_crop.dart';
import '../command.dart';

class CopyCropCmd extends Command {
  int x;
  int y;
  int width;
  int height;
  num radius;
  bool antialias;

  CopyCropCmd(Command? input,
      {required this.x,
      required this.y,
      required this.width,
      required this.height,
      this.radius = 0,
      this.antialias = false})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? copyCrop(img,
            x: x,
            y: y,
            width: width,
            height: height,
            radius: radius,
            antialias: antialias)
        : null;
  }
}

import '../../transform/copy_crop_circle.dart';
import '../command.dart';

class CopyCropCircleCmd extends Command {
  int? radius;
  int? centerX;
  int? centerY;
  bool antialias;

  CopyCropCircleCmd(Command? input,
      {this.radius, this.centerX, this.centerY, this.antialias = true})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? copyCropCircle(img,
            radius: radius,
            centerX: centerX,
            centerY: centerY,
            antialias: antialias)
        : null;
  }
}

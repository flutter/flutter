import '../../image/interpolation.dart';
import '../../transform/copy_resize_crop_square.dart';
import '../command.dart';

class CopyResizeCropSquareCmd extends Command {
  int size;
  num radius;
  Interpolation interpolation;
  bool antialias;

  CopyResizeCropSquareCmd(Command? input,
      {required this.size,
      this.radius = 0,
      this.interpolation = Interpolation.nearest,
      this.antialias = true})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? copyResizeCropSquare(img,
            size: size,
            radius: radius,
            interpolation: interpolation,
            antialias: antialias)
        : null;
  }
}

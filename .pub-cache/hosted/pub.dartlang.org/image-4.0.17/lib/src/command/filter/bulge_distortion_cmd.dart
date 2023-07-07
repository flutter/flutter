import '../../color/channel.dart';
import '../../filter/bulge_distortion.dart';
import '../../image/interpolation.dart';
import '../command.dart';

class BulgeDistortionCmd extends Command {
  int? centerX;
  int? centerY;
  num? radius;
  num scale;
  Interpolation interpolation;
  Command? mask;
  Channel maskChannel;

  BulgeDistortionCmd(Command? input,
      {this.centerX,
      this.centerY,
      this.radius,
      this.scale = 0.5,
      this.interpolation = Interpolation.nearest,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? bulgeDistortion(img,
            centerX: centerX,
            centerY: centerY,
            radius: radius,
            scale: scale,
            interpolation: interpolation,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

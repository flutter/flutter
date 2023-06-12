import '../../color/channel.dart';
import '../../filter/stretch_distortion.dart';
import '../../image/interpolation.dart';
import '../command.dart';

class StretchDistortionCmd extends Command {
  int? centerX;
  int? centerY;
  Interpolation interpolation;
  Command? mask;
  Channel maskChannel;

  StretchDistortionCmd(Command? input,
      {this.centerX,
      this.centerY,
      this.interpolation = Interpolation.nearest,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? stretchDistortion(img,
            centerX: centerX,
            centerY: centerY,
            interpolation: interpolation,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

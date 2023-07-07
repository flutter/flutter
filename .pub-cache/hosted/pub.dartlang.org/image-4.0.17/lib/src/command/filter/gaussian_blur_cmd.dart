import '../../color/channel.dart';
import '../../filter/gaussian_blur.dart' as g;
import '../command.dart';

class GaussianBlurCmd extends Command {
  int radius;
  Command? mask;
  Channel maskChannel;

  GaussianBlurCmd(Command? input,
      {required this.radius, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.gaussianBlur(img,
            radius: radius, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

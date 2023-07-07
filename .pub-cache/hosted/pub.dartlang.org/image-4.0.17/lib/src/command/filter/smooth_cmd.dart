import '../../color/channel.dart';
import '../../filter/smooth.dart' as g;
import '../command.dart';

class SmoothCmd extends Command {
  num weight;
  Command? mask;
  Channel maskChannel;

  SmoothCmd(Command? input,
      {required this.weight, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.smooth(img, weight: weight, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

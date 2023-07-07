import '../../color/channel.dart';
import '../../filter/normalize.dart' as g;
import '../command.dart';

class NormalizeCmd extends Command {
  num min;
  num max;
  Command? mask;
  Channel maskChannel;

  NormalizeCmd(Command? input,
      {required this.min,
      required this.max,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.normalize(img,
            min: min, max: max, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

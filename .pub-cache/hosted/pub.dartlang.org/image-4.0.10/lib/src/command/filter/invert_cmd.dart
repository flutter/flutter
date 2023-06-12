import '../../color/channel.dart';
import '../../filter/invert.dart' as g;
import '../command.dart';

class InvertCmd extends Command {
  Command? mask;
  Channel maskChannel;

  InvertCmd(Command? input, {this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.invert(img, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

import '../../color/channel.dart';
import '../../filter/grayscale.dart' as g;
import '../command.dart';

class GrayscaleCmd extends Command {
  num amount;
  Command? mask;
  Channel maskChannel;

  GrayscaleCmd(Command? input,
      {this.amount = 1, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.grayscale(img,
            amount: amount, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

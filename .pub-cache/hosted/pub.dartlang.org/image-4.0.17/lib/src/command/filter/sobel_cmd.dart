import '../../color/channel.dart';
import '../../filter/sobel.dart' as g;
import '../command.dart';

class SobelCmd extends Command {
  num amount;
  Command? mask;
  Channel maskChannel;

  SobelCmd(Command? input,
      {this.amount = 1, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.sobel(img, amount: amount, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

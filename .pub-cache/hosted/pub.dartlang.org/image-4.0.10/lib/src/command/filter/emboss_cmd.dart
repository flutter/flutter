import '../../color/channel.dart';
import '../../filter/emboss.dart' as g;
import '../command.dart';

class EmbossCmd extends Command {
  num amount;
  Command? mask;
  Channel maskChannel;

  EmbossCmd(Command? input,
      {this.amount = 1, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.emboss(img, amount: amount, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

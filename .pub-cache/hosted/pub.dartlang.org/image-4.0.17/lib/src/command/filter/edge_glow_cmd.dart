import '../../color/channel.dart';
import '../../filter/edge_glow.dart' as g;
import '../command.dart';

class EdgeGlowCmd extends Command {
  num amount;
  Command? mask;
  Channel maskChannel;

  EdgeGlowCmd(Command? input,
      {this.amount = 1, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.edgeGlow(img,
            amount: amount, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

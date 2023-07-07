import '../../color/channel.dart';
import '../../filter/gamma.dart' as g;
import '../command.dart';

class GammaCmd extends Command {
  final num _gamma;
  Command? mask;
  Channel maskChannel;

  GammaCmd(Command? input,
      {num gamma = 2.2, this.mask, this.maskChannel = Channel.luminance})
      : _gamma = gamma,
        super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.gamma(img, gamma: _gamma, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

import 'dart:math';

import '../../color/channel.dart';
import '../../filter/noise.dart' as g;
import '../command.dart';

class NoiseCmd extends Command {
  num sigma;
  g.NoiseType type;
  Random? random;
  Command? mask;
  Channel maskChannel;

  NoiseCmd(Command? input, this.sigma,
      {this.type = g.NoiseType.gaussian,
      this.random,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.noise(img, sigma,
            type: type, random: random, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

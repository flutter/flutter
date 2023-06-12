import '../../color/channel.dart';
import '../../filter/luminance_threshold.dart';
import '../command.dart';

class LuminanceThresholdCmd extends Command {
  final num threshold;
  final bool outputColor;
  final num amount;
  Command? mask;
  Channel maskChannel;

  LuminanceThresholdCmd(Command? input,
      {this.threshold = 0.5,
      this.outputColor = false,
      this.amount = 1,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? luminanceThreshold(img,
            threshold: threshold,
            outputColor: outputColor,
            amount: amount,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

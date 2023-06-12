import '../../color/channel.dart';
import '../../color/color.dart';
import '../../filter/vignette.dart' as g;
import '../command.dart';

class VignetteCmd extends Command {
  num start;
  num end;
  num amount;
  Color? color;
  Command? mask;
  Channel maskChannel;

  VignetteCmd(Command? input,
      {this.start = 0.3,
      this.end = 0.75,
      this.color,
      this.amount = 0.8,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.vignette(img,
            start: start,
            end: end,
            color: color,
            amount: amount,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

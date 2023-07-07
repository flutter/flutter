import '../../color/channel.dart';
import '../../color/color.dart';
import '../../filter/monochrome.dart' as g;
import '../command.dart';

class MonochromeCmd extends Command {
  final num amount;
  final Color? color;
  Command? mask;
  Channel maskChannel;

  MonochromeCmd(Command? input,
      {this.color,
      this.amount = 1,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.monochrome(img,
            color: color,
            amount: amount,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

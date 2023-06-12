import '../../color/channel.dart';
import '../../filter/dot_screen.dart' as g;
import '../command.dart';

class DotScreenCmd extends Command {
  final num angle;
  final num size;
  final int? centerX;
  final int? centerY;
  final num amount;
  Command? mask;
  Channel maskChannel;

  DotScreenCmd(Command? input,
      {this.angle = 180,
      this.size = 5.75,
      this.centerX,
      this.centerY,
      this.amount = 1,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.dotScreen(img,
            angle: angle,
            size: size,
            centerX: centerX,
            centerY: centerY,
            amount: amount,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

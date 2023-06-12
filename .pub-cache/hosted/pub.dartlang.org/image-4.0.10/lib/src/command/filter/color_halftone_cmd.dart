import '../../color/channel.dart';
import '../../filter/color_halftone.dart';
import '../command.dart';

class ColorHalftoneCmd extends Command {
  num amount;
  int? centerX;
  int? centerY;
  num angle = 180;
  num size = 5;
  Command? mask;
  Channel maskChannel;

  ColorHalftoneCmd(Command? input,
      {this.amount = 1,
      this.centerX,
      this.centerY,
      this.angle = 180,
      this.size = 5,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? colorHalftone(img,
            amount: amount,
            centerX: centerX,
            centerY: centerY,
            angle: angle,
            size: size,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

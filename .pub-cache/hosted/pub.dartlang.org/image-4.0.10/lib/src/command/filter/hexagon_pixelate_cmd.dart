import '../../color/channel.dart';
import '../../filter/hexagon_pixelate.dart' as g;
import '../command.dart';

class HexagonPixelateCmd extends Command {
  int? centerX;
  int? centerY;
  int size;
  num amount;
  Command? mask;
  Channel maskChannel;

  HexagonPixelateCmd(Command? input,
      {this.centerX,
      this.centerY,
      this.size = 5,
      this.amount = 1,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.hexagonPixelate(img,
            centerX: centerX,
            centerY: centerY,
            size: size,
            amount: amount,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

import '../../color/channel.dart';
import '../../filter/color_offset.dart' as g;
import '../command.dart';

class ColorOffsetCmd extends Command {
  num red;
  num green;
  num blue;
  num alpha;
  Command? mask;
  Channel maskChannel;

  ColorOffsetCmd(Command? input,
      {this.red = 0,
      this.green = 0,
      this.blue = 0,
      this.alpha = 0,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.colorOffset(img,
            red: red,
            green: green,
            blue: blue,
            alpha: alpha,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

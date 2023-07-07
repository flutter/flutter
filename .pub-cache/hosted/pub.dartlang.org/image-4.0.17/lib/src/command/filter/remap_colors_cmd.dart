import '../../color/channel.dart';
import '../../filter/remap_colors.dart' as g;
import '../command.dart';

class RemapColorsCmd extends Command {
  Channel red;
  Channel green;
  Channel blue;
  Channel alpha;

  RemapColorsCmd(Command? input,
      {this.red = Channel.red,
      this.green = Channel.green,
      this.blue = Channel.blue,
      this.alpha = Channel.alpha})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    outputImage = img != null
        ? g.remapColors(img, red: red, green: green, blue: blue, alpha: alpha)
        : null;
  }
}

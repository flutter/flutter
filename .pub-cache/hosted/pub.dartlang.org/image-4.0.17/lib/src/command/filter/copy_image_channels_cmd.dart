import '../../color/channel.dart';
import '../../filter/copy_image_channels.dart' as g;
import '../command.dart';

class CopyImageChannelsCmd extends Command {
  final Command? from;
  final bool scaled;
  final Channel? red;
  final Channel? green;
  final Channel? blue;
  final Channel? alpha;
  final Command? mask;
  final Channel maskChannel;

  CopyImageChannelsCmd(Command? input,
      {this.from,
      this.scaled = false,
      this.red,
      this.green,
      this.blue,
      this.alpha,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final fromImg = await from?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null && fromImg != null
        ? g.copyImageChannels(img,
            from: fromImg,
            scaled: scaled,
            red: red,
            green: green,
            blue: blue,
            alpha: alpha,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

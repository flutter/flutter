import '../../color/channel.dart';
import '../../filter/pixelate.dart' as g;
import '../command.dart';

class PixelateCmd extends Command {
  int size;
  g.PixelateMode mode;
  Command? mask;
  Channel maskChannel;

  PixelateCmd(Command? input,
      {required this.size,
      this.mode = g.PixelateMode.upperLeft,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.pixelate(img,
            size: size, mode: mode, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

import '../../color/channel.dart';
import '../../filter/contrast.dart' as g;
import '../command.dart';

class ContrastCmd extends Command {
  final num _contrast;
  Command? mask;
  Channel maskChannel;

  ContrastCmd(Command? input,
      {num contrast = 100.0, this.mask, this.maskChannel = Channel.luminance})
      : _contrast = contrast,
        super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.contrast(img,
            contrast: _contrast, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

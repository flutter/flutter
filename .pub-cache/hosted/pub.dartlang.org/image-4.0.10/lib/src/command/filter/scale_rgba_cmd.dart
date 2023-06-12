import '../../color/channel.dart';
import '../../color/color.dart';
import '../../filter/scale_rgba.dart' as g;
import '../command.dart';

class ScaleRgbaCmd extends Command {
  Color scale;
  Command? mask;
  Channel maskChannel;

  ScaleRgbaCmd(Command? input,
      {required this.scale, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.scaleRgba(img,
            scale: scale, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

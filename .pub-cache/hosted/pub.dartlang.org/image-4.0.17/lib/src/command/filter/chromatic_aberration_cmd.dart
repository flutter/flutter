import '../../color/channel.dart';
import '../../filter/chromatic_aberration.dart';
import '../command.dart';

class ChromaticAberrationCmd extends Command {
  int shift;
  Command? mask;
  Channel maskChannel;

  ChromaticAberrationCmd(Command? input,
      {this.shift = 5, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? chromaticAberration(img,
            shift: shift, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

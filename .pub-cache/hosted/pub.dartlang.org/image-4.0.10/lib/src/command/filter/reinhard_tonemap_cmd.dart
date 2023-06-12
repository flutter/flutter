import '../../color/channel.dart';
import '../../filter/reinhard_tone_map.dart' as g;
import '../command.dart';

class ReinhardTonemapCmd extends Command {
  Command? mask;
  Channel maskChannel;

  ReinhardTonemapCmd(Command? input,
      {this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.reinhardTonemap(img) : null;
  }
}

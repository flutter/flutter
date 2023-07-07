import '../../color/channel.dart';
import '../../filter/bleach_bypass.dart';
import '../command.dart';

class BleachBypassCmd extends Command {
  num amount;
  Command? mask;
  Channel maskChannel;

  BleachBypassCmd(Command? input,
      {this.amount = 1, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? bleachBypass(img,
            amount: amount, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

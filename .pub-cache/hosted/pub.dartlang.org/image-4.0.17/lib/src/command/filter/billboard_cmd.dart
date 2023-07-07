import '../../color/channel.dart';
import '../../filter/billboard.dart';
import '../command.dart';

class BillboardCmd extends Command {
  final num grid;
  final num amount;
  Command? mask;
  Channel maskChannel;

  BillboardCmd(Command? input,
      {this.grid = 10,
      this.amount = 1,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? billboard(img,
            grid: grid, amount: amount, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

import '../../color/channel.dart';
import '../../filter/convolution.dart' as g;
import '../command.dart';

class ConvolutionCmd extends Command {
  final List<num> _filter;
  final num div;
  final num offset;
  final num amount;
  final Command? mask;
  final Channel maskChannel;

  ConvolutionCmd(Command? input,
      {required List<num> filter,
      this.div = 1.0,
      this.offset = 0,
      this.amount = 1,
      this.mask,
      this.maskChannel = Channel.luminance})
      : _filter = filter,
        super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.convolution(img,
            filter: _filter,
            div: div,
            offset: offset,
            amount: amount,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

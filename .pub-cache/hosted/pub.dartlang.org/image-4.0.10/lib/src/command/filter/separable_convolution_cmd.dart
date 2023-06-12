import '../../color/channel.dart';
import '../../filter/separable_convolution.dart' as g;
import '../../filter/separable_kernel.dart' as g;
import '../command.dart';

class SeparableConvolutionCmd extends Command {
  g.SeparableKernel kernel;
  Command? mask;
  Channel maskChannel;

  SeparableConvolutionCmd(Command? input,
      {required this.kernel, this.mask, this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.separableConvolution(img,
            kernel: kernel, mask: maskImg, maskChannel: maskChannel)
        : null;
  }
}

import '../../color/channel.dart';
import '../../draw/blend_mode.dart';
import '../../draw/composite_image.dart';
import '../command.dart';

class CompositeImageCmd extends Command {
  Command? src;
  int? dstX;
  int? dstY;
  int? dstW;
  int? dstH;
  int? srcX;
  int? srcY;
  int? srcW;
  int? srcH;
  BlendMode blend;
  bool linearBlend;
  bool center;
  Command? mask;
  Channel maskChannel;

  CompositeImageCmd(Command? dst, this.src,
      {this.dstX,
      this.dstY,
      this.dstW,
      this.dstH,
      this.srcX,
      this.srcY,
      this.srcW,
      this.srcH,
      this.blend = BlendMode.alpha,
      this.linearBlend = false,
      this.center = false,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(dst);

  @override
  Future<void> executeCommand() async {
    final dst = await input?.getImage();
    final srcImg = await src?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = dst != null && srcImg != null
        ? compositeImage(dst, srcImg,
            dstX: dstX,
            dstY: dstY,
            dstW: dstW,
            dstH: dstH,
            srcX: srcX,
            srcY: srcY,
            srcW: srcW,
            srcH: srcH,
            blend: blend,
            linearBlend: linearBlend,
            center: center,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

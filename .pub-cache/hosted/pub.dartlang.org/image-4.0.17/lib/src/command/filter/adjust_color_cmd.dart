import '../../color/channel.dart';
import '../../color/color.dart';
import '../../filter/adjust_color.dart' as g;
import '../command.dart';

class AdjustColorCmd extends Command {
  final Color? blacks;
  final Color? whites;
  final Color? mids;
  final num? _contrast;
  final num? saturation;
  final num? brightness;
  final num? _gamma;
  final num? exposure;
  final num? hue;
  final num amount;
  final Command? mask;
  final Channel maskChannel;

  AdjustColorCmd(Command? input,
      {this.blacks,
      this.whites,
      this.mids,
      num? contrast,
      this.saturation,
      this.brightness,
      num? gamma,
      this.exposure,
      this.hue,
      this.amount = 1,
      this.mask,
      this.maskChannel = Channel.luminance})
      : _contrast = contrast,
        _gamma = gamma,
        super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? g.adjustColor(img,
            blacks: blacks,
            whites: whites,
            mids: mids,
            contrast: _contrast,
            saturation: saturation,
            brightness: brightness,
            gamma: _gamma,
            exposure: exposure,
            hue: hue,
            amount: amount,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}

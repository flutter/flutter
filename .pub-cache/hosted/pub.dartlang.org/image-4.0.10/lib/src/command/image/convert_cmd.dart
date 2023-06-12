import '../../color/format.dart';
import '../command.dart';

class ConvertCmd extends Command {
  int? numChannels;
  Format? format;
  num? alpha;
  bool withPalette;
  ConvertCmd(Command? input,
      {this.numChannels, this.format, this.alpha, this.withPalette = false})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img?.convert(
        format: format,
        numChannels: numChannels,
        alpha: alpha,
        withPalette: withPalette);
  }
}

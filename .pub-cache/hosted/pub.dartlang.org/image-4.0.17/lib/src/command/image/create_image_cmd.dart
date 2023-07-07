import '../../color/format.dart';
import '../../exif/exif_data.dart';
import '../../image/icc_profile.dart';
import '../../image/image.dart';
import '../../image/palette.dart';
import '../command.dart';

class CreateImageCmd extends Command {
  int width;
  int height;
  Format format;
  int numChannels;
  bool withPalette;
  Format paletteFormat;
  Palette? palette;
  ExifData? exif;
  IccProfile? iccp;
  Map<String, String>? textData;

  CreateImageCmd(Command? input,
      {required this.width,
      required this.height,
      this.format = Format.uint8,
      this.numChannels = 3,
      this.withPalette = false,
      this.paletteFormat = Format.uint8,
      this.palette,
      this.exif,
      this.iccp,
      this.textData})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = Image(
        width: width,
        height: height,
        format: format,
        numChannels: numChannels,
        withPalette: withPalette,
        paletteFormat: paletteFormat,
        palette: palette,
        exif: exif,
        iccp: iccp,
        textData: textData);
  }
}

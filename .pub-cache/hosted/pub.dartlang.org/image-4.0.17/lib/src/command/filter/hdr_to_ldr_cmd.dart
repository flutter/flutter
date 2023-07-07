import '../../filter/hdr_to_ldr.dart' as g;
import '../command.dart';

class HdrToLdrCmd extends Command {
  num? exposure;

  HdrToLdrCmd(Command? input, {this.exposure}) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.hdrToLdr(img, exposure: exposure) : null;
  }
}

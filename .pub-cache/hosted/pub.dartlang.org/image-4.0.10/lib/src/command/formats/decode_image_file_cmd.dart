import '../../formats/formats.dart';
import '../command.dart';

class DecodeImageFileCmd extends Command {
  String path;

  DecodeImageFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeImageFile(path);
  }
}

import '../../formats/formats.dart';
import '../command.dart';

// Encode an Image to the Cur format.
class EncodeCurCmd extends Command {
  EncodeCurCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeCur(outputImage!);
    }
  }
}

// Encode an Image to the Cur format and write it to a file at the given
// [path].
class EncodeCurFileCmd extends Command {
  String path;

  EncodeCurFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodeCurFile(path, outputImage!);
    }
  }
}

import '../../formats/formats.dart';
import '../../util/file_access.dart';
import '../command.dart';

class WriteToFileCmd extends Command {
  String path;

  WriteToFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    outputBytes = input?.outputBytes;

    if (outputBytes == null && outputImage != null) {
      await encodeImageFile(path, outputImage!);
    } else if (outputBytes != null) {
      await writeFile(path, outputBytes!);
    }
  }
}

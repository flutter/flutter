import '../../image/image.dart';
import '../command.dart';

class ImageCmd extends Command {
  ImageCmd(Command? input, Image image) : super(input) {
    outputImage = image;
  }

  @override
  Future<void> executeCommand() async {
    await input?.execute();
  }
}

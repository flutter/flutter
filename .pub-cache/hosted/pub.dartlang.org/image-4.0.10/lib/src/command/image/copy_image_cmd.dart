import '../command.dart';

class CopyImageCmd extends Command {
  CopyImageCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img?.clone();
  }
}

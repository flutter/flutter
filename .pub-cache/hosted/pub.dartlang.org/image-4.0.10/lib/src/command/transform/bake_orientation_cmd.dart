import '../../transform/bake_orientation.dart';
import '../command.dart';

class BakeOrientationCmd extends Command {
  BakeOrientationCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? bakeOrientation(img) : null;
  }
}

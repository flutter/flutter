import '../../transform/copy_flip.dart';
import '../../transform/flip.dart';
import '../command.dart';

class CopyFlipCmd extends Command {
  FlipDirection direction;

  CopyFlipCmd(Command? input, {required this.direction}) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? copyFlip(img, direction: direction) : null;
  }
}

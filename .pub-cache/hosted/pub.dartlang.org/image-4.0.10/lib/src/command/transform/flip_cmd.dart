import '../../transform/flip.dart';
import '../command.dart';

class FlipCmd extends Command {
  FlipDirection direction;

  FlipCmd(Command? input, {required this.direction}) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? flip(img, direction: direction) : null;
  }
}

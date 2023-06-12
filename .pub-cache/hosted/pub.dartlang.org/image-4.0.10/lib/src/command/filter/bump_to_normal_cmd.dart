import '../../filter/bump_to_normal.dart' as g;
import '../command.dart';

class BumpToNormalCmd extends Command {
  num strength;

  BumpToNormalCmd(Command? input, {this.strength = 2.0}) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.bumpToNormal(img, strength: strength) : null;
  }
}

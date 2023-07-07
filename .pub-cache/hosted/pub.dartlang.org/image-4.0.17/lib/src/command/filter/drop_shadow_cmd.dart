import '../../color/color.dart';
import '../../filter/drop_shadow.dart' as g;
import '../command.dart';

class DropShadowCmd extends Command {
  int hShadow;
  int vShadow;
  int blur;
  Color? shadowColor;

  DropShadowCmd(Command? input, this.hShadow, this.vShadow, this.blur,
      {this.shadowColor})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? g.dropShadow(img, hShadow, vShadow, blur, shadowColor: shadowColor)
        : null;
  }
}

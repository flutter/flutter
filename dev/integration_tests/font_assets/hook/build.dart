import 'package:font_asset/build_helpers.dart';
import 'package:hooks/hooks.dart';

void main(List<String> arguments) {
  build(arguments, (input, output) async {
    addFontAsset(
      input,
      output,
      filePath: 'fonts/BBHBartle-Regular.ttf',
      fontFamily: 'BBHBartle',
    );
    addMaterialFont(input, output);
  });
}

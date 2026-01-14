import 'package:font_asset/build_helpers.dart';
import 'package:hooks/hooks.dart';

void main(List<String> arguments) {
  build(arguments, (input, output) async {
    addFont(
      input,
      output,
      filePath: 'fonts/BBHBartle-Regular.ttf',
      family: 'BBHBartle',
    );
    addMaterialFont(input, output);
  });
}

import 'package:get_cli/functions/path/replace_to_relative.dart';
import 'package:test/test.dart';

void main() {
  test('replace import to relative', () {
    var import =
        "import 'package:ponto_facil/app/modules/home/views/home.view.dart';";
    var otherFile = 'lib/app/data/file.dart';
    expect(replaceToRelativeImport(import, otherFile),
        equals("import '../modules/home/views/home.view.dart';"));
  });
}

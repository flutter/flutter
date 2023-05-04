import 'package:test/test.dart';

import 'shorebird_tests.dart';

void main() {
  group('shorebird helpers', () {
    testWithShorebirdProject('can build a base project',
        (projectDirectory) async {
      expect(projectDirectory.existsSync(), isTrue);

      expect(projectDirectory.pubspecFile.existsSync(), isTrue);
      expect(projectDirectory.shorebirdFile.existsSync(), isTrue);
    });
  });
}

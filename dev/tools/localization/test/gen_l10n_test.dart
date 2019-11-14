import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../gen_l10n.dart';

final String defaultArbPathString = path.join('lib', 'l10n');
const String defaultTemplateArbFileName = 'app_en.arb';
const String defaultOutputFileString = 'output-localization-file';
const String defaultClassNameString = 'AppLocalizations';

void _standardFlutterDirectoryL10nSetup(FileSystem fs) {
  fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
    ..createSync(recursive: true)
    ..childFile(defaultTemplateArbFileName)
    .writeAsStringSync('Hello world');
}

void main() {
  MemoryFileSystem fs;
  setUp(() {
    fs = MemoryFileSystem();
  });

  test('LocalizationsGenerator setters happy path', () {
    _standardFlutterDirectoryL10nSetup(fs);

    try {
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      generator.setL10nDirectory(defaultArbPathString);
      generator.setTemplateArbFile(defaultTemplateArbFileName);
      generator.setOutputFile(defaultOutputFileString);
      generator.setClassName(defaultClassNameString);
    } on FileSystemException catch (e) {
      fail('Setters should not fail $e');
    }
  });

  test('LocalizationsGenerator.setL10nDirectory fails if the directory does not exist', () {
    try {
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      generator.setL10nDirectory('lib');
    } on FileSystemException catch (e) {
      expect(e.message, contains('Make sure that the correct path was provided'));
      return;
    }

    fail(
      'Attempting to set LocalizationsGenerator.setL10nDirectory should fail if the '
      'directory does not exist.'
    );
  });
}
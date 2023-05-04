import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:shorebird_tools/src/command_runner.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('package', () {
    late Logger logger;
    late ShorebirdToolsCommandRunner commandRunner;
    late Directory testDir;

    setUp(() {
      logger = _MockLogger();
      commandRunner = ShorebirdToolsCommandRunner(logger: logger);
      testDir = Directory.systemTemp.createTempSync('shorebird_tools_test');
    });

    test('packages the received patch', () async {
      File(p.join(testDir.path, 'patch.txt')).writeAsStringSync('banana');

      final exitCode = await commandRunner.run(
        [
          'package',
          '-p',
          p.join(testDir.path, 'patch.txt'),
          '-o',
          p.join(testDir.path, 'patch.zip'),
        ],
      );

      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info(
          'Packaged patch at ${p.join(testDir.path, 'patch.txt')} '
          'to ${p.join(testDir.path, 'patch.zip')}',
        ),
      ).called(1);

      final patchFile = File(p.join(testDir.path, 'patch.zip'));
      expect(patchFile.existsSync(), isTrue);

      final extractedFolder = Directory(p.join(testDir.path, 'extracted'))
        ..createSync();
      await extractFileToDisk(patchFile.path, extractedFolder.path);

      // Making sure it was correctly archived and can be extracted
      final extractedFile = File(p.join(extractedFolder.path, 'patch.txt'));
      expect(extractedFile.existsSync(), isTrue);
      expect(extractedFile.readAsStringSync(), 'banana');
    });

    group('when the patch file does not exists', () {
      test('error and logs', () async {
        final exitCode = await commandRunner.run(
          [
            'package',
            '-p',
            p.join(testDir.path, 'patch.txt'),
            '-o',
            p.join(testDir.path, 'patch.zip'),
          ],
        );

        expect(exitCode, ExitCode.software.code);

        verify(
          () => logger.err(
            'Patch file not found at ${p.join(testDir.path, 'patch.txt')}',
          ),
        ).called(1);
      });
    });

    group('when missing option for -p', () {
      test('shows errors and print the correct usage', () async {
        final exitCode = await commandRunner.run(['package', '-p']);

        expect(exitCode, ExitCode.usage.code);

        verify(() => logger.err('Missing argument for "patch".')).called(1);
        verify(
          () => logger.info('''
Usage: shorebird_tools package [arguments]
-h, --help                  Print this usage information.
-p, --patch (mandatory)     The path to the patch artifact which will be packaged
-o, --output (mandatory)    Where to write the packaged patch archive

Run "shorebird_tools help" to see global options.'''),
        ).called(1);
      });
    });

    group('when missing option for -o', () {
      test('shows errors and print the correct usage', () async {
        final exitCode = await commandRunner.run(
          [
            'package',
            '-p',
            'bla',
            '-o',
          ],
        );

        expect(exitCode, ExitCode.usage.code);

        verify(() => logger.err('Missing argument for "output".')).called(1);
        verify(
          () => logger.info('''
Usage: shorebird_tools package [arguments]
-h, --help                  Print this usage information.
-p, --patch (mandatory)     The path to the patch artifact which will be packaged
-o, --output (mandatory)    Where to write the packaged patch archive

Run "shorebird_tools help" to see global options.'''),
        ).called(1);
      });
    });
  });
}

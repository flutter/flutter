@TestOn('vm')
library process_run.doc_test;

import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

void main() {
  group('doc', () {
    test('run', () async {
      try {
        await run('firebase --version');
        await run('''
        dart --version
        git status
        ''');
      } catch (_) {}
    });

    test('ShellLinesController', () async {
      var controller = ShellLinesController();
      var shell = Shell(stdout: controller.sink, verbose: false);
      controller.stream.listen((event) {
        // Handle output

        // ...
        // If needed kill the shell
        shell.kill();
      });
      try {
        await shell.run('dart echo.dart some_text');
      } on ShellException catch (_) {
        // We might get a shell exception
      }
    });
  });
}

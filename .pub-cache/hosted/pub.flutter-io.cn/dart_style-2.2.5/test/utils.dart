// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_style.test.utils;

import 'dart:io';
import 'dart:mirrors';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

const unformattedSource = 'void  main()  =>  print("hello") ;';
const formattedSource = 'void main() => print("hello");\n';

/// The same as formatted source but without a trailing newline because
/// [TestProcess] filters those when it strips command line output into lines.
const formattedOutput = 'void main() => print("hello");';

final _indentPattern = RegExp(r'\(indent (\d+)\)');
final _fixPattern = RegExp(r'\(fix ([a-x-]+)\)');
final _unicodePattern = RegExp(r'×([0-9a-fA-F]{2,4})');

/// If tool/command_shell.dart has been compiled to a snapshot, this is the path
/// to it.
String? _commandExecutablePath;

/// If bin/format.dart has been compiled to a snapshot, this is the path to it.
String? _formatterExecutablePath;

/// Compiles format.dart to a native executable for tests to use.
///
/// Calls [setupAll()] and [tearDownAll()] to coordinate this when the
/// subsequent tests and to clean up the executable.
void compileFormatterExecutable() {
  setUpAll(() async {
    _formatterExecutablePath = await _compileSnapshot('bin/format.dart');
  });

  tearDownAll(() async {
    await _deleteSnapshot(_formatterExecutablePath!);
    _formatterExecutablePath = null;
  });
}

/// Compiles command_shell.dart to a native executable for tests to use.
///
/// Calls [setupAll()] and [tearDownAll()] to coordinate this when the
/// subsequent tests and to clean up the executable.
void compileCommandExecutable() {
  setUpAll(() async {
    _commandExecutablePath = await _compileSnapshot('tool/command_shell.dart');
  });

  tearDownAll(() async {
    await _deleteSnapshot(_commandExecutablePath!);
    _commandExecutablePath = null;
  });
}

/// Compile the Dart [script] to an app-JIT snapshot.
///
/// We do this instead of spawning the script from source each time because it's
/// much faster when the same script needs to be run several times.
Future<String> _compileSnapshot(String script) async {
  var scriptName = p.basename(script);
  var tempDir =
      await Directory.systemTemp.createTemp(p.withoutExtension(scriptName));
  var snapshot = p.join(tempDir.path, '$scriptName.snapshot');

  // Locate the "test" directory. Use mirrors so that this works with the test
  // package, which loads this suite into an isolate.
  var testDir = p.dirname(currentMirrorSystem()
      .findLibrary(#dart_style.test.utils)
      .uri
      .toFilePath());
  var scriptPath = p.normalize(p.join(p.dirname(testDir), script));

  var compileResult = await Process.run(Platform.resolvedExecutable, [
    '--snapshot-kind=app-jit',
    '--snapshot=$snapshot',
    scriptPath,
    '--help'
  ]);

  if (compileResult.exitCode != 0) {
    fail('Could not compile $scriptName to a snapshot (exit code '
        '${compileResult.exitCode}):\n${compileResult.stdout}\n\n'
        '${compileResult.stderr}');
  }

  return snapshot;
}

/// Attempts to delete to temporary directory created for [snapshot] by
/// [_compileSnapshot()].
Future<void> _deleteSnapshot(String snapshot) async {
  try {
    await Directory(p.dirname(snapshot)).delete(recursive: true);
  } on IOException {
    // Do nothing if we failed to delete it. The OS will eventually clean it
    // up.
  }
}

/// Runs the command line formatter, passing it [args].
Future<TestProcess> runFormatter([List<String>? args]) {
  if (_formatterExecutablePath == null) {
    fail('Must call createFormatterExecutable() before running commands.');
  }

  return TestProcess.start(
      Platform.resolvedExecutable, [_formatterExecutablePath!, ...?args],
      workingDirectory: d.sandbox);
}

/// Runs the command line formatter, passing it the test directory followed by
/// [args].
Future<TestProcess> runFormatterOnDir([List<String>? args]) {
  return runFormatter(['.', ...?args]);
}

/// Runs the test shell for the [Command]-based formatter, passing it [args].
Future<TestProcess> runCommand([List<String>? args]) {
  if (_commandExecutablePath == null) {
    fail('Must call createCommandExecutable() before running commands.');
  }

  return TestProcess.start(Platform.resolvedExecutable,
      [_commandExecutablePath!, 'format', ...?args],
      workingDirectory: d.sandbox);
}

/// Runs the test shell for the [Command]-based formatter, passing it the test
/// directory followed by [args].
Future<TestProcess> runCommandOnDir([List<String>? args]) {
  return runCommand(['.', ...?args]);
}

/// Run tests defined in "*.unit" and "*.stmt" files inside directory [name].
void testDirectory(String name, [Iterable<StyleFix>? fixes]) {
  // Locate the "test" directory. Use mirrors so that this works with the test
  // package, which loads this suite into an isolate.
  // TODO(rnystrom): Investigate using Isolate.resolvePackageUri instead.
  var testDir = p.dirname(currentMirrorSystem()
      .findLibrary(#dart_style.test.utils)
      .uri
      .toFilePath());

  var entries = Directory(p.join(testDir, name))
      .listSync(recursive: true, followLinks: false);
  entries.sort((a, b) => a.path.compareTo(b.path));

  for (var entry in entries) {
    if (!entry.path.endsWith('.stmt') && !entry.path.endsWith('.unit')) {
      continue;
    }

    _testFile(name, entry.path, fixes);
  }
}

void testFile(String path, [Iterable<StyleFix>? fixes]) {
  // Locate the "test" directory. Use mirrors so that this works with the test
  // package, which loads this suite into an isolate.
  var testDir = p.dirname(currentMirrorSystem()
      .findLibrary(#dart_style.test.utils)
      .uri
      .toFilePath());

  _testFile(p.dirname(path), p.join(testDir, path), fixes);
}

void _testFile(String name, String path, Iterable<StyleFix>? baseFixes) {
  var fixes = [...?baseFixes];

  group('$name ${p.basename(path)}', () {
    // Explicitly create a File, in case the entry is a Link.
    var lines = File(path).readAsLinesSync();

    // The first line may have a "|" to indicate the page width.
    int? pageWidth;
    if (lines[0].endsWith('|')) {
      pageWidth = lines[0].indexOf('|');
      lines = lines.skip(1).toList();
    }

    var i = 0;
    while (i < lines.length) {
      var description = lines[i++].replaceAll('>>>', '');

      // Let the test specify a leading indentation. This is handy for
      // regression tests which often come from a chunk of nested code.
      var leadingIndent = 0;
      description = description.replaceAllMapped(_indentPattern, (match) {
        leadingIndent = int.parse(match[1]!);
        return '';
      });

      // Let the test specify fixes to apply.
      description = description.replaceAllMapped(_fixPattern, (match) {
        fixes.add(StyleFix.all.firstWhere((fix) => fix.name == match[1]));
        return '';
      });

      description = description.trim();

      if (description == '') {
        description = 'line ${i + 1}';
      } else {
        description = 'line ${i + 1}: $description';
      }

      var input = '';
      while (!lines[i].startsWith('<<<')) {
        input += '${lines[i++]}\n';
      }

      var expectedOutput = '';
      while (++i < lines.length && !lines[i].startsWith('>>>')) {
        expectedOutput += '${lines[i]}\n';
      }

      // Unescape special Unicode escape markers.
      input = _unescapeUnicode(input);
      expectedOutput = _unescapeUnicode(expectedOutput);

      // TODO(rnystrom): Stop skipping these tests when possible.
      if (description.contains('(skip:')) {
        print('skipping $description');
        continue;
      }

      test(description, () {
        var isCompilationUnit = p.extension(path) == '.unit';

        var inputCode =
            _extractSelection(input, isCompilationUnit: isCompilationUnit);

        var expected = _extractSelection(expectedOutput,
            isCompilationUnit: isCompilationUnit);
        var expectedText = expected.text;

        var formatter = DartFormatter(
            pageWidth: pageWidth, indent: leadingIndent, fixes: fixes);

        var actual = formatter.formatSource(inputCode);

        // The test files always put a newline at the end of the expectation.
        // Statements from the formatter (correctly) don't have that, so add
        // one to line up with the expected result.
        var actualText = actual.text;
        if (!isCompilationUnit) actualText += '\n';

        // Fail with an explicit message because it's easier to read than
        // the matcher output.
        if (actualText != expectedText) {
          fail('Formatting did not match expectation. Expected:\n'
              '$expectedText\nActual:\n$actualText');
        }

        expect(actual.selectionStart, equals(expected.selectionStart));
        expect(actual.selectionLength, equals(expected.selectionLength));
      });
    }
  });
}

/// Given a source string that contains ‹ and › to indicate a selection, returns
/// a [SourceCode] with the text (with the selection markers removed) and the
/// correct selection range.
SourceCode _extractSelection(String source, {bool isCompilationUnit = false}) {
  var start = source.indexOf('‹');
  source = source.replaceAll('‹', '');

  var end = source.indexOf('›');
  source = source.replaceAll('›', '');

  return SourceCode(source,
      isCompilationUnit: isCompilationUnit,
      selectionStart: start == -1 ? null : start,
      selectionLength: end == -1 ? null : end - start);
}

/// Turn the special Unicode escape marker syntax used in the tests into real
/// Unicode characters.
///
/// This does not use Dart's own string escape sequences so that we don't
/// accidentally modify the Dart code being formatted.
String _unescapeUnicode(String input) {
  return input.replaceAllMapped(_unicodePattern, (match) {
    var codePoint = int.parse(match[1]!, radix: 16);
    return String.fromCharCode(codePoint);
  });
}

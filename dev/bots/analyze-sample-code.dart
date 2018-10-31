// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This script analyzes all the sample code in API docs in the Flutter source.
//
// It uses the following conventions:
//
// Code is denoted by markdown ```dart / ``` markers.
//
// Only code in "## Sample code" or "### Sample code" sections is examined.
// Subheadings can also be specified, as in "## Sample code: foo".
//
// Additionally, code inside of dartdoc snippet and sample blocks
// ({@tool snippet ...}{@end-tool}, and {@tool sample ...}{@end-tool})
// is recognized as sample code. Snippets are processed as separate programs,
// and samples are processed in the same way as "## Sample code" blocks are.
//
// There are several kinds of sample code you can specify:
//
// * Constructor calls, typically showing what might exist in a build method.
//   These start with "new" or "const", and will be inserted into an assignment
//   expression assigning to a variable of type "dynamic" and followed by a
//   semicolon, for the purposes of analysis.
//
// * Class definitions. These start with "class", and are analyzed verbatim.
//
// * Other code. It gets included verbatim, though any line that says "// ..."
//   is considered to separate the block into multiple blocks to be processed
//   individually.
//
// In addition, you can declare code that should be included in the analysis but
// not shown in the API docs by adding a comment "// Examples can assume:" to
// the file (usually at the top of the file, after the imports), following by
// one or more commented-out lines of code. That code is included verbatim in
// the analysis.
//
// All the sample code of every file is analyzed together. This means you can't
// have two pieces of sample code that define the same example class.
//
// Also, the above means that it's tricky to include verbatim imperative code
// (e.g. a call to a method), since it won't be valid to have such code at the
// top level. Instead, wrap it in a function or even a whole class, or make it a
// valid variable declaration.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

// To run this: bin/cache/dart-sdk/bin/dart dev/bots/analyze-sample-code.dart

final String _flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String _flutter =
    path.join(_flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');

Future<void> main(List<String> arguments) async {
  Directory flutterPackage;
  if (arguments.length == 1) {
    // Used for testing.
    flutterPackage = Directory(arguments.single);
  } else {
    flutterPackage = Directory(path.join(_flutterRoot, 'packages', 'flutter', 'lib'));
  }
  await SampleChecker(flutterPackage).checkSamples();
}

class Line {
  const Line(this.filename, this.line, this.indent);
  final String filename;
  final int line;
  final int indent;
  Line get next => this + 1;
  Line operator +(int count) {
    if (count == 0) {
      return this;
    }
    return Line(filename, line + count, indent);
  }

  @override
  String toString([int column]) {
    if (column != null) {
      return '$filename:$line:${column + indent}';
    }
    return '$filename:$line';
  }
}

class Section {
  const Section(this.start, this.preamble, this.code, this.postamble);
  final Line start;
  final String preamble;
  final List<String> code;
  final String postamble;
  Iterable<String> get strings sync* {
    if (preamble != null) {
      assert(!preamble.contains('\n'));
      yield preamble;
    }
    assert(!code.any((String line) => line.contains('\n')));
    yield* code;
    if (postamble != null) {
      assert(!postamble.contains('\n'));
      yield postamble;
    }
  }

  List<Line> get lines {
    final List<Line> result = List<Line>.generate(code.length, (int index) => start + index);
    if (preamble != null) {
      result.insert(0, null);
    }
    if (postamble != null) {
      result.add(null);
    }
    return result;
  }
}

class Snippet {
  Snippet({this.start, List<String> input, List<String> args, this.serial}) {
    this.input = <String>[]..addAll(input);
    this.args = <String>[]..addAll(args);
  }
  final Line start;
  final int serial;
  List<String> input;
  List<String> args;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer('snippet ${args.join(' ')}\n');
    int count = start.line;
    for (String line in input) {
      buf.writeln(' ${count.toString().padLeft(4, ' ')}: $line');
      count++;
    }
    return buf.toString();
  }
}

class SampleChecker {
  SampleChecker(this.flutterPackage) {
    tempDir = Directory.systemTemp.createTempSync('flutter_analyze_sample_code.');
  }

  static const String kDartDocPrefix = '///';
  static const String kDartDocPrefixWithSpace = '$kDartDocPrefix ';
  static final RegExp kDartDocSampleBeginRegex = RegExp(r'{@tool (sample|snippet)(?:| ([^}]*))}');
  static final RegExp kDartDocSampleEndRegex = RegExp(r'{@end-tool}');
  static final RegExp kCodeBlockStartRegex = RegExp(r'/// ```dart.*$');
  static final RegExp kCodeBlockEndRegex = RegExp(r'/// ```\s*$');

  Directory tempDir;
  final Directory flutterPackage;
  final List<String> mainContents = <String>[];
  final List<Section> sections = <Section>[];
  final List<Snippet> snippets = <Snippet>[];
  final List<Line> lines = <Line>[];
  final RegExp _constructorRegExp = RegExp(r'[A-Z][a-zA-Z0-9<>.]*\(');
  int _expressionId = 0;

  String get snippetsExecutable {
    final String platformScriptPath = path.dirname(Platform.script.toFilePath());
    return path.canonicalize(path.join(platformScriptPath, '..', 'snippets', 'lib', 'main.dart'));
  }

  Future<void> checkSamples() async {
    final Set<File> keptFiles = Set<File>();
    File dartFile;
    try {
      _extractSamples();
      snippets.forEach(print);
      dartFile = _addBoilerplate();
      for (Snippet snippet in snippets) {
        await _createSnippet(snippet);
      }
      keptFiles.addAll(await _analyze(dartFile));
    } finally {
      if (keptFiles.isNotEmpty) {
        print('Kept ${tempDir.path} because it had errors (see above).');
        for (File file in keptFiles) {
          print('-------8< ${path.basename(file.path)} -------');
          int number = 1;
          List<String> contents;
          if (path.equals(file.path, dartFile.path)) {
            contents = mainContents;
          } else {
            contents = file.readAsLinesSync();
          }
          for (String line in contents) {
            print('${number.toString().padLeft(6, " ")}: $line');
            number += 1;
          }
          print('-------8<-------');
        }
      } else {
        print('Deleting ${tempDir.path}');
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException catch (e) {
          print('Failed to delete ${tempDir.path}: $e');
        }
      }
    }
  }

  Future<void> _createSnippet(Snippet snippet) async {
    // Generate the snippet.
    String snippetId = path.relative(snippet.start.filename, from: flutterPackage.path);
    snippetId = path.split(snippetId).join('.');
    snippetId = path.basenameWithoutExtension(snippetId);
    snippetId = 'snippet.$snippetId.${snippet.start.line}';
    final String inputName = '$snippetId.input';
    // Now we have a filename like 'lib.src.material.foo_widget.123.dart' for each snippet.
    final File inputFile = File(path.join(tempDir.path, inputName))..createSync(recursive: true);
    inputFile.writeAsStringSync(snippet.input.join('\n'));
    final File outputFile = File(path.join(tempDir.path, snippetId));
    List<String> args = <String>[
      snippetsExecutable,
      '--output=${outputFile.absolute.path}',
      '--input=${inputFile.absolute.path}'
    ]..addAll(snippet.args);
    print('Starting process: ${Platform.executable} ${args.join(' ')}');
    final ProcessResult process =
        await Process.run(Platform.executable, args, workingDirectory: _flutterRoot);
    if (process.exitCode != 0) {
      throw 'Unable to create snippet from ${inputFile.path}:\n${process.stderr}\n${process.stdout}';
    }
  }

  void _extractSamples() {
    int sampleCodeSections = 0;
    for (FileSystemEntity file in flutterPackage.listSync(recursive: true, followLinks: false)) {
      if (file is File && path.extension(file.path) == '.dart') {
        final List<String> lines = file.readAsLinesSync();
        bool inPreamble = false;
        bool inSampleSection = false;
        bool inSnippet = false;
        bool inDart = false;
        bool foundDart = false;
        int lineNumber = 0;
        final List<String> block = <String>[];
        List<String> snippetArgs = <String>[];
        Line startLine;
        for (String line in lines) {
          lineNumber += 1;
          final String trimmedLine = line.trim();
          if (inSnippet) {
            if (!trimmedLine.startsWith(kDartDocPrefix)) {
              throw '${file.path}:$lineNumber: Snippet section unterminated.';
            }
            if (kDartDocSampleEndRegex.hasMatch(trimmedLine)) {
              snippets.add(Snippet(
                  start: startLine, input: block, args: snippetArgs, serial: snippets.length));
              snippetArgs = <String>[];
              block.clear();
              inSnippet = false;
              inSampleSection = false;
            } else {
              block.add(line.replaceFirst(RegExp(r'\s*/// ?'), ''));
            }
          } else if (inPreamble) {
            if (line.isEmpty) {
              inPreamble = false;
              _processBlock(startLine, block, sections);
            } else if (!line.startsWith('// ')) {
              throw '${file.path}:$lineNumber: Unexpected content in sample code preamble.';
            } else {
              block.add(line.substring(3));
            }
          } else if (inSampleSection) {
            if (!trimmedLine.startsWith(kDartDocPrefix) ||
                trimmedLine.startsWith('$kDartDocPrefix ## ')) {
              if (inDart) {
                throw '${file.path}:$lineNumber: Dart section inexplicably unterminated.';
              }
              if (!foundDart) {
                throw '${file.path}:$lineNumber: No dart block found in sample code section';
              }
              inSampleSection = false;
            } else {
              if (inDart) {
                if (kCodeBlockEndRegex.hasMatch(trimmedLine)) {
                  inDart = false;
                  _processBlock(startLine, block, sections);
                } else if (trimmedLine == kDartDocPrefix) {
                  block.add('');
                } else {
                  final int index = line.indexOf(kDartDocPrefixWithSpace);
                  if (index < 0)
                    throw '${file.path}:$lineNumber: Dart section inexplicably did not contain "$kDartDocPrefixWithSpace" prefix.';
                  block.add(line.substring(index + 4));
                }
              } else if (kCodeBlockStartRegex.hasMatch(trimmedLine)) {
                assert(block.isEmpty);
                startLine = Line(file.path, lineNumber + 1,
                    line.indexOf(kDartDocPrefixWithSpace) + kDartDocPrefixWithSpace.length);
                inDart = true;
                foundDart = true;
              }
            }
          }
          if (!inSampleSection) {
            final Match sampleMatch = kDartDocSampleBeginRegex.firstMatch(trimmedLine);
            if (line == '// Examples can assume:') {
              assert(block.isEmpty);
              startLine = Line(file.path, lineNumber + 1, 3);
              inPreamble = true;
            } else if (trimmedLine == '/// ## Sample code' ||
                trimmedLine.startsWith('/// ## Sample code:') ||
                trimmedLine == '/// ### Sample code' ||
                trimmedLine.startsWith('/// ### Sample code:') ||
                sampleMatch != null) {
              inSnippet = sampleMatch != null ? sampleMatch[1] == 'snippet' : false;
              if (inSnippet) {
                startLine = Line(file.path, lineNumber + 1,
                    line.indexOf(kDartDocPrefixWithSpace) + kDartDocPrefixWithSpace.length);
                if (sampleMatch[2] != null) {
                  // There are arguments to the snippet tool to keep track of.
                  snippetArgs = _splitUpQuotedArgs(sampleMatch[2]).toList();
                } else {
                  snippetArgs = <String>[];
                }
              }
              inSampleSection = !inSnippet;
              foundDart = false;
              sampleCodeSections += 1;
            }
          }
        }
      }
    }
    print('Found $sampleCodeSections sample code sections.');
  }

  /// Helper to process arguments given as a (possibly quoted) string.
  ///
  /// First, this will split the given [argsAsString] into separate arguments,
  /// taking any quoting (either ' or " are accepted) into account, including
  /// handling backslash-escaped quotes.
  ///
  /// Then, it will prepend "--" to any args that start with an identifier
  /// followed by an equals sign, allowing the argument parser to treat any
  /// "foo=bar" argument as "--foo=bar" (which is a dartdoc-ism).
  Iterable<String> _splitUpQuotedArgs(String argsAsString) {
    // Regexp to take care of splitting arguments, and handling the quotes
    // around arguments, if any.
    //
    // Match group 1 is the "foo=" (or "--foo=") part of the option, if any.
    // Match group 2 contains the quote character used (which is discarded).
    // Match group 3 is a quoted arg, if any, without the quotes.
    // Match group 4 is the unquoted arg, if any.
    final RegExp argMatcher = RegExp(r'([a-zA-Z\-_0-9]+=)?' // option name
        r'(?:' // Start a new non-capture group for the two possibilities.
        r'''(["'])((?:\\{2})*|(?:.*?[^\\](?:\\{2})*))\2|''' // with quotes.
        r'([^ ]+))'); // without quotes.
    final Iterable<Match> matches = argMatcher.allMatches(argsAsString);

    // Remove quotes around args, and if convertToArgs is true, then for any
    // args that look like assignments (start with valid option names followed
    // by an equals sign), add a "--" in front so that they parse as options.
    return matches.map<String>((Match match) {
      String option = '';
      if (match[1] != null && !match[1].startsWith('-')) {
        option = '--';
      }
      if (match[2] != null) {
        // This arg has quotes, so strip them.
        return '$option${match[1] ?? ''}${match[3] ?? ''}${match[4] ?? ''}';
      }
      return '$option${match[0]}';
    });
  }

  void _createAnalysisFiles(File dartFile) {
    final File pubSpec = File(path.join(dartFile.parent.path, 'pubspec.yaml'))
      ..createSync(recursive: true);
    final File analysisOptions = File(path.join(dartFile.parent.path, 'analysis_options.yaml'))
      ..createSync(recursive: true);
    pubSpec.writeAsStringSync('''
name: analyze_sample_code
dependencies:
  flutter:
    sdk: flutter
  flutter_test:
    sdk: flutter
''');
    analysisOptions.writeAsStringSync('''
linter:
  rules:
    - unnecessary_const
    - unnecessary_new
''');
  }

  File _addBoilerplate() {
    final File mainDart = File(path.join(tempDir.path, 'main.dart'))..createSync(recursive: true);

    mainContents.add('// generated code');
    mainContents.add('import \'dart:async\';');
    mainContents.add('import \'dart:convert\';');
    mainContents.add('import \'dart:math\' as math;');
    mainContents.add('import \'dart:typed_data\';');
    mainContents.add('import \'dart:ui\' as ui;');
    mainContents.add('import \'package:flutter_test/flutter_test.dart\';');
    for (FileSystemEntity file in flutterPackage.listSync(recursive: false, followLinks: false)) {
      if (file is File && path.extension(file.path) == '.dart') {
        mainContents.add('');
        mainContents.add('// ${file.path}');
        mainContents.add('import \'package:flutter/${path.basename(file.path)}\';');
      }
    }
    mainContents.add('');
    lines.clear();
    lines.addAll(List<Line>.filled(mainContents.length, null, growable: true));
    for (Section section in sections) {
      mainContents.addAll(section.strings);
      lines.addAll(section.lines);
    }
    assert(mainContents.length == lines.length);
    mainDart.writeAsStringSync(mainContents.join('\n'));
    return mainDart;
  }

  Future<List<File>> _analyze(File dartFile) async {
    print('Beginning to analyze ${dartFile.parent.path}');
    _createAnalysisFiles(dartFile);
    bool keepDartFile = false;
    final Process process = await Process.start(
      _flutter,
      <String>['--no-wrap', 'analyze', '--no-preamble', '--no-congratulate', '.'],
      workingDirectory: dartFile.parent.path,
    );
    final List<String> errors = <String>[];
    errors.addAll(await process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .toList());
    errors.add(null);
    errors.addAll(await process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .toList());
    // top is stderr
    if (errors.isNotEmpty &&
        (errors.first.contains(' issues found. (ran in ') ||
            errors.first.contains(' issue found. (ran in '))) {
      errors.removeAt(
          0); // the "23 issues found" message goes onto stderr, which is concatenated first
      if (errors.isNotEmpty && errors.last.isEmpty)
        errors
            .removeLast(); // if there's an "issues found" message, we put a blank line on stdout before it
    }
    // null separates stderr from stdout
    if (errors.first != null) {
      throw 'cannot analyze dartdocs; unexpected error output: $errors';
    }
    errors.removeAt(0);
    // rest is stdout
    if (errors.isNotEmpty && errors.first == 'Building flutter tool...') {
      errors.removeAt(0);
    }
    if (errors.isNotEmpty && errors.first.startsWith('Running "flutter packages get" in '))
      errors.removeAt(0);
    int errorCount = 0;
    final String kBullet = Platform.isWindows ? ' - ' : ' • ';
    final RegExp errorPattern = RegExp(
        '^ +([a-z]+)$kBullet(.+)$kBullet(.+):([0-9]+):([0-9]+)$kBullet([-a-z_]+)\$',
        caseSensitive: false);
    for (String error in errors) {
      final Match parts = errorPattern.matchAsPrefix(error);
      if (parts != null) {
        final String message = parts[2];
        final String file = parts[3];
        final String line = parts[4];
        final String column = parts[5];
        final String errorCode = parts[6];
        final int lineNumber = int.parse(line, radix: 10);
        final int columnNumber = int.parse(column, radix: 10);
        final bool isSnippet = file.startsWith('snippet');
        if (file != 'main.dart' && !isSnippet) {
          keepDartFile = true;
          throw 'cannot analyze dartdocs; analysis errors exist in $file: $error';
        }
        if (!isSnippet) {
          if (lineNumber < 1 || lineNumber > lines.length) {
            keepDartFile = true;
            throw 'failed to parse error message (read line number as $lineNumber; total number of lines is ${lines.length}): $error';
          }
          final Line actualLine = lines[lineNumber - 1];
          if (errorCode == 'unused_element' || errorCode == 'unused_local_variable') {
            // We don't really care if sample code isn't used!
          } else if (actualLine == null) {
            if (errorCode == 'missing_identifier' &&
                lineNumber > 1 &&
                mainContents[lineNumber - 2].endsWith(',')) {
              final Line actualLine = lines[lineNumber - 2];
              print(
                  '${actualLine.toString(mainContents[lineNumber - 2].length - 1)}: unexpected comma at end of sample code');
              errorCount += 1;
            } else {
              print('${dartFile.path}:${lineNumber - 1}:$columnNumber: $message');
              keepDartFile = true;
              errorCount += 1;
            }
          } else {
            print('${actualLine.toString(columnNumber)}: $message ($errorCode)');
            errorCount += 1;
          }
        } else {
          keepDartFile = true;
          print('${path.basename(dartFile.path)}:$lineNumber:$columnNumber: $message');
        }
      } else {
        print('?? $error');
        keepDartFile = true;
        errorCount += 1;
      }
    }
    exitCode = await process.exitCode;
    if (exitCode == 1 && errorCount == 0) {
      exitCode = 0;
    }
    if (exitCode == 0) {
      print('No errors in ${dartFile.path}!');
    }
    return keepDartFile ? <File>[dartFile] : <File>[];
  }

  void _processBlock(Line line, List<String> block, List<Section> sections) {
    if (block.isEmpty) {
      throw '$line: Empty ```dart block in sample code.';
    }
    if (block.first.startsWith('new ') ||
        block.first.startsWith('const ') ||
        block.first.startsWith(_constructorRegExp)) {
      _expressionId += 1;
      sections.add(Section(line, 'dynamic expression$_expressionId = ', block.toList(), ';'));
    } else if (block.first.startsWith('await ')) {
      _expressionId += 1;
      sections.add(
          Section(line, 'Future<void> expression$_expressionId() async { ', block.toList(), ' }'));
    } else if (block.first.startsWith('class ') || block.first.startsWith('enum ')) {
      sections.add(Section(line, null, block.toList(), null));
    } else if ((block.first.startsWith('_') || block.first.startsWith('final ')) &&
        block.first.contains(' = ')) {
      _expressionId += 1;
      sections.add(Section(line, 'void expression$_expressionId() { ', block.toList(), ' }'));
    } else {
      final List<String> buffer = <String>[];
      int subblocks = 0;
      Line subline;
      for (int index = 0; index < block.length; index += 1) {
        if (block[index] == '' || block[index] == '// ...') {
          if (subline == null)
            throw '${line + index}: Unexpected blank line or "// ..." line near start of subblock in sample code.';
          subblocks += 1;
          _processBlock(subline, buffer, sections);
          assert(buffer.isEmpty);
          subline = null;
        } else if (block[index].startsWith('// ')) {
          if (buffer.length > 1) // don't include leading comments
            buffer.add(
                '/${block[index]}'); // so that it doesn't start with "// " and get caught in this again
        } else {
          subline ??= line + index;
          buffer.add(block[index]);
        }
      }
      if (subblocks > 0) {
        if (subline != null) {
          _processBlock(subline, buffer, sections);
        }
      } else {
        sections.add(Section(line, null, block.toList(), null));
      }
    }
    block.clear();
  }
}

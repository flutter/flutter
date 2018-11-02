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
  const Line(this.code, {this.filename, this.line, this.indent});
  final String filename;
  final int line;
  final int indent;
  final String code;

  String toStringWithColumn(int column) {
    if (column != null) {
      return '$filename:$line:${column + indent}: $code';
    }
    return toString();
  }

  @override
  String toString() => '$filename:$line: $code';
}

class Section {
  const Section(this.code);
  factory Section.combine(List<Section> sections) {
    final List<Line> code = <Line>[];
    for (Section section in sections) {
      code.addAll(section.code);
    }
    return Section(code);
  }
  factory Section.fromStrings(Line firstLine, List<String> code) {
    final List<Line> codeLines = <Line>[];
    for (int i = 0; i < code.length; ++i) {
      codeLines.add(Line(code[i],
          filename: firstLine.filename, line: firstLine.line + i, indent: firstLine.indent));
    }
    return Section(codeLines);
  }
  factory Section.surround(Line firstLine, String prefix, List<String> code, String postfix) {
    assert(prefix != null);
    assert(postfix != null);
    final List<Line> codeLines = <Line>[];
    for (int i = 0; i < code.length; ++i) {
      codeLines.add(Line(code[i],
          filename: firstLine.filename, line: firstLine.line + i, indent: firstLine.indent));
    }
    return Section(<Line>[Line(prefix)]
      ..addAll(codeLines)
      ..add(Line(postfix)));
  }
  Line get start => code.firstWhere((Line line) => line.filename != null);
  final List<Line> code;
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

class AnalysisError {
  const AnalysisError(this.line, this.column, this.message, {this.source});

  final int line;
  final int column;
  final String message;
  final Line source;

  @override
  String toString() => '$message:\n${source?.toStringWithColumn(column)}';
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
  final List<Snippet> snippets = <Snippet>[];
  final RegExp _constructorRegExp = RegExp(r'[A-Z][a-zA-Z0-9<>.]*\(');
  int _expressionId = 0;

  String get snippetsExecutable {
    final String platformScriptPath = path.dirname(Platform.script.toFilePath());
    return path.canonicalize(path.join(platformScriptPath, '..', 'snippets', 'lib', 'main.dart'));
  }

  List<Line> _headers;
  List<Line> get headers {
    if (_headers == null) {
      final List<String> buffer = <String>[];
      buffer.add('// generated code');
      buffer.add('import \'dart:async\';');
      buffer.add('import \'dart:convert\';');
      buffer.add('import \'dart:math\' as math;');
      buffer.add('import \'dart:typed_data\';');
      buffer.add('import \'dart:ui\' as ui;');
      buffer.add('import \'package:flutter_test/flutter_test.dart\';');
      for (FileSystemEntity file in flutterPackage.listSync(recursive: false, followLinks: false)) {
        if (file is File && path.extension(file.path) == '.dart') {
          buffer.add('');
          buffer.add('// ${file.path}');
          buffer.add('import \'package:flutter/${path.basename(file.path)}\';');
        }
      }
      _headers = buffer.map<Line>((String code) => Line(code)).toList();
    }
    return _headers;
  }

  Future<void> checkSamples() async {
    Map<String, List<AnalysisError>> errors = <String, List<AnalysisError>>{};
    try {
      final Map<String, Section> sections = <String, Section>{};
      for (Section section in _extractSamples()) {
        sections[_writeSection(section).path] = section;
      }
      for (Snippet snippet in snippets) {
        await _createSnippet(snippet);
      }
      errors = await _analyze(tempDir, sections);
    } finally {
      if (errors.isNotEmpty) {
        print('Kept temporary directory ${tempDir.path} because there were errors.');
        for (String filePath in errors.keys) {
          print('-------8< ${path.basename(filePath)} -------');
          errors[filePath].forEach(print);
//          int number = 1;
//          List<String> contents;
//          if (path.equals(file.path, dartFile.path)) {
//            contents = mainContents;
//          } else {
//            contents = File(path.join(tempDir.path, file.path)).readAsLinesSync();
//          }
//          for (String line in contents) {
//            print('${number.toString().padLeft(6, " ")}: $line');
//            number += 1;
//          }
          print('-------8<-------');
        }
      } else {
        print('Deleting ${tempDir.path}');
//        try {
//          tempDir.deleteSync(recursive: true);
//        } on FileSystemException catch (e) {
//          print('Failed to delete ${tempDir.path}: $e');
//        }
      }
    }
  }

  String _createNameFromSource(String prefix, String filename, int start) {
    String snippetId = path.relative(filename, from: flutterPackage.path);
    snippetId = path.split(snippetId).join('.');
    snippetId = path.basenameWithoutExtension(snippetId);
    snippetId = '$prefix.$snippetId.$start';
    return snippetId;
  }

  Future<void> _createSnippet(Snippet snippet) async {
    // Generate the snippet.
    final String snippetId =
        _createNameFromSource('snippet', snippet.start.filename, snippet.start.line);
    final String inputName = '$snippetId.input';
    // Now we have a filename like 'lib.src.material.foo_widget.123.dart' for each snippet.
    final File inputFile = File(path.join(tempDir.path, inputName))..createSync(recursive: true);
    inputFile.writeAsStringSync(snippet.input.join('\n'));
    final File outputFile = File(path.join(tempDir.path, '$snippetId.dart'));
    final List<String> args = <String>[
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

  List<Section> _extractSamples() {
    final List<Section> sections = <Section>[];
    for (FileSystemEntity file in flutterPackage.listSync(recursive: true, followLinks: false)) {
      if (file is File && path.extension(file.path) == '.dart') {
        final String relativeFilePath = path.relative(file.path, from: _flutterRoot);
        final List<String> sampleLines = file.readAsLinesSync();
        final List<Section> preambleSections = <Section>[];
        bool inPreamble = false;
        bool inSampleSection = false;
        bool inSnippet = false;
        bool inDart = false;
        bool foundDart = false;
        int lineNumber = 0;
        final List<String> block = <String>[];
        List<String> snippetArgs = <String>[];
        Line startLine;
        for (String line in sampleLines) {
          lineNumber += 1;
          final String trimmedLine = line.trim();
          if (inSnippet) {
            if (!trimmedLine.startsWith(kDartDocPrefix)) {
              throw '$relativeFilePath:$lineNumber: Snippet section unterminated.';
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
              preambleSections.add(_processBlock(startLine, block));
              block.clear();
            } else if (!line.startsWith('// ')) {
              throw '$relativeFilePath:$lineNumber: Unexpected content in sample code preamble.';
            } else {
              block.add(line.substring(3));
            }
          } else if (inSampleSection) {
            if (!trimmedLine.startsWith(kDartDocPrefix) ||
                trimmedLine.startsWith('$kDartDocPrefix ## ')) {
              if (inDart) {
                throw '$relativeFilePath:$lineNumber: Dart section inexplicably unterminated.';
              }
              if (!foundDart) {
                throw '$relativeFilePath:$lineNumber: No dart block found in sample code section';
              }
              inSampleSection = false;
            } else {
              if (inDart) {
                if (kCodeBlockEndRegex.hasMatch(trimmedLine)) {
                  inDart = false;
                  final Section processed = _processBlock(startLine, block);
                  if (preambleSections.isEmpty) {
                    sections.add(processed);
                  } else {
                    sections.add(Section.combine(preambleSections
                      ..toList()
                      ..add(processed)));
                  }
                  block.clear();
                } else if (trimmedLine == kDartDocPrefix) {
                  block.add('');
                } else {
                  final int index = line.indexOf(kDartDocPrefixWithSpace);
                  if (index < 0)
                    throw '$relativeFilePath:$lineNumber: Dart section inexplicably did not contain "$kDartDocPrefixWithSpace" prefix.';
                  block.add(line.substring(index + 4));
                }
              } else if (kCodeBlockStartRegex.hasMatch(trimmedLine)) {
                assert(block.isEmpty);
                startLine = Line('',
                    filename: relativeFilePath,
                    line: lineNumber + 1,
                    indent: line.indexOf(kDartDocPrefixWithSpace) + kDartDocPrefixWithSpace.length);
                inDart = true;
                foundDart = true;
              }
            }
          }
          if (!inSampleSection) {
            final Match sampleMatch = kDartDocSampleBeginRegex.firstMatch(trimmedLine);
            if (line == '// Examples can assume:') {
              assert(block.isEmpty);
              startLine = Line('', filename: relativeFilePath, line: lineNumber + 1, indent: 3);
              inPreamble = true;
            } else if (trimmedLine == '/// ## Sample code' ||
                trimmedLine.startsWith('/// ## Sample code:') ||
                trimmedLine == '/// ### Sample code' ||
                trimmedLine.startsWith('/// ### Sample code:') ||
                sampleMatch != null) {
              inSnippet = sampleMatch != null ? sampleMatch[1] == 'snippet' : false;
              if (inSnippet) {
                startLine = Line('',
                    filename: relativeFilePath,
                    line: lineNumber + 1,
                    indent: line.indexOf(kDartDocPrefixWithSpace) + kDartDocPrefixWithSpace.length);
                if (sampleMatch[2] != null) {
                  // There are arguments to the snippet tool to keep track of.
                  snippetArgs = _splitUpQuotedArgs(sampleMatch[2]).toList();
                } else {
                  snippetArgs = <String>[];
                }
              }
              inSampleSection = !inSnippet;
              foundDart = false;
            }
          }
        }
      }
    }
    print('Found ${sections.length} sample code sections.');
    return sections;
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

  void _createAnalysisFiles(Directory directory) {
    final File pubSpec = File(path.join(directory.path, 'pubspec.yaml'))
      ..createSync(recursive: true);
    final File analysisOptions = File(path.join(directory.path, 'analysis_options.yaml'))
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

  File _writeSection(Section section) {
    final String sectionId =
        _createNameFromSource('sample', section.start.filename, section.start.line);
    final File outputFile = File(path.join(tempDir.path, '$sectionId.dart'))
      ..createSync(recursive: true);
    final List<Line> mainContents = headers.toList();
    mainContents.add(const Line(''));
    mainContents.add(Line('// From: ${section.start.filename}:${section.start.line}'));
    mainContents.addAll(section.code);
    outputFile.writeAsStringSync(mainContents.map<String>((Line line) => line.code).join('\n'));
    return outputFile;
  }

  Future<List<String>> _runAnalyzer(Directory directory) async {
    print('Starting analysis of ${directory.absolute.path}');
    _createAnalysisFiles(directory);
    final ProcessResult result = await Process.run(
      _flutter,
      <String>['--no-wrap', 'analyze', '--no-preamble', '--no-congratulate', '.'],
      workingDirectory: directory.absolute.path,
    );
    final List<String> stderr = result.stderr.toString().trim().split('\n');
    final List<String> stdout = result.stdout.toString().trim().split('\n');
    // Check out the stderr to see if the analyzer had it's own issues.
    if (stderr.isNotEmpty &&
        (stderr.first.contains(' issues found. (ran in ') ||
            stderr.first.contains(' issue found. (ran in '))) {
      stderr.removeAt(
          0); // the "23 issues found" message goes onto stderr, which is concatenated first
      if (stderr.isNotEmpty && stderr.last.isEmpty)
        stderr
            .removeLast(); // if there's an "issues found" message, we put a blank line on stdout before it
    }
    if (stderr.isNotEmpty) {
      throw 'Cannot analyze dartdocs; unexpected error output:\n$stderr';
    }
    if (stdout.isNotEmpty && stdout.first == 'Building flutter tool...') {
      stdout.removeAt(0);
    }
    if (stdout.isNotEmpty && stdout.first.startsWith('Running "flutter packages get" in '))
      stdout.removeAt(0);
    exitCode = result.exitCode;
    return stdout;
  }

  Future<Map<String, List<AnalysisError>>> _analyze(
      Directory directory, Map<String, Section> sections) async {
    final List<String> errors = await _runAnalyzer(directory);
    final Map<String, List<AnalysisError>> analysisErrors = <String, List<AnalysisError>>{};
    void addAnalysisError(File file, AnalysisError error) {
      if (analysisErrors.containsKey(file.path)) {
        analysisErrors[file.path].add(error);
      } else {
        analysisErrors[file.path] = <AnalysisError>[error];
      }
    }

    final String kBullet = Platform.isWindows ? ' - ' : ' • ';
    final RegExp errorPattern = RegExp(
        '^ +([a-z]+)$kBullet(.+)$kBullet(.+):([0-9]+):([0-9]+)$kBullet([-a-z_]+)\$',
        caseSensitive: false);
    bool unknownAnalyzerErrors = false;
    final int headerLength = headers.length + 2;
    for (String error in errors) {
      final Match parts = errorPattern.matchAsPrefix(error);
      if (parts != null) {
        final String message = parts[2];
        final File file = File(path.join(tempDir.path, parts[3]));
        final List<String> fileContents = file.readAsLinesSync();
        final bool isSnippet = path.basename(file.path).startsWith('snippet.');
        final bool isSample = path.basename(file.path).startsWith('sample.');
        final String line = parts[4];
        final String column = parts[5];
        final String errorCode = parts[6];
        final int lineNumber = int.parse(line, radix: 10) - (isSample ? headerLength : 0);
        final int columnNumber = int.parse(column, radix: 10);
        if (lineNumber < 0 && errorCode == 'unused_import') {
          // We don't care about unused imports.
          continue;
        }

        // For when errors occur outside of the things we're trying to analyze.
        if (!isSnippet && !isSample) {
          addAnalysisError(file, AnalysisError(lineNumber, columnNumber, message));
          throw 'Cannot analyze dartdocs; analysis errors exist in $file: $error';
        }

        if (isSnippet) {
          addAnalysisError(file, AnalysisError(lineNumber, columnNumber, message));
        } else {
          if (lineNumber < 1 || lineNumber > fileContents.length) {
            addAnalysisError(file, AnalysisError(lineNumber, columnNumber, message));
            throw 'Failed to parse error message (read line number as $lineNumber; '
                'total number of lines is ${fileContents.length}): $error';
          }

          final Section actualSection = sections[file.path];
          final Line actualLine = actualSection.code[lineNumber - 1];
          if (errorCode == 'unused_element' || errorCode == 'unused_local_variable') {
            // We don't really care if sample code isn't used!
          } else if (actualLine.filename == null) {
            if (errorCode == 'missing_identifier' && lineNumber > 1) {
              if (fileContents[lineNumber - 2].endsWith(',')) {
                final Line actualLine = sections[file.path].code[lineNumber - 2];
                addAnalysisError(
                  file,
                  AnalysisError(
                    actualLine.line,
                    actualLine.indent + fileContents[lineNumber - 2].length - 1,
                    'Unexpected comma at end of sample code.',
                  ),
                );
              }
            } else {
              addAnalysisError(
                  file, AnalysisError(lineNumber - 1, columnNumber, message, source: actualLine));
            }
          } else {
            addAnalysisError(
                file,
                AnalysisError(
                    actualLine.line, actualLine.indent + columnNumber, '$message ($errorCode)',
                    source: actualLine));
          }
        }
      } else {
        stderr.writeln('Analyzer output: $error');
        unknownAnalyzerErrors = true;
      }
    }
    if (exitCode == 1 && analysisErrors.isEmpty && !unknownAnalyzerErrors) {
      exitCode = 0;
    }
    if (exitCode == 0) {
      print('No analysis errors in samples!');
    }
    return analysisErrors;
  }

  Section _processBlock(Line line, List<String> block) {
    if (block.isEmpty) {
      throw '$line: Empty ```dart block in sample code.';
    }
    if (block.first.startsWith('new ') ||
        block.first.startsWith('const ') ||
        block.first.startsWith(_constructorRegExp)) {
      _expressionId += 1;
      return Section.surround(line, 'dynamic expression$_expressionId = ', block.toList(), ';');
    } else if (block.first.startsWith('await ')) {
      _expressionId += 1;
      return Section.surround(
          line, 'Future<void> expression$_expressionId() async { ', block.toList(), ' }');
    } else if (block.first.startsWith('class ') || block.first.startsWith('enum ')) {
      return Section.fromStrings(line, block.toList());
    } else if ((block.first.startsWith('_') || block.first.startsWith('final ')) &&
        block.first.contains(' = ')) {
      _expressionId += 1;
      return Section.surround(line, 'void expression$_expressionId() { ', block.toList(), ' }');
    } else {
      final List<String> buffer = <String>[];
      int subblocks = 0;
      Line subline;
      final List<Section> subsections = <Section>[];
      for (int index = 0; index < block.length; index += 1) {
        // Each section of the dart code that is either split by a blank line, or with '// ...' is
        // treated as a separate code block.
        if (block[index] == '' || block[index] == '// ...') {
          if (subline == null)
            throw '${Line('', filename: line.filename, line: line.line + index, indent: line.indent)}: Unexpected blank line or "// ..." line near start of subblock in sample code.';
          subblocks += 1;
          subsections.add(_processBlock(subline, buffer));
          buffer.clear();
          assert(buffer.isEmpty);
          subline = null;
        } else if (block[index].startsWith('// ')) {
          if (buffer.length > 1) // don't include leading comments
            buffer.add(
                '/${block[index]}'); // so that it doesn't start with "// " and get caught in this again
        } else {
          subline ??= Line(block[index],
              filename: line.filename, line: line.line + index, indent: line.indent);
          buffer.add(block[index]);
        }
      }
      if (subblocks > 0) {
        if (subline != null) {
          subsections.add(_processBlock(subline, buffer));
        }
        // Combine all of the subsections into one section, now that they've been processed.
        return Section.combine(subsections);
      } else {
        return Section.fromStrings(line, block.toList());
      }
    }
  }
}

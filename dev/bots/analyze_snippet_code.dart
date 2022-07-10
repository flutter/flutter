// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See ../snippets/README.md for documentation.

// To run this, from the root of the Flutter repository:
//   bin/cache/dart-sdk/bin/dart dev/bots/analyze_snippet_code.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

final String _flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String _defaultFlutterPackage = path.join(_flutterRoot, 'packages', 'flutter', 'lib');
final String _defaultDartUiLocation = path.join(_flutterRoot, 'bin', 'cache', 'pkg', 'sky_engine', 'lib', 'ui');
final String _flutter = path.join(_flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    'temp',
    help: 'A location where temporary files may be written. Defaults to a '
          'directory in the system temp folder. If specified, will not be '
          'automatically removed at the end of execution.',
  );
  argParser.addFlag(
    'verbose',
    negatable: false,
    help: 'Print verbose output for the analysis process.',
  );
  argParser.addOption(
    'dart-ui-location',
    defaultsTo: _defaultDartUiLocation,
    help: 'A location where the dart:ui dart files are to be found. Defaults to '
          'the sky_engine directory installed in this flutter repo. This '
          'is typically the engine/src/flutter/lib/ui directory in an engine dev setup. '
          'Implies --include-dart-ui.',
  );
  argParser.addFlag(
    'include-dart-ui',
    defaultsTo: true,
    help: 'Includes the dart:ui code supplied by the engine in the analysis.',
  );
  argParser.addFlag(
    'help',
    negatable: false,
    help: 'Print help for this command.',
  );
  argParser.addOption(
    'interactive',
    abbr: 'i',
    help: 'Analyzes the snippet code in the specified file interactively.',
  );

  final ArgResults parsedArguments = argParser.parse(arguments);

  if (parsedArguments['help'] as bool) {
    print(argParser.usage);
    print('See dev/snippets/README.md for documentation.');
    exit(0);
  }

  Directory flutterPackage;
  if (parsedArguments.rest.length == 1) {
    // Used for testing.
    flutterPackage = Directory(parsedArguments.rest.single);
  } else {
    flutterPackage = Directory(_defaultFlutterPackage);
  }

  final bool includeDartUi = parsedArguments.wasParsed('dart-ui-location') || parsedArguments['include-dart-ui'] as bool;
  late Directory dartUiLocation;
  if (((parsedArguments['dart-ui-location'] ?? '') as String).isNotEmpty) {
    dartUiLocation = Directory(
        path.absolute(parsedArguments['dart-ui-location'] as String));
  } else {
    dartUiLocation = Directory(_defaultDartUiLocation);
  }
  if (!dartUiLocation.existsSync()) {
    stderr.writeln('Unable to find dart:ui directory ${dartUiLocation.path}');
    exit(-1);
  }

  Directory? tempDirectory;
  if (parsedArguments.wasParsed('temp')) {
    final String tempArg = parsedArguments['temp'] as String;
    tempDirectory = Directory(path.join(Directory.systemTemp.absolute.path, path.basename(tempArg)));
    if (path.basename(tempArg) != tempArg) {
      stderr.writeln('Supplied temporary directory name should be a name, not a path. Using ${tempDirectory.absolute.path} instead.');
    }
    print('Leaving temporary output in ${tempDirectory.absolute.path}.');
    // Make sure that any directory left around from a previous run is cleared
    // out.
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
    tempDirectory.createSync();
  }

  if (parsedArguments['interactive'] != null) {
    await _runInteractive(
      tempDir: tempDirectory,
      flutterPackage: flutterPackage,
      filePath: parsedArguments['interactive'] as String,
      dartUiLocation: includeDartUi ? dartUiLocation : null,
    );
  } else {
    try {
      exitCode = await _SnippetChecker(
        flutterPackage,
        tempDirectory: tempDirectory,
        verbose: parsedArguments['verbose'] as bool,
        dartUiLocation: includeDartUi ? dartUiLocation : null,
      ).checkSnippets();
    } on _SnippetCheckerException catch (e) {
      stderr.write(e);
      exit(1);
    }
  }
}

class _SnippetCheckerException implements Exception {
  _SnippetCheckerException(this.message, {this.file, this.line});
  final String message;
  final String? file;
  final int? line;

  @override
  String toString() {
    if (file != null || line != null) {
      final String fileStr = file == null ? '' : '$file:';
      final String lineStr = line == null ? '' : '$line:';
      return '$fileStr$lineStr Error: $message';
    } else {
      return 'Error: $message';
    }
  }
}

class _AnalysisResult {
  const _AnalysisResult(this.exitCode, this.errors);
  final int exitCode;
  final Map<String, List<_AnalysisError>> errors;
}

/// Checks code snippets for analysis errors.
///
/// Extracts dartdoc content from flutter package source code, identifies code
/// sections, and writes them to a temporary directory, where 'flutter analyze'
/// is used to analyze the sources for problems. If problems are found, the
/// error output from the analyzer is parsed for details, and the problem
/// locations are translated back to the source location.
class _SnippetChecker {
  /// Creates a [_SnippetChecker].
  ///
  /// The positional argument is the path to the package directory for the
  /// flutter package within the Flutter root dir.
  ///
  /// The optional `tempDirectory` argument supplies the location for the
  /// temporary files to be written and analyzed. If not supplied, it defaults
  /// to a system generated temp directory.
  ///
  /// The optional `verbose` argument indicates whether or not status output
  /// should be emitted while doing the check.
  ///
  /// The optional `dartUiLocation` argument indicates the location of the
  /// `dart:ui` code to be analyzed along with the framework code. If not
  /// supplied, the default location of the `dart:ui` code in the Flutter
  /// repository is used (i.e. "<flutter repo>/bin/cache/pkg/sky_engine/lib/ui").
  _SnippetChecker(
    this._flutterPackage, {
    Directory? tempDirectory,
    this.verbose = false,
    Directory? dartUiLocation,
  }) : _tempDirectory = tempDirectory ?? Directory.systemTemp.createTempSync('flutter_analyze_snippet_code.'),
       _keepTmp = tempDirectory != null,
       _dartUiLocation = dartUiLocation;

  /// The prefix of each comment line
  static const String _dartDocPrefix = '///';

  /// The prefix of each comment line with a space appended.
  static const String _dartDocPrefixWithSpace = '$_dartDocPrefix ';

  /// A RegExp that matches the beginning of a dartdoc snippet.
  static final RegExp _dartDocSnippetBeginRegex = RegExp(r'{@tool snippet(?:| ([^}]*))}');

  /// A RegExp that matches the end of a dartdoc snippet.
  static final RegExp _dartDocSnippetEndRegex = RegExp(r'{@end-tool}');

  /// A RegExp that matches the start of a code block within dartdoc.
  static final RegExp _codeBlockStartRegex = RegExp(r'///\s+```dart.*$');

  /// A RegExp that matches the end of a code block within dartdoc.
  static final RegExp _codeBlockEndRegex = RegExp(r'///\s+```\s*$');

  /// A RegExp that matches a Dart constructor.
  static final RegExp _constructorRegExp = RegExp(r'(const\s+)?_*[A-Z][a-zA-Z0-9<>._]*\(');

  /// A RegExp that matches a dart version specification in an example preamble.
  static final RegExp _dartVersionRegExp = RegExp(r'\/\/ \/\/ @dart = ([0-9]+\.[0-9]+)');

  /// Whether or not to print verbose output.
  final bool verbose;

  /// Whether or not to keep the temp directory around after running.
  ///
  /// Defaults to false.
  final bool _keepTmp;

  /// The temporary directory where all output is written. This will be deleted
  /// automatically if there are no errors.
  final Directory _tempDirectory;

  /// The package directory for the flutter package within the flutter root dir.
  final Directory _flutterPackage;

  /// The directory for the dart:ui code to be analyzed with the flutter code.
  ///
  /// If this is null, then no dart:ui code is included in the analysis.  It
  /// defaults to the location inside of the flutter bin/cache directory that
  /// contains the dart:ui code supplied by the engine.
  final Directory? _dartUiLocation;

  /// A serial number so that we can create unique expression names when we
  /// generate them.
  int _expressionId = 0;

  static List<File> _listDartFiles(Directory directory, {bool recursive = false}) {
    return directory.listSync(recursive: recursive, followLinks: false).whereType<File>().where((File file) => path.extension(file.path) == '.dart').toList();
  }

  /// Computes the headers needed for each snippet file.
  List<_Line> get headers {
    return _headers ??= <String>[
      '// ignore_for_file: directives_ordering',
      '// ignore_for_file: unnecessary_import',
      '// ignore_for_file: unused_import',
      '// ignore_for_file: unused_element',
      '// ignore_for_file: unused_local_variable',
      "import 'dart:async';",
      "import 'dart:convert';",
      "import 'dart:math' as math;",
      "import 'dart:typed_data';",
      "import 'dart:ui' as ui;",
      "import 'package:flutter_test/flutter_test.dart';",
      for (final File file in _listDartFiles(Directory(_defaultFlutterPackage)))
        "import 'package:flutter/${path.basename(file.path)}';",
    ].map<_Line>((String code) => _Line.generated(code: code, filename: 'headers')).toList();
  }

  List<_Line>? _headers;

  /// Checks all the snippets in the Dart files in [_flutterPackage] for errors.
  Future<int> checkSnippets() async {
    _AnalysisResult? analysisResult;
    try {
      final Map<String, _Section> sections = <String, _Section>{};
      if (_dartUiLocation != null && !_dartUiLocation!.existsSync()) {
        stderr.writeln('Unable to analyze engine dart snippets at ${_dartUiLocation!.path}.');
      }
      final List<File> filesToAnalyze = <File>[
        ..._listDartFiles(_flutterPackage, recursive: true),
        if (_dartUiLocation != null && _dartUiLocation!.existsSync()) ... _listDartFiles(_dartUiLocation!, recursive: true),
      ];
      await _extractSnippets(filesToAnalyze, sectionMap: sections);
      analysisResult = _analyze(_tempDirectory, sections);
    } finally {
      if (analysisResult != null && analysisResult.errors.isNotEmpty) {
        for (final String filePath in analysisResult.errors.keys) {
          analysisResult.errors[filePath]!.forEach(stderr.writeln);
        }
        stderr.writeln('\nFound ${analysisResult.errors.length} snippet code errors.');
      }
      if (_keepTmp) {
        print('Leaving temporary directory ${_tempDirectory.path} around for your perusal.');
      } else {
        try {
          _tempDirectory.deleteSync(recursive: true);
        } on FileSystemException catch (e) {
          stderr.writeln('Failed to delete ${_tempDirectory.path}: $e');
        }
      }
    }
    return analysisResult.exitCode;
  }

  /// Creates a name for the snippets tool to use for the snippet ID from a
  /// filename and starting line number.
  String _createNameFromSource(String prefix, String filename, int start) {
    String snippetId = path.split(filename).join('.');
    snippetId = path.basenameWithoutExtension(snippetId);
    snippetId = '$prefix.$snippetId.$start';
    return snippetId;
  }

  /// Extracts the snippets from the Dart files in [files], writes them
  /// to disk, and adds them to the [sectionMap].
  Future<void> _extractSnippets(
    List<File> files, {
    required Map<String, _Section> sectionMap,
    bool silent = false,
  }) async {
    final List<_Section> sections = <_Section>[];

    for (final File file in files) {
      final String relativeFilePath = path.relative(file.path, from: _flutterRoot);
      final List<String> snippetLine = file.readAsLinesSync();
      final List<_Section> preambleSections = <_Section>[];
      // Whether or not we're in the file-wide preamble section ("Examples can assume").
      bool inPreamble = false;
      // Whether or not we're in a code snippet
      bool inSnippetSection = false;
      // Whether or not we're in a '```dart' segment.
      bool inDart = false;
      String? dartVersionOverride;
      int lineNumber = 0;
      final List<String> block = <String>[];
      late _Line startLine;
      for (final String line in snippetLine) {
        lineNumber += 1;
        final String trimmedLine = line.trim();
        if (inPreamble) {
          if (line.isEmpty) {
            inPreamble = false;
            // If there's only a dartVersionOverride in the preamble, don't add
            // it as a section. The dartVersionOverride was processed below.
            if (dartVersionOverride == null || block.isNotEmpty) {
              preambleSections.add(_processBlock(startLine, block));
            }
            block.clear();
          } else if (!line.startsWith('// ')) {
            throw _SnippetCheckerException('Unexpected content in snippet code preamble.', file: relativeFilePath, line: lineNumber);
          } else if (_dartVersionRegExp.hasMatch(line)) {
            dartVersionOverride = line.substring(3);
          } else {
            block.add(line.substring(3));
          }
        } else if (inSnippetSection) {
          if (_dartDocSnippetEndRegex.hasMatch(trimmedLine)) {
            if (inDart) {
              throw _SnippetCheckerException("Dart section didn't terminate before end of snippet", file: relativeFilePath, line: lineNumber);
            }
            inSnippetSection = false;
          }
          if (inDart) {
            if (_codeBlockEndRegex.hasMatch(trimmedLine)) {
              inDart = false;
              final _Section processed = _processBlock(startLine, block);
              final _Section combinedSection = preambleSections.isEmpty ? processed : _Section.combine(preambleSections..add(processed));
              sections.add(combinedSection.copyWith(dartVersionOverride: dartVersionOverride));
              block.clear();
            } else if (trimmedLine == _dartDocPrefix) {
              block.add('');
            } else {
              final int index = line.indexOf(_dartDocPrefixWithSpace);
              if (index < 0) {
                throw _SnippetCheckerException(
                  'Dart section inexplicably did not contain "$_dartDocPrefixWithSpace" prefix.',
                  file: relativeFilePath,
                  line: lineNumber,
                );
              }
              block.add(line.substring(index + 4));
            }
          } else if (_codeBlockStartRegex.hasMatch(trimmedLine)) {
            assert(block.isEmpty);
            startLine = _Line(
              filename: relativeFilePath,
              line: lineNumber + 1,
              indent: line.indexOf(_dartDocPrefixWithSpace) + _dartDocPrefixWithSpace.length,
            );
            inDart = true;
          }
        }
        if (!inSnippetSection) {
          final RegExpMatch? snippetMatch = _dartDocSnippetBeginRegex.firstMatch(trimmedLine);
          if (line == '// Examples can assume:') {
            assert(block.isEmpty);
            startLine = _Line.generated(filename: relativeFilePath, line: lineNumber + 1, indent: 3);
            inPreamble = true;
          } else if (snippetMatch != null) {
            inSnippetSection = true;
          } else if (RegExp(r'///\s*#+\s+[Ss]ample\s+[Cc]ode:?$').hasMatch(trimmedLine)) {
            throw _SnippetCheckerException(
              "Found deprecated '## Sample code' section: use {@tool snippet}...{@end-tool} instead.",
              file: relativeFilePath,
              line: lineNumber,
            );
          }
        }
      }
    }
    if (!silent)
      print('Found ${sections.length} snippet code blocks');
    for (final _Section section in sections) {
      final String path = _writeSection(section).path;
      if (sectionMap != null)
        sectionMap[path] = section;
    }
  }

  /// Creates the configuration files necessary for the analyzer to consider
  /// the temporary directory a package, and sets which lint rules to enforce.
  void _createConfigurationFiles(Directory directory) {
    final File targetPubSpec = File(path.join(directory.path, 'pubspec.yaml'));
    if (!targetPubSpec.existsSync()) {
      // Copying pubspec.yaml from examples/api into temp directory.
      final File sourcePubSpec = File(path.join(_flutterRoot, 'examples', 'api', 'pubspec.yaml'));
      if (!sourcePubSpec.existsSync()) {
        throw 'Cannot find pubspec.yaml at ${sourcePubSpec.path}, which is also used to analyze code snippets.';
      }
      sourcePubSpec.copySync(targetPubSpec.path);
    }
    final File targetAnalysisOptions = File(path.join(directory.path, 'analysis_options.yaml'));
    if (!targetAnalysisOptions.existsSync()) {
      // Use the same analysis_options.yaml configuration that's used for examples/api.
      final File sourceAnalysisOptions = File(path.join(_flutterRoot, 'examples', 'api', 'analysis_options.yaml'));
      if (!sourceAnalysisOptions.existsSync()) {
        throw 'Cannot find analysis_options.yaml at ${sourceAnalysisOptions.path}, which is also used to analyze code snippets.';
      }
      targetAnalysisOptions
        ..createSync(recursive: true)
        ..writeAsStringSync('include: ${sourceAnalysisOptions.absolute.path}');
    }
  }

  /// Writes out a snippet section to the disk and returns the file.
  File _writeSection(_Section section) {
    final String sectionId = _createNameFromSource('snippet', section.start.filename, section.start.line);
    final File outputFile = File(path.join(_tempDirectory.path, '$sectionId.dart'))..createSync(recursive: true);
    final List<_Line> mainContents = <_Line>[
      _Line.generated(code: section.dartVersionOverride ?? '', filename: section.start.filename),
      ...headers,
      _Line.generated(filename: section.start.filename),
      _Line.generated(code: '// From: ${section.start.filename}:${section.start.line}', filename: section.start.filename),
      ...section.code,
      _Line.generated(filename: section.start.filename), // empty line at EOF
    ];
    outputFile.writeAsStringSync(mainContents.map<String>((_Line line) => line.code).join('\n'));
    return outputFile;
  }

  /// Invokes the analyzer on the given [directory] and returns the stdout.
  int _runAnalyzer(Directory directory, {bool silent = true, required List<String> output}) {
    if (!silent)
      print('Starting analysis of code snippets.');
    _createConfigurationFiles(directory);
    final ProcessResult result = Process.runSync(
      _flutter,
      <String>['--no-wrap', 'analyze', '--no-preamble', '--no-congratulate', '.'],
      workingDirectory: directory.absolute.path,
    );
    final List<String> stderr = result.stderr.toString().trim().split('\n');
    final List<String> stdout = result.stdout.toString().trim().split('\n');
    // Remove output from building the flutter tool.
    stderr.removeWhere((String line) {
      return line.startsWith('Building flutter tool...')
          || line.startsWith('Waiting for another flutter command to release the startup lock...')
          || line.startsWith('Flutter assets will be downloaded from ');
    });
    // Check out the stderr to see if the analyzer had it's own issues.
    if (stderr.isNotEmpty && stderr.first.contains(RegExp(r' issues? found\. \(ran in '))) {
      stderr.removeAt(0);
      if (stderr.isNotEmpty && stderr.last.isEmpty) {
        stderr.removeLast();
      }
    }
    if (stderr.isNotEmpty && stderr.any((String line) => line.isNotEmpty)) {
      throw 'Cannot analyze dartdocs; unexpected error output:\n$stderr';
    }
    if (stdout.isNotEmpty && stdout.first == 'Building flutter tool...') {
      stdout.removeAt(0);
    }
    if (stdout.isNotEmpty && stdout.first.startsWith('Running "flutter pub get" in ')) {
      stdout.removeAt(0);
    }
    output.addAll(stdout);
    return result.exitCode;
  }

  /// Starts the analysis phase of checking the snippets by invoking the analyzer
  /// and parsing its output to create a map of filename to [_AnalysisError]s.
  _AnalysisResult _analyze(
    Directory directory,
    Map<String, _Section> sections, {
    bool silent = false,
  }) {
    final List<String> errors = <String>[];
    int exitCode = _runAnalyzer(directory, silent: silent, output: errors);

    final Map<String, List<_AnalysisError>> analysisErrors = <String, List<_AnalysisError>>{};
    void addAnalysisError(File file, _AnalysisError error) {
      if (analysisErrors.containsKey(file.path)) {
        analysisErrors[file.path]!.add(error);
      } else {
        analysisErrors[file.path] = <_AnalysisError>[error];
      }
    }

    final String kBullet = Platform.isWindows ? ' - ' : ' • ';
    // RegExp to match an error output line of the analyzer.
    final RegExp errorPattern = RegExp(
      '^ +(?<type>[a-z]+)'
      '$kBullet(?<description>.+)'
      '$kBullet(?<file>.+):(?<line>[0-9]+):(?<column>[0-9]+)'
      '$kBullet(?<code>[-a-z_]+)\$',
      caseSensitive: false,
    );
    bool unknownAnalyzerErrors = false;
    final int headerLength = headers.length + 3;
    for (final String error in errors) {
      final RegExpMatch? match = errorPattern.firstMatch(error);
      if (match == null) {
        stderr.writeln('Analyzer output: $error');
        unknownAnalyzerErrors = true;
        continue;
      }
      final String type = match.namedGroup('type')!;
      final String message = match.namedGroup('description')!;
      final File file = File(path.join(_tempDirectory.path, match.namedGroup('file')));
      final List<String> fileContents = file.readAsLinesSync();
      final String lineString = match.namedGroup('line')!;
      final String columnString = match.namedGroup('column')!;
      final String errorCode = match.namedGroup('code')!;
      final int lineNumber = int.parse(lineString, radix: 10) - headerLength;
      final int columnNumber = int.parse(columnString, radix: 10);

      if (lineNumber < 1 || lineNumber > fileContents.length) {
        addAnalysisError(
          file,
          _AnalysisError(
            type,
            lineNumber,
            columnNumber,
            message,
            errorCode,
            _Line(filename: file.path, line: lineNumber),
          ),
        );
        throw _SnippetCheckerException('Failed to parse error message: $error', file: file.path, line: lineNumber);
      }

      final _Section actualSection = sections[file.path]!;
      if (actualSection == null) {
        throw _SnippetCheckerException(
          "Unknown section for ${file.path}. Maybe the temporary directory wasn't empty?",
          file: file.path,
          line: lineNumber,
        );
      }
      final _Line actualLine = actualSection.code[lineNumber - 1];

      late int line;
      late int column;
      String errorMessage = message;
      _Line source = actualLine;
      if (actualLine.generated) {
        // Since generated lines don't appear in the original, we just provide the line
        // in the generated file.
        line = lineNumber - 1;
        column = columnNumber;
        if (errorCode == 'missing_identifier' && lineNumber > 1) {
          // For a missing identifier on a generated line, it is very often because of a
          // trailing comma on the previous line, and so we want to provide a better message
          // and the previous line as the error location, since that appears in the original
          // source, and can be more easily located.
          final _Line previousCodeLine = sections[file.path]!.code[lineNumber - 2];
          if (previousCodeLine.code.contains(RegExp(r',\s*$'))) {
            line = previousCodeLine.line;
            column = previousCodeLine.indent + previousCodeLine.code.length - 1;
            errorMessage = 'Unexpected comma at end of snippet code.';
            source = previousCodeLine;
          }
        }
      } else {
        line = actualLine.line;
        column = actualLine.indent + columnNumber;
      }
      addAnalysisError(
        file,
        _AnalysisError(
          type,
          line,
          column,
          errorMessage,
          errorCode,
          source,
        ),
      );
    }
    if (exitCode == 1 && analysisErrors.isEmpty && !unknownAnalyzerErrors) {
      exitCode = 0;
    }
    if (exitCode == 0) {
      if (!silent)
        print('No analysis errors in snippets!');
      assert(analysisErrors.isEmpty);
    }
    return _AnalysisResult(exitCode, analysisErrors);
  }

  /// Process one block of snippet code (the part inside of "```" markers).
  /// Splits any sections denoted by "// ..." into separate blocks to be
  /// processed separately. Uses a primitive heuristic to make snippet blocks
  /// into valid Dart code.
  _Section _processBlock(_Line line, List<String> block) {
    if (block.isEmpty) {
      throw _SnippetCheckerException('$line: Empty ```dart block in snippet code.');
    }
    if (block.first.startsWith('new ') || block.first.startsWith(_constructorRegExp)) {
      _expressionId += 1;
      return _Section.surround(line, 'dynamic expression$_expressionId = ', block.toList(), ';');
    } else if (block.first.startsWith('await ')) {
      _expressionId += 1;
      return _Section.surround(line, 'Future<void> expression$_expressionId() async { ', block.toList(), ' }');
    } else if (block.first.startsWith('class ') || block.first.startsWith('enum ')) {
      return _Section.fromStrings(line, block.toList());
    } else if ((block.first.startsWith('_') || block.first.startsWith('final ')) && block.first.contains(' = ')) {
      _expressionId += 1;
      return _Section.surround(line, 'void expression$_expressionId() { ', block.toList(), ' }');
    } else {
      final List<String> buffer = <String>[];
      int subblocks = 0;
      _Line? subline;
      final List<_Section> subsections = <_Section>[];
      for (int index = 0; index < block.length; index += 1) {
        // Each section of the dart code that is either split by a blank line, or with '// ...' is
        // treated as a separate code block.
        if (block[index] == '' || block[index] == '// ...') {
          if (subline == null)
            throw _SnippetCheckerException('${_Line(filename: line.filename, line: line.line + index, indent: line.indent)}: '
                'Unexpected blank line or "// ..." line near start of subblock in snippet code.');
          subblocks += 1;
          subsections.add(_processBlock(subline, buffer));
          buffer.clear();
          assert(buffer.isEmpty);
          subline = null;
        } else if (block[index].startsWith('// ')) {
          if (buffer.length > 1) // don't include leading comments
            buffer.add('/${block[index]}'); // so that it doesn't start with "// " and get caught in this again
        } else {
          subline ??= _Line(
            code: block[index],
            filename: line.filename,
            line: line.line + index,
            indent: line.indent,
          );
          buffer.add(block[index]);
        }
      }
      if (subblocks > 0) {
        if (subline != null) {
          subsections.add(_processBlock(subline, buffer));
        }
        // Combine all of the subsections into one section, now that they've been processed.
        return _Section.combine(subsections);
      } else {
        return _Section.fromStrings(line, block.toList());
      }
    }
  }
}

/// A class to represent a line of input code.
class _Line {
  const _Line({this.code = '', required this.filename, this.line = -1, this.indent = 0})
      : generated = false;
  const _Line.generated({this.code = '', required this.filename, this.line = -1, this.indent = 0})
      : generated = true;

  /// The file that this line came from, or the file that the line was generated for, if [generated] is true.
  final String filename;
  final int line;
  final int indent;
  final String code;
  final bool generated;

  String toStringWithColumn(int column) {
    if (column != null && indent != null) {
      return '$filename:$line:${column + indent}: $code';
    }
    return toString();
  }

  @override
  String toString() => '$filename:$line: $code';
}

/// A class to represent a section of snippet code, marked by "{@tool snippet}...{@end-tool}".
class _Section {
  const _Section(this.code, {this.dartVersionOverride});
  factory _Section.combine(List<_Section> sections) {
    final List<_Line> code = sections
        .expand((_Section section) => section.code)
        .toList();
    return _Section(code);
  }
  factory _Section.fromStrings(_Line firstLine, List<String> code) {
    final List<_Line> codeLines = <_Line>[];
    for (int i = 0; i < code.length; ++i) {
      codeLines.add(
        _Line(
          code: code[i],
          filename: firstLine.filename,
          line: firstLine.line + i,
          indent: firstLine.indent,
        ),
      );
    }
    return _Section(codeLines);
  }
  factory _Section.surround(_Line firstLine, String prefix, List<String> code, String postfix) {
    assert(prefix != null);
    assert(postfix != null);
    final List<_Line> codeLines = <_Line>[];
    for (int i = 0; i < code.length; ++i) {
      codeLines.add(
        _Line(
          code: code[i],
          filename: firstLine.filename,
          line: firstLine.line + i,
          indent: firstLine.indent,
        ),
      );
    }
    return _Section(<_Line>[
      _Line.generated(code: prefix, filename: firstLine.filename, line: 0),
      ...codeLines,
      _Line.generated(code: postfix, filename: firstLine.filename, line: 0),
    ]);
  }
  _Line get start => code.firstWhere((_Line line) => !line.generated);
  final List<_Line> code;
  final String? dartVersionOverride;

  _Section copyWith({String? dartVersionOverride}) {
    return _Section(code, dartVersionOverride: dartVersionOverride ?? this.dartVersionOverride);
  }
}

/// A class representing an analysis error along with the context of the error.
///
/// Changes how it converts to a string based on the source of the error.
class _AnalysisError {
  const _AnalysisError(
    this.type,
    this.line,
    this.column,
    this.message,
    this.errorCode,
    this.source,
  );

  final String type;
  final int line;
  final int column;
  final String message;
  final String errorCode;
  final _Line? source;

  @override
  String toString() {
    if (source != null) {
      return '${source!.toStringWithColumn(column)}\n>>> $type: $message ($errorCode)';
    } else {
      return '<source unknown>:$line:$column\n>>> $type: $message ($errorCode)';
    }
  }
}

Future<void> _runInteractive({
  required Directory? tempDir,
  required Directory flutterPackage,
  required String filePath,
  required Directory? dartUiLocation,
}) async {
  filePath = path.isAbsolute(filePath) ? filePath : path.join(path.current, filePath);
  final File file = File(filePath);
  if (!file.existsSync()) {
    throw 'Path ${file.absolute.path} does not exist ($filePath).';
  }
  if (!path.isWithin(_flutterRoot, file.absolute.path) &&
      (dartUiLocation == null || !path.isWithin(dartUiLocation.path, file.absolute.path))) {
    throw 'Path ${file.absolute.path} is not within the flutter root: '
        '$_flutterRoot${dartUiLocation != null ? ' or the dart:ui location: $dartUiLocation' : ''}';
  }

  if (tempDir == null) {
    tempDir = Directory.systemTemp.createTempSync('flutter_analyze_snippet_code.');
    ProcessSignal.sigint.watch().listen((_) {
      print('Deleting temp files...');
      tempDir!.deleteSync(recursive: true);
      exit(0);
    });
    print('Using temp dir ${tempDir.path}');
  }
  print('Starting up in interactive mode on ${path.relative(filePath, from: _flutterRoot)} ...');

  Future<void> analyze(_SnippetChecker checker, File file) async {
    final Map<String, _Section> sections = <String, _Section>{};
    await checker._extractSnippets(<File>[file], silent: true, sectionMap: sections);
    final _AnalysisResult analysisResult = checker._analyze(checker._tempDirectory, sections, silent: true);
    stderr.writeln('\u001B[2J\u001B[H'); // Clears the old results from the terminal.
    if (analysisResult.errors.isNotEmpty) {
      for (final String filePath in analysisResult.errors.keys) {
        analysisResult.errors[filePath]!.forEach(stderr.writeln);
      }
      stderr.writeln('\nFound ${analysisResult.errors.length} errors.');
    } else {
      stderr.writeln('\nNo issues found.');
    }
  }

  final _SnippetChecker checker = _SnippetChecker(flutterPackage, tempDirectory: tempDir)
    .._createConfigurationFiles(tempDir);
  await analyze(checker, file);

  print('Type "q" to quit, or "r" to delete temp dir and manually reload.');

  void rerun() {
    print('\n\nRerunning...');
    try {
      analyze(checker, file);
    } on _SnippetCheckerException catch (e) {
      print('Caught Exception (${e.runtimeType}), press "r" to retry:\n$e');
    }
  }

  stdin.lineMode = false;
  stdin.echoMode = false;
  stdin.transform(utf8.decoder).listen((String input) {
    switch (input) {
      case 'q':
        print('Exiting...');
        exit(0);
      case 'r':
        print('Deleting temp files...');
        tempDir!.deleteSync(recursive: true);
        rerun();
        break;
    }
  });

  Watcher(file.absolute.path).events.listen((_) => rerun());
}

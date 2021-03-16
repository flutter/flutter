// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See ../snippets/README.md for documentation.

// To run this, from the root of the Flutter repository:
//   bin/cache/dart-sdk/bin/dart dev/bots/analyze_sample_code.dart

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

final String _flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String _defaultFlutterPackage = path.join(_flutterRoot, 'packages', 'flutter', 'lib');
final String _flutter = path.join(_flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');

void main(List<String> arguments) {
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    'temp',
    defaultsTo: null,
    help: 'A location where temporary files may be written. Defaults to a '
          'directory in the system temp folder. If specified, will not be '
          'automatically removed at the end of execution.',
  );
  argParser.addFlag(
    'verbose',
    defaultsTo: false,
    negatable: false,
    help: 'Print verbose output for the analysis process.',
  );
  argParser.addFlag(
    'help',
    defaultsTo: false,
    negatable: false,
    help: 'Print help for this command.',
  );
  argParser.addOption(
    'interactive',
    abbr: 'i',
    help: 'Analyzes the sample code in the specified file interactively.',
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

  Directory tempDirectory;
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
    _runInteractive(tempDirectory, flutterPackage, parsedArguments['interactive'] as String);
  } else {
    try {
      exitCode = SampleChecker(
        flutterPackage,
        tempDirectory: tempDirectory,
        verbose: parsedArguments['verbose'] as bool,
      ).checkSamples();
    } on SampleCheckerException catch (e) {
      stderr.write(e);
      exit(1);
    }
  }
}

class SampleCheckerException implements Exception {
  SampleCheckerException(this.message, {this.file, this.line});
  final String message;
  final String file;
  final int line;

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

/// Checks samples and code snippets for analysis errors.
///
/// Extracts dartdoc content from flutter package source code, identifies code
/// sections, and writes them to a temporary directory, where 'flutter analyze'
/// is used to analyze the sources for problems. If problems are found, the
/// error output from the analyzer is parsed for details, and the problem
/// locations are translated back to the source location.
///
/// For samples, the samples are generated using the snippets tool, and they
/// are analyzed with the snippets. If errors are found in samples, then the
/// line number of the start of the sample is given instead of the actual error
/// line, since samples get reformatted when written, and the line numbers
/// don't necessarily match. It does, however, print the source of the
/// problematic line.
class SampleChecker {
  SampleChecker(this._flutterPackage, {Directory tempDirectory, this.verbose = false})
      : _tempDirectory = tempDirectory,
        _keepTmp = tempDirectory != null {
    _tempDirectory ??= Directory.systemTemp.createTempSync('flutter_analyze_sample_code.');
  }

  /// The prefix of each comment line
  static const String _dartDocPrefix = '///';

  /// The prefix of each comment line with a space appended.
  static const String _dartDocPrefixWithSpace = '$_dartDocPrefix ';

  /// A RegExp that matches the beginning of a dartdoc snippet or sample.
  static final RegExp _dartDocSampleBeginRegex = RegExp(r'{@tool (sample|snippet|dartpad)(?:| ([^}]*))}');

  /// A RegExp that matches the end of a dartdoc snippet or sample.
  static final RegExp _dartDocSampleEndRegex = RegExp(r'{@end-tool}');

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
  Directory _tempDirectory;

  /// The package directory for the flutter package within the flutter root dir.
  final Directory _flutterPackage;

  /// A serial number so that we can create unique expression names when we
  /// generate them.
  int _expressionId = 0;

  /// The exit code from the analysis process.
  int _exitCode = 0;

  // Once the snippets tool has been precompiled by Dart, this contains the AOT
  // snapshot.
  String _snippetsSnapshotPath;

  /// Finds the location of the snippets script.
  String get _snippetsExecutable {
    final String platformScriptPath = path.dirname(path.fromUri(Platform.script));
    return path.canonicalize(path.join(platformScriptPath, '..', 'snippets', 'lib', 'main.dart'));
  }

  /// Finds the location of the Dart executable.
  String get _dartExecutable {
    final File dartExecutable = File(Platform.resolvedExecutable);
    return dartExecutable.absolute.path;
  }

  static List<File> _listDartFiles(Directory directory, {bool recursive = false}) {
    return directory.listSync(recursive: recursive, followLinks: false).whereType<File>().where((File file) => path.extension(file.path) == '.dart').toList();
  }

  /// Computes the headers needed for each sample file.
  List<Line> get headers {
    return _headers ??= <String>[
      '// generated code',
      '// ignore_for_file: unused_import',
      '// ignore_for_file: unused_element',
      '// ignore_for_file: unused_local_variable',
      "import 'dart:async';",
      "import 'dart:convert';",
      "import 'dart:math' as math;",
      "import 'dart:typed_data';",
      "import 'dart:ui' as ui;",
      "import 'package:flutter_test/flutter_test.dart';",
      for (final File file in _listDartFiles(Directory(_defaultFlutterPackage))) ...<String>[
        '',
        '// ${file.path}',
        "import 'package:flutter/${path.basename(file.path)}';",
      ],
    ].map<Line>((String code) => Line(code)).toList();
  }

  List<Line> _headers;

  /// Checks all the samples in the Dart files in [_flutterPackage] for errors.
  int checkSamples() {
    _exitCode = 0;
    Map<String, List<AnalysisError>> errors = <String, List<AnalysisError>>{};
    try {
      final Map<String, Section> sections = <String, Section>{};
      final Map<String, Sample> snippets = <String, Sample>{};
      _extractSamples(_listDartFiles(_flutterPackage, recursive: true), sectionMap: sections, sampleMap: snippets);
      errors = _analyze(_tempDirectory, sections, snippets);
    } finally {
      if (errors.isNotEmpty) {
        for (final String filePath in errors.keys) {
          errors[filePath].forEach(stderr.writeln);
        }
        stderr.writeln('\nFound ${errors.length} sample code errors.');
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
      // If we made a snapshot, remove it (so as not to clutter up the tree).
      if (_snippetsSnapshotPath != null) {
        final File snapshot = File(_snippetsSnapshotPath);
        if (snapshot.existsSync()) {
          snapshot.deleteSync();
        }
      }
    }
    return _exitCode;
  }

  /// Creates a name for the snippets tool to use for the snippet ID from a
  /// filename and starting line number.
  String _createNameFromSource(String prefix, String filename, int start) {
    String sampleId = path.split(filename).join('.');
    sampleId = path.basenameWithoutExtension(sampleId);
    sampleId = '$prefix.$sampleId.$start';
    return sampleId;
  }

  // Precompiles the snippets tool if _snippetsSnapshotPath isn't set yet, and
  // runs the precompiled version if it is set.
  ProcessResult _runSnippetsScript(List<String> args) {
    final String workingDirectory = path.join(_flutterRoot, 'dev', 'docs');
    if (_snippetsSnapshotPath == null) {
      _snippetsSnapshotPath = '$_snippetsExecutable.snapshot';
      return Process.runSync(
        _dartExecutable,
        <String>[
          '--snapshot=$_snippetsSnapshotPath',
          '--snapshot-kind=app-jit',
          path.canonicalize(_snippetsExecutable),
          ...args,
        ],
        workingDirectory: workingDirectory,
      );
    } else {
      return Process.runSync(
        _dartExecutable,
        <String>[path.canonicalize(_snippetsSnapshotPath), ...args],
        workingDirectory: workingDirectory,
      );
    }
  }

  /// Writes out the given sample to an output file in the [_tempDirectory] and
  /// returns the output file.
  File _writeSample(Sample sample) {
    // Generate the snippet.
    final String sampleId = _createNameFromSource('sample', sample.start.filename, sample.start.line);
    final String inputName = '$sampleId.input';
    // Now we have a filename like 'lib.src.material.foo_widget.123.dart' for each snippet.
    final File inputFile = File(path.join(_tempDirectory.path, inputName))..createSync(recursive: true);
    inputFile.writeAsStringSync(sample.input.join('\n'));
    final File outputFile = File(path.join(_tempDirectory.path, '$sampleId.dart'));
    final List<String> args = <String>[
      '--output=${outputFile.absolute.path}',
      '--input=${inputFile.absolute.path}',
      ...sample.args,
    ];
    if (verbose)
      print('Generating sample for ${sample.start?.filename}:${sample.start?.line}');
    final ProcessResult process = _runSnippetsScript(args);
    if (verbose)
      stderr.write('${process.stderr}');
    if (process.exitCode != 0) {
      throw SampleCheckerException(
        'Unable to create sample for ${sample.start.filename}:${sample.start.line} '
            '(using input from ${inputFile.path}):\n${process.stdout}\n${process.stderr}',
        file: sample.start.filename,
        line: sample.start.line,
      );
    }
    return outputFile;
  }

  /// Extracts the samples from the Dart files in [files], writes them
  /// to disk, and adds them to the appropriate [sectionMap] or [sampleMap].
  void _extractSamples(List<File> files, {Map<String, Section> sectionMap, Map<String, Sample> sampleMap, bool silent = false}) {
    final List<Section> sections = <Section>[];
    final List<Sample> samples = <Sample>[];
    int dartpadCount = 0;
    int sampleCount = 0;

    for (final File file in files) {
      final String relativeFilePath = path.relative(file.path, from: _flutterPackage.path);
      final List<String> sampleLines = file.readAsLinesSync();
      final List<Section> preambleSections = <Section>[];
      // Whether or not we're in the file-wide preamble section ("Examples can assume").
      bool inPreamble = false;
      // Whether or not we're in a code sample
      bool inSampleSection = false;
      // Whether or not we're in a snippet code sample (with template) specifically.
      bool inSnippet = false;
      // Whether or not we're in a '```dart' segment.
      bool inDart = false;
      String dartVersionOverride;
      int lineNumber = 0;
      final List<String> block = <String>[];
      List<String> snippetArgs = <String>[];
      Line startLine;
      for (final String line in sampleLines) {
        lineNumber += 1;
        final String trimmedLine = line.trim();
        if (inSnippet) {
          if (!trimmedLine.startsWith(_dartDocPrefix)) {
            throw SampleCheckerException('Snippet section unterminated.', file: relativeFilePath, line: lineNumber);
          }
          if (_dartDocSampleEndRegex.hasMatch(trimmedLine)) {
            samples.add(
              Sample(
                start: startLine,
                input: block,
                args: snippetArgs,
                serial: samples.length,
              ),
            );
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
            // If there's only a dartVersionOverride in the preamble, don't add
            // it as a section. The dartVersionOverride was processed below.
            if (dartVersionOverride == null || block.isNotEmpty) {
              preambleSections.add(_processBlock(startLine, block));
            }
            block.clear();
          } else if (!line.startsWith('// ')) {
            throw SampleCheckerException('Unexpected content in sample code preamble.', file: relativeFilePath, line: lineNumber);
          } else if (_dartVersionRegExp.hasMatch(line)) {
            dartVersionOverride = line.substring(3);
          } else {
            block.add(line.substring(3));
          }
        } else if (inSampleSection) {
          if (_dartDocSampleEndRegex.hasMatch(trimmedLine)) {
            if (inDart) {
              throw SampleCheckerException("Dart section didn't terminate before end of sample", file: relativeFilePath, line: lineNumber);
            }
            inSampleSection = false;
          }
          if (inDart) {
            if (_codeBlockEndRegex.hasMatch(trimmedLine)) {
              inDart = false;
              final Section processed = _processBlock(startLine, block);
              final Section combinedSection = preambleSections.isEmpty ? processed : Section.combine(preambleSections..add(processed));
              sections.add(combinedSection.copyWith(dartVersionOverride: dartVersionOverride));
              block.clear();
            } else if (trimmedLine == _dartDocPrefix) {
              block.add('');
            } else {
              final int index = line.indexOf(_dartDocPrefixWithSpace);
              if (index < 0) {
                throw SampleCheckerException(
                  'Dart section inexplicably did not contain "$_dartDocPrefixWithSpace" prefix.',
                  file: relativeFilePath,
                  line: lineNumber,
                );
              }
              block.add(line.substring(index + 4));
            }
          } else if (_codeBlockStartRegex.hasMatch(trimmedLine)) {
            assert(block.isEmpty);
            startLine = Line(
              '',
              filename: relativeFilePath,
              line: lineNumber + 1,
              indent: line.indexOf(_dartDocPrefixWithSpace) + _dartDocPrefixWithSpace.length,
            );
            inDart = true;
          }
        }
        if (!inSampleSection) {
          final Match sampleMatch = _dartDocSampleBeginRegex.firstMatch(trimmedLine);
          if (line == '// Examples can assume:') {
            assert(block.isEmpty);
            startLine = Line('', filename: relativeFilePath, line: lineNumber + 1, indent: 3);
            inPreamble = true;
          } else if (sampleMatch != null) {
            inSnippet = sampleMatch != null && (sampleMatch[1] == 'sample' || sampleMatch[1] == 'dartpad');
            if (inSnippet) {
              if (sampleMatch[1] == 'sample') {
                sampleCount++;
              }
              if (sampleMatch[1] == 'dartpad') {
                dartpadCount++;
              }
              startLine = Line(
                '',
                filename: relativeFilePath,
                line: lineNumber + 1,
                indent: line.indexOf(_dartDocPrefixWithSpace) + _dartDocPrefixWithSpace.length,
              );
              if (sampleMatch[2] != null) {
                // There are arguments to the snippet tool to keep track of.
                snippetArgs = _splitUpQuotedArgs(sampleMatch[2]).toList();
              } else {
                snippetArgs = <String>[];
              }
            }
            inSampleSection = !inSnippet;
          } else if (RegExp(r'///\s*#+\s+[Ss]ample\s+[Cc]ode:?$').hasMatch(trimmedLine)) {
            throw SampleCheckerException(
              "Found deprecated '## Sample code' section: use {@tool snippet}...{@end-tool} instead.",
              file: relativeFilePath,
              line: lineNumber,
            );
          }
        }
      }
    }
    if (!silent)
      print('Found ${sections.length} snippet code blocks, $sampleCount sample code sections, and $dartpadCount dartpad sections.');
    for (final Section section in sections) {
      final String path = _writeSection(section).path;
      if (sectionMap != null)
        sectionMap[path] = section;
    }
    for (final Sample sample in samples) {
      final File snippetFile = _writeSample(sample);
      if (sampleMap != null) {
        sample.contents = snippetFile.readAsLinesSync();
        sampleMap[snippetFile.absolute.path] = sample;
      }
    }
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

  /// Creates the configuration files necessary for the analyzer to consider
  /// the temporary directory a package, and sets which lint rules to enforce.
  void _createConfigurationFiles(Directory directory) {
    final File pubSpec = File(path.join(directory.path, 'pubspec.yaml'))..createSync(recursive: true);

    pubSpec.writeAsStringSync('''
name: analyze_sample_code
environment:
  sdk: ">=2.12.0-0 <3.0.0"
dependencies:
  flutter:
    sdk: flutter
  flutter_test:
    sdk: flutter
''');

    // Copy in the analysis options from the Flutter root.
    File(path.join(_flutterRoot,'analysis_options.yaml')).copySync(path.join(directory.path, 'analysis_options.yaml'));
  }

  /// Writes out a sample section to the disk and returns the file.
  File _writeSection(Section section) {
    final String sectionId = _createNameFromSource('snippet', section.start.filename, section.start.line);
    final File outputFile = File(path.join(_tempDirectory.path, '$sectionId.dart'))..createSync(recursive: true);
    final List<Line> mainContents = <Line>[
      if (section.dartVersionOverride != null) Line(section.dartVersionOverride) else const Line(''),
      ...headers,
      const Line(''),
      Line('// From: ${section.start.filename}:${section.start.line}'),
      ...section.code,
    ];
    outputFile.writeAsStringSync(mainContents.map<String>((Line line) => line.code).join('\n'));
    return outputFile;
  }

  /// Invokes the analyzer on the given [directory] and returns the stdout.
  List<String> _runAnalyzer(Directory directory, {bool silent}) {
    if (!silent)
      print('Starting analysis of code samples.');
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
      return line.startsWith('Building flutter tool...');
    });
    // Check out the stderr to see if the analyzer had it's own issues.
    if (stderr.isNotEmpty && (stderr.first.contains(' issues found. (ran in ') || stderr.first.contains(' issue found. (ran in '))) {
      // The "23 issues found" message goes onto stderr, which is concatenated first.
      stderr.removeAt(0);
      // If there's an "issues found" message, we put a blank line on stdout before it.
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
    _exitCode = result.exitCode;
    return stdout;
  }

  /// Starts the analysis phase of checking the samples by invoking the analyzer
  /// and parsing its output to create a map of filename to [AnalysisError]s.
  Map<String, List<AnalysisError>> _analyze(
    Directory directory,
    Map<String, Section> sections,
    Map<String, Sample> samples, {
    bool silent = false,
  }) {
    final List<String> errors = _runAnalyzer(directory, silent: silent);
    final Map<String, List<AnalysisError>> analysisErrors = <String, List<AnalysisError>>{};
    void addAnalysisError(File file, AnalysisError error) {
      if (analysisErrors.containsKey(file.path)) {
        analysisErrors[file.path].add(error);
      } else {
        analysisErrors[file.path] = <AnalysisError>[error];
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
      final RegExpMatch match = errorPattern.firstMatch(error);
      if (match == null) {
        stderr.writeln('Analyzer output: $error');
        unknownAnalyzerErrors = true;
        continue;
      }
      final String type = match.namedGroup('type');
      final String message = match.namedGroup('description');
      final File file = File(path.join(_tempDirectory.path, match.namedGroup('file')));
      final List<String> fileContents = file.readAsLinesSync();
      final bool isSnippet = path.basename(file.path).startsWith('snippet.');
      final bool isSample = path.basename(file.path).startsWith('sample.');
      final String line = match.namedGroup('line');
      final String column = match.namedGroup('column');
      final String errorCode = match.namedGroup('code');
      final int lineNumber = int.parse(line, radix: 10) - (isSnippet ? headerLength : 0);
      final int columnNumber = int.parse(column, radix: 10);

      // For when errors occur outside of the things we're trying to analyze.
      if (!isSnippet && !isSample) {
        addAnalysisError(
          file,
          AnalysisError(
            type,
            lineNumber,
            columnNumber,
            message,
            errorCode,
            Line(
              '',
              filename: file.path,
              line: lineNumber,
            ),
          ),
        );
        throw SampleCheckerException(
          'Cannot analyze dartdocs; analysis errors exist: $error',
          file: file.path,
          line: lineNumber,
        );
      }

      if (isSample) {
        addAnalysisError(
          file,
          AnalysisError(
            type,
            lineNumber,
            columnNumber,
            message,
            errorCode,
            null,
            sample: samples[file.path],
          ),
        );
      } else {
        if (lineNumber < 1 || lineNumber > fileContents.length) {
          addAnalysisError(
            file,
            AnalysisError(
              type,
              lineNumber,
              columnNumber,
              message,
              errorCode,
              Line('', filename: file.path, line: lineNumber),
            ),
          );
          throw SampleCheckerException('Failed to parse error message: $error', file: file.path, line: lineNumber);
        }

        final Section actualSection = sections[file.path];
        if (actualSection == null) {
          throw SampleCheckerException(
            "Unknown section for ${file.path}. Maybe the temporary directory wasn't empty?",
            file: file.path,
            line: lineNumber,
          );
        }
        final Line actualLine = actualSection.code[lineNumber - 1];

        if (actualLine?.filename == null) {
          if (errorCode == 'missing_identifier' && lineNumber > 1) {
            if (fileContents[lineNumber - 2].endsWith(',')) {
              final Line actualLine = sections[file.path].code[lineNumber - 2];
              addAnalysisError(
                file,
                AnalysisError(
                  type,
                  actualLine.line,
                  actualLine.indent + fileContents[lineNumber - 2].length - 1,
                  'Unexpected comma at end of sample code.',
                  errorCode,
                  actualLine,
                ),
              );
            }
          } else {
            addAnalysisError(
              file,
              AnalysisError(
                type,
                lineNumber - 1,
                columnNumber,
                message,
                errorCode,
                actualLine,
              ),
            );
          }
        } else {
          addAnalysisError(
            file,
            AnalysisError(
              type,
              actualLine.line,
              actualLine.indent + columnNumber,
              message,
              errorCode,
              actualLine,
            ),
          );
        }
      }
    }
    if (_exitCode == 1 && analysisErrors.isEmpty && !unknownAnalyzerErrors) {
      _exitCode = 0;
    }
    if (_exitCode == 0) {
      if (!silent)
        print('No analysis errors in samples!');
      assert(analysisErrors.isEmpty);
    }
    return analysisErrors;
  }

  /// Process one block of sample code (the part inside of "```" markers).
  /// Splits any sections denoted by "// ..." into separate blocks to be
  /// processed separately. Uses a primitive heuristic to make sample blocks
  /// into valid Dart code.
  Section _processBlock(Line line, List<String> block) {
    if (block.isEmpty) {
      throw SampleCheckerException('$line: Empty ```dart block in sample code.');
    }
    if (block.first.startsWith('new ') || block.first.startsWith(_constructorRegExp)) {
      _expressionId += 1;
      return Section.surround(line, 'dynamic expression$_expressionId = ', block.toList(), ';');
    } else if (block.first.startsWith('await ')) {
      _expressionId += 1;
      return Section.surround(line, 'Future<void> expression$_expressionId() async { ', block.toList(), ' }');
    } else if (block.first.startsWith('class ') || block.first.startsWith('enum ')) {
      return Section.fromStrings(line, block.toList());
    } else if ((block.first.startsWith('_') || block.first.startsWith('final ')) && block.first.contains(' = ')) {
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
            throw SampleCheckerException('${Line('', filename: line.filename, line: line.line + index, indent: line.indent)}: '
                'Unexpected blank line or "// ..." line near start of subblock in sample code.');
          subblocks += 1;
          subsections.add(_processBlock(subline, buffer));
          buffer.clear();
          assert(buffer.isEmpty);
          subline = null;
        } else if (block[index].startsWith('// ')) {
          if (buffer.length > 1) // don't include leading comments
            buffer.add('/${block[index]}'); // so that it doesn't start with "// " and get caught in this again
        } else {
          subline ??= Line(
            block[index],
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
        return Section.combine(subsections);
      } else {
        return Section.fromStrings(line, block.toList());
      }
    }
  }
}

/// A class to represent a line of input code.
class Line {
  const Line(this.code, {this.filename, this.line, this.indent});
  final String filename;
  final int line;
  final int indent;
  final String code;

  String toStringWithColumn(int column) {
    if (column != null && indent != null) {
      return '$filename:$line:${column + indent}: $code';
    }
    return toString();
  }

  @override
  String toString() => '$filename:$line: $code';
}

/// A class to represent a section of sample code, marked by "{@tool snippet}...{@end-tool}".
class Section {
  const Section(this.code, {this.dartVersionOverride});
  factory Section.combine(List<Section> sections) {
    final List<Line> code = sections
      .expand((Section section) => section.code)
      .toList();
    return Section(code);
  }
  factory Section.fromStrings(Line firstLine, List<String> code) {
    final List<Line> codeLines = <Line>[];
    for (int i = 0; i < code.length; ++i) {
      codeLines.add(
        Line(
          code[i],
          filename: firstLine.filename,
          line: firstLine.line + i,
          indent: firstLine.indent,
        ),
      );
    }
    return Section(codeLines);
  }
  factory Section.surround(Line firstLine, String prefix, List<String> code, String postfix) {
    assert(prefix != null);
    assert(postfix != null);
    final List<Line> codeLines = <Line>[];
    for (int i = 0; i < code.length; ++i) {
      codeLines.add(
        Line(
          code[i],
          filename: firstLine.filename,
          line: firstLine.line + i,
          indent: firstLine.indent,
        ),
      );
    }
    return Section(<Line>[
      Line(prefix),
      ...codeLines,
      Line(postfix),
    ]);
  }
  Line get start => code.firstWhere((Line line) => line.filename != null);
  final List<Line> code;
  final String dartVersionOverride;

  Section copyWith({String dartVersionOverride}) {
    return Section(code, dartVersionOverride: dartVersionOverride);
  }
}

/// A class to represent a sample in the dartdoc comments, marked by
/// "{@tool sample ...}...{@end-tool}". Samples are processed separately from
/// regular snippets, because they must be injected into templates in order to be
/// analyzed.
class Sample {
  Sample({this.start, List<String> input, List<String> args, this.serial}) {
    this.input = input.toList();
    this.args = args.toList();
  }
  final Line start;
  final int serial;
  List<String> input;
  List<String> args;
  List<String> contents;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer('sample ${args.join(' ')}\n');
    int count = start.line;
    for (final String line in input) {
      buf.writeln(' ${count.toString().padLeft(4, ' ')}: $line');
      count++;
    }
    return buf.toString();
  }
}

/// A class representing an analysis error along with the context of the error.
///
/// Changes how it converts to a string based on the source of the error.
class AnalysisError {
  const AnalysisError(
    this.type,
    this.line,
    this.column,
    this.message,
    this.errorCode,
    this.source, {
    this.sample,
  });

  final String type;
  final int line;
  final int column;
  final String message;
  final String errorCode;
  final Line source;
  final Sample sample;

  @override
  String toString() {
    if (source != null) {
      return '${source.toStringWithColumn(column)}\n>>> $type: $message ($errorCode)';
    } else if (sample != null) {
      return 'In sample starting at '
          '${sample.start.filename}:${sample.start.line}:${sample.contents[line - 1]}\n'
          '>>> $type: $message ($errorCode)';
    } else {
      return '<source unknown>:$line:$column\n>>> $type: $message ($errorCode)';
    }
  }
}

Future<void> _runInteractive(Directory tempDir, Directory flutterPackage, String filePath) async {
  filePath = path.isAbsolute(filePath) ? filePath : path.join(path.current, filePath);
  final File file = File(filePath);
  if (!file.existsSync()) {
    throw 'Path ${file.absolute.path} does not exist.';
  }
  if (!path.isWithin(_flutterRoot, file.absolute.path)) {
    throw 'Path ${file.absolute.path} is not within the flutter root: $_flutterRoot';
  }

  if (tempDir == null) {
    tempDir = Directory.systemTemp.createTempSync('flutter_analyze_sample_code.');
    ProcessSignal.sigint.watch().listen((_) {
      print('Deleting temp files...');
      tempDir.deleteSync(recursive: true);
      exit(0);
    });
    print('Using temp dir ${tempDir.path}');
  }
  print('Starting up in interactive mode on ${path.relative(filePath, from: _flutterRoot)} ...');

  void analyze(SampleChecker checker, File file) {
    final Map<String, Section> sections = <String, Section>{};
    final Map<String, Sample> snippets = <String, Sample>{};
    checker._extractSamples(<File>[file], silent: true, sectionMap: sections, sampleMap: snippets);
    final Map<String, List<AnalysisError>> errors = checker._analyze(checker._tempDirectory, sections, snippets, silent: true);
    stderr.writeln('\u001B[2J\u001B[H'); // Clears the old results from the terminal.
    if (errors.isNotEmpty) {
      for (final String filePath in errors.keys) {
        errors[filePath].forEach(stderr.writeln);
      }
      stderr.writeln('\nFound ${errors.length} errors.');
    } else {
      stderr.writeln('\nNo issues found.');
    }
  }

  final SampleChecker checker = SampleChecker(flutterPackage, tempDirectory: tempDir)
    .._createConfigurationFiles(tempDir);
  analyze(checker, file);

  print('Type "q" to quit, or "r" to delete temp dir and manually reload.');

  void rerun() {
    print('\n\nRerunning...');
    try {
      analyze(checker, file);
    } on SampleCheckerException catch (e) {
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
        break;
      case 'r':
        print('Deleting temp files...');
        tempDir.deleteSync(recursive: true);
        rerun();
        break;
    }
  });

  Watcher(file.absolute.path).events.listen((_) => rerun());
}

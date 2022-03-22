// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See ../snippets/README.md for documentation.

// To run this, from the root of the Flutter repository:
//   bin/cache/dart-sdk/bin/dart dev/bots/analyze_sample_code.dart

// @dart= 2.14

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

// If you update this version, also update it in dev/bots/docs.sh
const String _snippetsActivateVersion = '0.2.5';

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
    help: 'Analyzes the sample code in the specified file interactively.',
  );
  argParser.addFlag(
    'global-activate-snippets',
    defaultsTo: true,
    help: 'Whether or not to "pub global activate" the snippets package. If set, will '
          'activate version $_snippetsActivateVersion',
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

  if (parsedArguments['global-activate-snippets']! as bool) {
    try {
      final ProcessResult activateResult = Process.runSync(
        Platform.resolvedExecutable,
        <String>[
          'pub',
          'global',
          'activate',
          'snippets',
          _snippetsActivateVersion,
        ],
        workingDirectory: _flutterRoot,
      );
      if (activateResult.exitCode != 0) {
        exit(activateResult.exitCode);
      }
    } on ProcessException catch (e) {
      stderr.writeln('Unable to global activate snippets package at version $_snippetsActivateVersion: $e');
      exit(1);
    }
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
      exitCode = await SampleChecker(
        flutterPackage,
        tempDirectory: tempDirectory,
        verbose: parsedArguments['verbose'] as bool,
        dartUiLocation: includeDartUi ? dartUiLocation : null,
      ).checkSamples();
    } on SampleCheckerException catch (e) {
      stderr.write(e);
      exit(1);
    }
  }
}

typedef TaskQueueClosure<T> = Future<T> Function();

class _TaskQueueItem<T> {
  _TaskQueueItem(this._closure, this._completer, {this.onComplete});

  final TaskQueueClosure<T> _closure;
  final Completer<T> _completer;
  void Function()? onComplete;

  Future<void> run() async {
    try {
      _completer.complete(await _closure());
    } catch (e, st) {
      _completer.completeError(e, st);
    } finally {
      onComplete?.call();
    }
  }
}

/// A task queue of Futures to be completed in parallel, throttling
/// the number of simultaneous tasks.
///
/// The tasks return results of type T.
class TaskQueue<T> {
  /// Creates a task queue with a maximum number of simultaneous jobs.
  /// The [maxJobs] parameter defaults to the number of CPU cores on the
  /// system.
  TaskQueue({int? maxJobs})
      : maxJobs = maxJobs ?? Platform.numberOfProcessors;

  /// The maximum number of jobs that this queue will run simultaneously.
  final int maxJobs;

  final Queue<_TaskQueueItem<T>> _pendingTasks = Queue<_TaskQueueItem<T>>();
  final Set<_TaskQueueItem<T>> _activeTasks = <_TaskQueueItem<T>>{};
  final Set<Completer<void>> _completeListeners = <Completer<void>>{};

  /// Returns a future that completes when all tasks in the [TaskQueue] are
  /// complete.
  Future<void> get tasksComplete {
    // In case this is called when there are no tasks, we want it to
    // signal complete immediately.
    if (_activeTasks.isEmpty && _pendingTasks.isEmpty) {
      return Future<void>.value();
    }
    final Completer<void> completer = Completer<void>();
    _completeListeners.add(completer);
    return completer.future;
  }

  /// Adds a single closure to the task queue, returning a future that
  /// completes when the task completes.
  Future<T> add(TaskQueueClosure<T> task) {
    final Completer<T> completer = Completer<T>();
    _pendingTasks.add(_TaskQueueItem<T>(task, completer));
    if (_activeTasks.length < maxJobs) {
      _processTask();
    }
    return completer.future;
  }

  // Process a single task.
  void _processTask() {
    if (_pendingTasks.isNotEmpty && _activeTasks.length <= maxJobs) {
      final _TaskQueueItem<T> item = _pendingTasks.removeFirst();
      _activeTasks.add(item);
      item.onComplete = () {
        _activeTasks.remove(item);
        _processTask();
      };
      item.run();
    } else {
      _checkForCompletion();
    }
  }

  void _checkForCompletion() {
    if (_activeTasks.isEmpty && _pendingTasks.isEmpty) {
      for (final Completer<void> completer in _completeListeners) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      _completeListeners.clear();
    }
  }
}

class SampleCheckerException implements Exception {
  SampleCheckerException(this.message, {this.file, this.line});
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

class AnalysisResult {
  const AnalysisResult(this.exitCode, this.errors);
  final int exitCode;
  final Map<String, List<AnalysisError>> errors;
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
  /// Creates a [SampleChecker].
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
  SampleChecker(
    this._flutterPackage, {
    Directory? tempDirectory,
    this.verbose = false,
    Directory? dartUiLocation,
  }) : _tempDirectory = tempDirectory ?? Directory.systemTemp.createTempSync('flutter_analyze_sample_code.'),
       _keepTmp = tempDirectory != null,
       _dartUiLocation = dartUiLocation;

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

  /// Computes the headers needed for each sample file.
  List<Line> get headers {
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
    ].map<Line>((String code) => Line.generated(code: code, filename: 'headers')).toList();
  }

  List<Line>? _headers;

  /// Checks all the samples in the Dart files in [_flutterPackage] for errors.
  Future<int> checkSamples() async {
    AnalysisResult? analysisResult;
    try {
      final Map<String, Section> sections = <String, Section>{};
      final Map<String, Sample> snippets = <String, Sample>{};
      if (_dartUiLocation != null && !_dartUiLocation!.existsSync()) {
        stderr.writeln('Unable to analyze engine dart samples at ${_dartUiLocation!.path}.');
      }
      final List<File> filesToAnalyze = <File>[
        ..._listDartFiles(_flutterPackage, recursive: true),
        if (_dartUiLocation != null && _dartUiLocation!.existsSync()) ... _listDartFiles(_dartUiLocation!, recursive: true),
      ];
      await _extractSamples(filesToAnalyze, sectionMap: sections, sampleMap: snippets);
      analysisResult = _analyze(_tempDirectory, sections, snippets);
    } finally {
      if (analysisResult != null && analysisResult.errors.isNotEmpty) {
        for (final String filePath in analysisResult.errors.keys) {
          analysisResult.errors[filePath]!.forEach(stderr.writeln);
        }
        stderr.writeln('\nFound ${analysisResult.errors.length} sample code errors.');
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
    String sampleId = path.split(filename).join('.');
    sampleId = path.basenameWithoutExtension(sampleId);
    sampleId = '$prefix.$sampleId.$start';
    return sampleId;
  }

  // The cached JSON Flutter version information from 'flutter --version --machine'.
  String? _flutterVersion;

  Future<Process> _runSnippetsScript(List<String> args) async {
    final String workingDirectory = path.join(_flutterRoot, 'dev', 'docs');
    if (_flutterVersion == null) {
      // Capture the flutter version information once so that the snippets tool doesn't
      // have to run it for every snippet.
      if (verbose) {
        print(<String>[_flutter, '--version', '--machine'].join(' '));
      }
      final ProcessResult versionResult = Process.runSync(_flutter, <String>['--version', '--machine']);
      if (verbose) {
        stdout.write(versionResult.stdout);
        stderr.write(versionResult.stderr);
      }
      _flutterVersion = versionResult.stdout as String? ?? '';
    }
    if (verbose) {
      print(<String>[
        Platform.resolvedExecutable,
        'pub',
        'global',
        'run',
        'snippets',
        ...args,
      ].join(' '));
    }
    return Process.start(
      Platform.resolvedExecutable,
      <String>[
        'pub',
        'global',
        'run',
        'snippets',
        ...args,
      ],
      workingDirectory: workingDirectory,
      environment: <String, String>{
        if (!Platform.environment.containsKey('FLUTTER_ROOT')) 'FLUTTER_ROOT': _flutterRoot,
        if (_flutterVersion!.isNotEmpty) 'FLUTTER_VERSION': _flutterVersion!,
      },
    );
  }

  /// Writes out the given sample to an output file in the [_tempDirectory] and
  /// returns the output file.
  Future<File> _writeSample(Sample sample) async {
    // Generate the snippet.
    final String sampleId = _createNameFromSource('sample', sample.start.filename, sample.start.line);
    final String inputName = '$sampleId.input';
    // Now we have a filename like 'lib.src.material.foo_widget.123.dart' for each snippet.
    final String inputFilePath = path.join(_tempDirectory.path, inputName);
    if (verbose) {
      stdout.writeln('Creating $inputFilePath.');
    }
    final File inputFile = File(inputFilePath)..createSync(recursive: true);
    if (verbose) {
      stdout.writeln('Writing $inputFilePath.');
    }
    inputFile.writeAsStringSync(sample.input.join('\n'));
    final File outputFile = File(path.join(_tempDirectory.path, '$sampleId.dart'));
    final List<String> args = <String>[
      '--output=${outputFile.absolute.path}',
      '--input=${inputFile.absolute.path}',
      // Formatting the output will fail on analysis errors, and we want it to fail
      // here, not there.
      '--no-format-output',
      ...sample.args,
    ];
    if (verbose) {
      print('Generating sample for ${sample.start.filename}:${sample.start.line}');
    }
    final Process process = await _runSnippetsScript(args);
    if (verbose) {
      process.stdout.transform(utf8.decoder).forEach(stdout.write);
    }
    process.stderr.transform(utf8.decoder).forEach(stderr.write);
    const Duration timeoutDuration = Duration(minutes: 5);
    final int exitCode = await process.exitCode.timeout(timeoutDuration, onTimeout: () {
      stderr.writeln('Snippet script timed out after $timeoutDuration.');
      return -1;
    });
    if (exitCode != 0) {
      throw SampleCheckerException(
        'Unable to create sample for ${sample.start.filename}:${sample.start.line} '
        '(using input from ${inputFile.path}).',
        file: sample.start.filename,
        line: sample.start.line,
      );
    }
    return outputFile;
  }

  /// Extracts the samples from the Dart files in [files], writes them
  /// to disk, and adds them to the appropriate [sectionMap] or [sampleMap].
  Future<void> _extractSamples(
    List<File> files, {
    required Map<String, Section> sectionMap,
    required Map<String, Sample> sampleMap,
    bool silent = false,
  }) async {
    final List<Section> sections = <Section>[];
    final List<Sample> samples = <Sample>[];
    int dartpadCount = 0;
    int sampleCount = 0;

    for (final File file in files) {
      final String relativeFilePath = path.relative(file.path, from: _flutterRoot);
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
      String? dartVersionOverride;
      int lineNumber = 0;
      final List<String> block = <String>[];
      List<String> snippetArgs = <String>[];
      late Line startLine;
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
              filename: relativeFilePath,
              line: lineNumber + 1,
              indent: line.indexOf(_dartDocPrefixWithSpace) + _dartDocPrefixWithSpace.length,
            );
            inDart = true;
          }
        }
        if (!inSampleSection) {
          final RegExpMatch? sampleMatch = _dartDocSampleBeginRegex.firstMatch(trimmedLine);
          if (line == '// Examples can assume:') {
            assert(block.isEmpty);
            startLine = Line.generated(filename: relativeFilePath, line: lineNumber + 1, indent: 3);
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
                filename: relativeFilePath,
                line: lineNumber + 1,
                indent: line.indexOf(_dartDocPrefixWithSpace) + _dartDocPrefixWithSpace.length,
              );
              if (sampleMatch[2] != null) {
                // There are arguments to the snippet tool to keep track of.
                snippetArgs = _splitUpQuotedArgs(sampleMatch[2]!).toList();
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
      print('Found ${sections.length} snippet code blocks, '
          '$sampleCount sample code sections, and '
          '$dartpadCount dartpad sections.');
    for (final Section section in sections) {
      final String path = _writeSection(section).path;
      if (sectionMap != null)
        sectionMap[path] = section;
    }
    final TaskQueue<File> sampleQueue = TaskQueue<File>();
    for (final Sample sample in samples) {
      final Future<File> futureFile = sampleQueue.add(() => _writeSample(sample));
      if (sampleMap != null) {
        sampleQueue.add(() async {
          final File snippetFile = await futureFile;
          sample.contents = await snippetFile.readAsLines();
          sampleMap[snippetFile.absolute.path] = sample;
          return futureFile;
        });
      }
    }
    await sampleQueue.tasksComplete;
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
      if (match[1] != null && !match[1]!.startsWith('-')) {
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
    final File pubSpec = File(path.join(directory.path, 'pubspec.yaml'));
    if (!pubSpec.existsSync()) {
      pubSpec.createSync(recursive: true);

      pubSpec.writeAsStringSync('''
name: analyze_sample_code
environment:
  sdk: ">=2.12.0-0 <3.0.0"
dependencies:
  flutter:
    sdk: flutter
  flutter_test:
    sdk: flutter
  vector_math: any

dev_dependencies:
  flutter_lints: ^2.0.0
''');
    }

    // Import the analysis options from the Flutter root.
    final File analysisOptions = File(path.join(directory.path, 'analysis_options.yaml'));
    if (!analysisOptions.existsSync()) {
      analysisOptions.createSync(recursive: true);
      analysisOptions.writeAsStringSync('''
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Samples want to print things pretty often.
    avoid_print: false

analyzer:
  errors:
    # TODO(https://github.com/flutter/flutter/issues/74381):
    # Clean up existing unnecessary imports, and remove line to ignore.
    unnecessary_import: ignore
''');
    }
  }

  /// Writes out a sample section to the disk and returns the file.
  File _writeSection(Section section) {
    final String sectionId = _createNameFromSource('snippet', section.start.filename, section.start.line);
    final File outputFile = File(path.join(_tempDirectory.path, '$sectionId.dart'))..createSync(recursive: true);
    final List<Line> mainContents = <Line>[
      Line.generated(code: section.dartVersionOverride ?? '', filename: section.start.filename),
      ...headers,
      Line.generated(filename: section.start.filename),
      Line.generated(code: '// From: ${section.start.filename}:${section.start.line}', filename: section.start.filename),
      ...section.code,
    ];
    outputFile.writeAsStringSync(mainContents.map<String>((Line line) => line.code).join('\n'));
    return outputFile;
  }

  /// Invokes the analyzer on the given [directory] and returns the stdout.
  int _runAnalyzer(Directory directory, {bool silent = true, required List<String> output}) {
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
      return line.startsWith('Building flutter tool...')
          || line.startsWith('Waiting for another flutter command to release the startup lock...');
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

  /// Starts the analysis phase of checking the samples by invoking the analyzer
  /// and parsing its output to create a map of filename to [AnalysisError]s.
  AnalysisResult _analyze(
    Directory directory,
    Map<String, Section> sections,
    Map<String, Sample> samples, {
    bool silent = false,
  }) {
    final List<String> errors = <String>[];
    int exitCode = _runAnalyzer(directory, silent: silent, output: errors);

    final Map<String, List<AnalysisError>> analysisErrors = <String, List<AnalysisError>>{};
    void addAnalysisError(File file, AnalysisError error) {
      if (analysisErrors.containsKey(file.path)) {
        analysisErrors[file.path]!.add(error);
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
      final bool isSnippet = path.basename(file.path).startsWith('snippet.');
      final bool isSample = path.basename(file.path).startsWith('sample.');
      final String line = match.namedGroup('line')!;
      final String column = match.namedGroup('column')!;
      final String errorCode = match.namedGroup('code')!;
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
              Line(filename: file.path, line: lineNumber),
            ),
          );
          throw SampleCheckerException('Failed to parse error message: $error', file: file.path, line: lineNumber);
        }

        final Section actualSection = sections[file.path]!;
        if (actualSection == null) {
          throw SampleCheckerException(
            "Unknown section for ${file.path}. Maybe the temporary directory wasn't empty?",
            file: file.path,
            line: lineNumber,
          );
        }
        final Line actualLine = actualSection.code[lineNumber - 1];

        late int line;
        late int column;
        String errorMessage = message;
        Line source = actualLine;
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
            final Line previousCodeLine = sections[file.path]!.code[lineNumber - 2];
            if (previousCodeLine.code.contains(RegExp(r',\s*$'))) {
              line = previousCodeLine.line;
              column = previousCodeLine.indent + previousCodeLine.code.length - 1;
              errorMessage = 'Unexpected comma at end of sample code.';
              source = previousCodeLine;
            }
          }
        } else {
          line = actualLine.line;
          column = actualLine.indent + columnNumber;
        }
        addAnalysisError(
          file,
          AnalysisError(
            type,
            line,
            column,
            errorMessage,
            errorCode,
            source,
          ),
        );
      }
    }
    if (exitCode == 1 && analysisErrors.isEmpty && !unknownAnalyzerErrors) {
      exitCode = 0;
    }
    if (exitCode == 0) {
      if (!silent)
        print('No analysis errors in samples!');
      assert(analysisErrors.isEmpty);
    }
    return AnalysisResult(exitCode, analysisErrors);
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
      Line? subline;
      final List<Section> subsections = <Section>[];
      for (int index = 0; index < block.length; index += 1) {
        // Each section of the dart code that is either split by a blank line, or with '// ...' is
        // treated as a separate code block.
        if (block[index] == '' || block[index] == '// ...') {
          if (subline == null)
            throw SampleCheckerException('${Line(filename: line.filename, line: line.line + index, indent: line.indent)}: '
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
        return Section.combine(subsections);
      } else {
        return Section.fromStrings(line, block.toList());
      }
    }
  }
}

/// A class to represent a line of input code.
class Line {
  const Line({this.code = '', required this.filename, this.line = -1, this.indent = 0})
      : generated = false;
  const Line.generated({this.code = '', required this.filename, this.line = -1, this.indent = 0})
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
          code: code[i],
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
          code: code[i],
          filename: firstLine.filename,
          line: firstLine.line + i,
          indent: firstLine.indent,
        ),
      );
    }
    return Section(<Line>[
      Line.generated(code: prefix, filename: firstLine.filename, line: 0),
      ...codeLines,
      Line.generated(code: postfix, filename: firstLine.filename, line: 0),
    ]);
  }
  Line get start => code.firstWhere((Line line) => !line.generated);
  final List<Line> code;
  final String? dartVersionOverride;

  Section copyWith({String? dartVersionOverride}) {
    return Section(code, dartVersionOverride: dartVersionOverride ?? this.dartVersionOverride);
  }
}

/// A class to represent a sample in the dartdoc comments, marked by
/// "{@tool sample ...}...{@end-tool}". Samples are processed separately from
/// regular snippets, because they must be injected into templates in order to be
/// analyzed.
class Sample {
  Sample({
    required this.start,
    required List<String> input,
    required List<String> args,
    required this.serial,
  })  : input = input.toList(),
        args = args.toList(),
        contents = <String>[];
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
      buf.writeln(' ${count.toString().padLeft(4)}: $line');
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
  final Line? source;
  final Sample? sample;

  @override
  String toString() {
    if (source != null) {
      return '${source!.toStringWithColumn(column)}\n>>> $type: $message ($errorCode)';
    } else if (sample != null) {
      return 'In sample starting at '
          '${sample!.start.filename}:${sample!.start.line}:${sample!.contents[line - 1]}\n'
          '>>> $type: $message ($errorCode)';
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
    tempDir = Directory.systemTemp.createTempSync('flutter_analyze_sample_code.');
    ProcessSignal.sigint.watch().listen((_) {
      print('Deleting temp files...');
      tempDir!.deleteSync(recursive: true);
      exit(0);
    });
    print('Using temp dir ${tempDir.path}');
  }
  print('Starting up in interactive mode on ${path.relative(filePath, from: _flutterRoot)} ...');

  Future<void> analyze(SampleChecker checker, File file) async {
    final Map<String, Section> sections = <String, Section>{};
    final Map<String, Sample> snippets = <String, Sample>{};
    await checker._extractSamples(<File>[file], silent: true, sectionMap: sections, sampleMap: snippets);
    final AnalysisResult analysisResult = checker._analyze(checker._tempDirectory, sections, snippets, silent: true);
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

  final SampleChecker checker = SampleChecker(flutterPackage, tempDirectory: tempDir)
    .._createConfigurationFiles(tempDir);
  await analyze(checker, file);

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
      case 'r':
        print('Deleting temp files...');
        tempDir!.deleteSync(recursive: true);
        rerun();
        break;
    }
  });

  Watcher(file.absolute.path).events.listen((_) => rerun());
}

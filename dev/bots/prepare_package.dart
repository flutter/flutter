// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:process/process.dart';

const String CHROMIUM_REPO =
    'https://chromium.googlesource.com/external/github.com/flutter/flutter';
const String GITHUB_REPO = 'https://github.com/flutter/flutter.git';
const String MINGIT_FOR_WINDOWS_URL = 'https://storage.googleapis.com/flutter_infra/mingit/'
    '603511c649b00bbef0a6122a827ac419b656bc19/mingit.zip';

/// Error class for when a process fails to run, so we can catch
/// it and provide something more readable than a stack trace.
class ProcessFailedException extends Error {
  ProcessFailedException([this.message, this.exitCode]);

  String message = '';
  int exitCode = 0;

  @override
  String toString() => message;
}

/// Creates a pre-populated Flutter archive from a git repo.
class ArchiveCreator {
  /// [_tempDir] is the directory to use for creating the archive.  The script
  /// will place several GiB of data there, so it should have available space.
  ///
  /// The starter argument is used to inject a mock of [Process.start] for
  /// testing purposes.
  ArchiveCreator(this._tempDir, {ProcessManager processManager, bool subprocessOutput: true})
      : _flutterRoot = new Directory(path.join(_tempDir.path, 'flutter')),
        _processManager = processManager ?? const LocalProcessManager(),
        _subprocessOutput = subprocessOutput {
    _flutter = path.join(
      _flutterRoot.absolute.path,
      'bin',
      Platform.isWindows ? 'flutter.bat' : 'flutter',
    );
    _environment = new Map<String, String>.from(Platform.environment);
    _environment['PUB_CACHE'] = path.join(_flutterRoot.absolute.path, '.pub-cache');
  }

  final Directory _flutterRoot;
  final Directory _tempDir;
  final bool _subprocessOutput;
  final ProcessManager _processManager;
  String _flutter;
  final String _git = Platform.isWindows ? 'git.bat' : 'git';
  final String _zip = Platform.isWindows ? '7za.exe' : 'zip';
  final String _tar = Platform.isWindows ? 'tar.exe' : 'tar';
  final Uri _minGitUri = Uri.parse(MINGIT_FOR_WINDOWS_URL);
  Map<String, String> _environment;

  static String defaultArchiveName(String revision) {
    final String os = Platform.operatingSystem.toLowerCase();
    final String id = revision.length > 10 ? revision.substring(0, 10) : revision;
    final String suffix = Platform.isWindows ? 'zip' : 'tar.xz';
    return 'flutter_${os}_$id.$suffix';
  }

  /// Performs all of the steps needed to create an archive.
  Future<File> createArchive(String revision, File outputFile) async {
    await _checkoutFlutter(revision);
    await _installMinGitIfNeeded();
    await _populateCaches();
    await _archiveFiles(outputFile);
    return outputFile;
  }

  /// Clone the Flutter repo and make sure that the git environment is sane
  /// for when the user will unpack it.
  Future<Null> _checkoutFlutter(String revision) async {
    // We want the user to start out the in the 'master' branch instead of a
    // detached head. To do that, we need to make sure master points at the
    // desired revision.
    await _runGit(<String>['clone', '-b', 'master', CHROMIUM_REPO], workingDirectory: _tempDir);
    await _runGit(<String>['reset', '--hard', revision]);

    // Make the origin point to github instead of the chromium mirror.
    await _runGit(<String>['remote', 'remove', 'origin']);
    await _runGit(<String>['remote', 'add', 'origin', GITHUB_REPO]);
  }

  /// Retrieve the MinGit executable from storage and unpack it.
  Future<Null> _installMinGitIfNeeded() async {
    if (!Platform.isWindows) {
      return;
    }
    final Uint8List data = await http.readBytes(_minGitUri);
    final File gitFile = new File(path.join(_tempDir.path, 'mingit.zip'));
    await gitFile.open(mode: FileMode.WRITE);
    await gitFile.writeAsBytes(data);

    final Directory minGitPath = new Directory(path.join(_flutterRoot.path, 'bin', 'mingit'));
    await minGitPath.create(recursive: true);
    await _unzipArchive(gitFile, currentDirectory: minGitPath);
  }

  /// Prepare the archive repo so that it has all of the caches warmed up and
  /// is configured for the user to begin working.
  Future<Null> _populateCaches() async {
    await _runFlutter(<String>['doctor']);
    await _runFlutter(<String>['update-packages']);
    await _runFlutter(<String>['precache']);
    await _runFlutter(<String>['ide-config']);

    // Create each of the templates, since they will call 'pub get' on
    // themselves when created, and this will warm the cache with their
    // dependencies too.
    for (String template in <String>['app', 'package', 'plugin']) {
      final String createName = path.join(_tempDir.path, 'create_$template');
      await _runFlutter(
        <String>['create', '--template=$template', createName],
      );
    }

    // Yes, we could just skip all .packages files when constructing
    // the archive, but some are checked in, and we don't want to skip
    // those.
    await _runGit(<String>['clean', '-f', '-X', '**/.packages']);
  }

  /// Write the archive to the given output file.
  Future<Null> _archiveFiles(File outputFile) async {
    if (outputFile.path.toLowerCase().endsWith('.zip')) {
      await _createZipArchive(outputFile, _flutterRoot);
    } else if (outputFile.path.toLowerCase().endsWith('.tar.xz')) {
      await _createTarArchive(outputFile, _flutterRoot);
    }
  }

  Future<String> _runFlutter(List<String> args) => _runProcess(<String>[_flutter]..addAll(args));

  Future<String> _runGit(List<String> args, {Directory workingDirectory}) {
    return _runProcess(<String>[_git]..addAll(args), workingDirectory: workingDirectory);
  }

  Future<String> _unzipArchive(File archive, {Directory currentDirectory}) {
    currentDirectory ??= new Directory(path.dirname(archive.absolute.path));
    final List<String> commandLine = <String>[];
    if (_zip == 'zip') {
      commandLine.add('unzip');
    } else {
      commandLine.addAll(<String>[_zip, 'x']);
    }
    commandLine.add(archive.absolute.path);

    return _runProcess(commandLine, workingDirectory: currentDirectory);
  }

  Future<String> _createZipArchive(File output, Directory source) {
    final List<String> commandLine = <String>[_zip];
    if (_zip == 'zip') {
      commandLine.addAll(<String>['-r', '-9', '-q']);
    } else {
      commandLine.addAll(<String>['a', '-tzip', '-mx=9']);
    }
    commandLine.addAll(<String>[
      output.absolute.path,
      path.basename(source.absolute.path),
    ]);
    return _runProcess(commandLine,
        workingDirectory: new Directory(path.dirname(source.absolute.path)));
  }

  Future<String> _createTarArchive(File output, Directory source) {
    return _runProcess(<String>[
      _tar,
      'cJf',
      output.absolute.path,
      path.basename(source.absolute.path),
    ], workingDirectory: new Directory(path.dirname(source.absolute.path)));
  }

  Future<String> _runProcess(List<String> commandLine, {Directory workingDirectory}) async {
    workingDirectory ??= _flutterRoot;
    if (_subprocessOutput) {
      stderr.write('Running "${commandLine.join(' ')}" in ${workingDirectory.path}.\n');
    }
    final List<int> output = <int>[];
    final Completer<Null> stdoutComplete = new Completer<Null>();
    final Completer<Null> stderrComplete = new Completer<Null>();
    Process process;
    Future<int> allComplete() async {
      await stderrComplete.future;
      await stdoutComplete.future;
      return process.exitCode;
    }

    try {
      process = await _processManager.start(
        commandLine,
        workingDirectory: workingDirectory.absolute.path,
        environment: _environment,
      );
      process.stdout.listen(
        (List<int> event) {
          output.addAll(event);
          if (_subprocessOutput) {
            stdout.add(event);
          }
        },
        onDone: () async => stdoutComplete.complete(),
      );
      if (_subprocessOutput) {
        process.stderr.listen(
          (List<int> event) {
            stderr.add(event);
          },
          onDone: () async => stderrComplete.complete(),
        );
      } else {
        stderrComplete.complete();
      }
    } on ProcessException catch (e) {
      final String message = 'Running "${commandLine.join(' ')}" in ${workingDirectory.path} '
          'failed with:\n${e.toString()}';
      throw new ProcessFailedException(message, -1);
    } catch (e) {
      rethrow;
    }

    final int exitCode = await allComplete();
    if (exitCode != 0) {
      final String message = 'Running "${commandLine.join(' ')}" in ${workingDirectory.path} '
          'failed with $exitCode.';
      throw new ProcessFailedException(message, exitCode);
    }
    return new Future<String>.value(UTF8.decoder.convert(output).trim());
  }
}

/// Prepares a flutter git repo to be packaged up for distribution.
/// It mainly serves to populate the .pub-cache with any appropriate Dart
/// packages, and the flutter cache in bin/cache with the appropriate
/// dependencies and snapshots.
///
/// Note that archives contain the executables and customizations for the
/// platform that they are created on.
Future<Null> main(List<String> argList) async {
  final ArgParser argParser = new ArgParser();
  argParser.addOption(
    'temp_dir',
    defaultsTo: null,
    help: 'A location where temporary files may be written. Defaults to a '
        'directory in the system temp folder. Will write a few GiB of data, '
        'so it should have sufficient free space.',
  );
  argParser.addOption(
    'revision',
    defaultsTo: 'master',
    help: 'The Flutter revision to build the archive with. Defaults to the '
        "master branch's HEAD revision.",
  );
  argParser.addOption(
    'output',
    defaultsTo: null,
    help: 'The path to the file where the output archive should be '
        'written. The output file must end in ".tar.xz" on Linux and Mac, '
        'and ".zip" on Windows. If --output is not specified, the archive will '
        "be written to the current directory. If the output directory doesn't "
        'exist, it, and the path to it, will be created.',
  );
  final ArgResults args = argParser.parse(argList);

  void errorExit(String message, {int exitCode = -1}) {
    stderr.write('Error: $message\n\n');
    stderr.write('${argParser.usage}\n');
    exit(exitCode);
  }

  if (args['revision'].isEmpty) {
    errorExit('Invalid argument: --revision must be specified.');
  }

  Directory tempDir;
  bool removeTempDir = false;
  if (args['temp_dir'] == null || args['temp_dir'].isEmpty) {
    tempDir = Directory.systemTemp.createTempSync('flutter_');
    removeTempDir = true;
  } else {
    tempDir = new Directory(args['temp_dir']);
    if (!tempDir.existsSync()) {
      errorExit("Temporary directory ${args['temp_dir']} doesn't exist.");
    }
  }

  final String output = (args['output'] == null || args['output'].isEmpty)
      ? path.join(path.current, ArchiveCreator.defaultArchiveName(args['revision']))
      : path.dirname(args['output']);

  /// Sanity check the output filename.
  final String outputFilename = path.basename(output);
  if (Platform.isWindows) {
    if (!outputFilename.endsWith('.zip')) {
      errorExit('The argument to --output must end in .zip on Windows.');
    }
  } else {
    if (!outputFilename.endsWith('.tar.xz')) {
      errorExit('The argument to --output must end in .tar.xz on Linux and Mac.');
    }
  }

  final Directory outputDirectory = new Directory(path.dirname(output));
  if (!outputDirectory.existsSync()) {
    outputDirectory.createSync(recursive: true);
  }
  final File outputFile = new File(path.join(outputDirectory.absolute.path, outputFilename));

  final ArchiveCreator preparer = new ArchiveCreator(tempDir);
  int exitCode = 0;
  String message;
  try {
    await preparer.createArchive(args['revision'], outputFile);
  } on ProcessFailedException catch (e) {
    exitCode = e.exitCode;
    message = e.message;
  } catch (e) {
    rethrow;
  } finally {
    if (removeTempDir) {
      tempDir.deleteSync(recursive: true);
    }
    if (exitCode != 0) {
      errorExit(message, exitCode: exitCode);
    }
    exit(0);
  }
}

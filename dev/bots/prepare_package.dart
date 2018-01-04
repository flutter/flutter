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

const String CHROMIUM_REPO =
    'https://chromium.googlesource.com/external/github.com/flutter/flutter';
const String GITHUB_REPO = 'https://github.com/flutter/flutter.git';
const String MINGIT_FOR_WINDOWS_URL = 'https://storage.googleapis.com/flutter_infra/mingit/'
    '603511c649b00bbef0a6122a827ac419b656bc19/mingit.zip';

/// The type of the process runner function.  This allows us to
/// inject a fake process runner into the ArchiveCreator for tests.
typedef Future<Process> ProcessStarter(String executable, List<String> arguments,
    {String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment,
    bool runInShell,
    ProcessStartMode mode});

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
  /// [tempDir] is the directory to use for creating the archive.  The script
  /// will place several GiB of data there, so it should have available space.
  ///
  /// [outputDirectory] is the path to the directory in which to place the output
  /// archive. The output file will have the name "flutter_<version>.tar.xz" on
  /// Linux and Mac, and "flutter_<version>.zip" on Windows, where <version> is
  /// the version number of Flutter for the archive.
  ///
  /// The starter argument is used to inject a mock of [Process.start] for
  /// testing purposes.
  ArchiveCreator(this.tempDir, this.outputDirectory,
      {ProcessStarter starter, bool subprocessOutput: true})
      : flutterRoot = new Directory(path.join(tempDir.path, 'flutter')),
        _starter = starter ?? Process.start,
        _subprocessOutput = subprocessOutput {
    flutter = path.join(
      flutterRoot.absolute.path,
      'bin',
      Platform.isWindows ? 'flutter.bat' : 'flutter',
    );
    environment = new Map<String, String>.from(Platform.environment);
    environment['PUB_CACHE'] = path.join(flutterRoot.absolute.path, '.pub-cache');
  }

  final Directory flutterRoot;
  final Directory tempDir;
  final Directory outputDirectory;
  final bool _subprocessOutput;
  final ProcessStarter _starter;
  String flutter;
  final String git = Platform.isWindows ? 'git.bat' : 'git';
  final String zip = Platform.isWindows ? '7za.exe' : 'zip';
  final String tar = Platform.isWindows ? 'tar.exe' : 'tar';
  final Uri minGitUri = Uri.parse(MINGIT_FOR_WINDOWS_URL);
  Map<String, String> environment;

  /// Performs all of the steps needed to create an archive.
  Future<File> createArchive(String revision) async {
    await checkoutFlutter(revision);
    await installMinGitIfNeeded();
    await populateCaches();
    final File outputFile =
        new File(path.join(outputDirectory.absolute.path, await _getArchiveName(revision)));
    await archiveFiles(outputFile);
    return outputFile;
  }

  Future<String> getArchiveName(String revision) async {
    if (!flutterRoot.existsSync()) {
      await checkoutFlutter(revision);
    }
    final File outputFile =
        new File(path.join(outputDirectory.path, await _getArchiveName(revision)));
    return outputFile.absolute.path;
  }

  /// Clone the Flutter repo and make sure that the git environment is sane
  /// for when the user will unpack it.
  Future<Null> checkoutFlutter(String revision) async {
    // We want the user to start out the in the 'master' branch instead of a
    // detached head. To do that, we need to make sure master points at the
    // desired revision.
    await runGit(<String>['clone', '-b', 'master', CHROMIUM_REPO], workingDirectory: tempDir);
    await runGit(<String>['reset', '--hard', revision]);

    // Make the origin point to github instead of the chromium mirror.
    await runGit(<String>['remote', 'remove', 'origin']);
    await runGit(<String>['remote', 'add', 'origin', GITHUB_REPO]);
  }

  /// Retrieve the MinGit executable from storage and unpack it.
  Future<Null> installMinGitIfNeeded() async {
    if (!Platform.isWindows) {
      return;
    }
    final Uint8List data = await http.readBytes(minGitUri);
    final File gitFile = new File(path.join(tempDir.path, 'mingit.zip'));
    await gitFile.open(mode: FileMode.WRITE);
    await gitFile.writeAsBytes(data);

    final Directory minGitPath = new Directory(path.join(flutterRoot.path, 'bin', 'mingit'));
    await minGitPath.create(recursive: true);
    await unzipArchive(gitFile, currentDirectory: minGitPath);
  }

  /// Prepare the archive repo so that it has all of the caches warmed up and
  /// is configured for the user to begin working.
  Future<Null> populateCaches() async {
    await runFlutter(<String>['doctor']);
    await runFlutter(<String>['update-packages']);
    await runFlutter(<String>['precache']);
    await runFlutter(<String>['ide-config']);

    // Create each of the templates, since they will call 'pub get' on
    // themselves when created, and this will warm the cache with their
    // dependencies too.
    for (String template in <String>['app', 'package', 'plugin']) {
      final String createName = path.join(tempDir.path, 'create_$template');
      await runFlutter(
        <String>['create', '--template=$template', createName],
      );
    }

    // Yes, we could just skip all .packages files when constructing
    // the archive, but some are checked in, and we don't want to skip
    // those.
    await runGit(<String>['clean', '-f', '-X', '**/.packages']);
  }

  /// Write the archive to the given output file.
  Future<Null> archiveFiles(File outputFile) async {
    if (outputFile.path.toLowerCase().endsWith('.zip')) {
      await createZipArchive(outputFile, flutterRoot);
    } else if (outputFile.path.toLowerCase().endsWith('.tar.xz')) {
      await createTarArchive(outputFile, flutterRoot);
    }
  }

  Future<String> _runProcess(String executable, List<String> args,
      {Directory workingDirectory}) async {
    workingDirectory ??= flutterRoot;
    if (_subprocessOutput) {
      stderr.write('Running "$executable ${args.join(' ')}" in ${workingDirectory.path}.\n');
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
      process = await _starter(
        executable,
        args,
        workingDirectory: workingDirectory.absolute.path,
        environment: environment,
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
      final String message = 'Running "$executable ${args.join(' ')}" in ${workingDirectory.path} '
          'failed with:\n${e.toString()}';
      throw new ProcessFailedException(message, -1);
    } catch (e) {
      rethrow;
    }

    final int exitCode = await allComplete();
    if (exitCode != 0) {
      final String message = 'Running "$executable ${args.join(' ')}" in ${workingDirectory.path} '
          'failed with $exitCode.';
      throw new ProcessFailedException(message, exitCode);
    }
    return new Future<String>.value(UTF8.decoder.convert(output).trim());
  }

  Future<String> runFlutter(List<String> args) {
    return _runProcess(flutter, args);
  }

  Future<String> runGit(List<String> args, {Directory workingDirectory}) {
    return _runProcess(git, args, workingDirectory: workingDirectory);
  }

  Future<String> unzipArchive(File archive, {Directory currentDirectory}) {
    currentDirectory ??= new Directory(path.dirname(archive.absolute.path));
    final List<String> args = <String>[];
    String executable;
    if (zip == 'zip') {
      executable = 'unzip';
    } else {
      executable = zip;
      args.addAll(<String>['x']);
    }
    args.add(archive.absolute.path);

    return _runProcess(executable, args, workingDirectory: currentDirectory);
  }

  Future<String> createZipArchive(File output, Directory source) {
    final List<String> args = <String>[];
    if (zip == 'zip') {
      args.addAll(<String>['-r', '-9', '-q']);
    } else {
      args.addAll(<String>['a', '-tzip', '-mx=9']);
    }
    args.addAll(<String>[
      output.absolute.path,
      path.basename(source.absolute.path),
    ]);

    return _runProcess(zip, args,
        workingDirectory: new Directory(path.dirname(source.absolute.path)));
  }

  Future<String> createTarArchive(File output, Directory source) {
    final List<String> args = <String>[
      'cJf',
      output.absolute.path,
      path.basename(source.absolute.path),
    ];
    return _runProcess(tar, args,
        workingDirectory: new Directory(path.dirname(source.absolute.path)));
  }

  /// Finds the largest "plain" version number (just #.#.#, no alpha or symbols)
  /// that is not greater than the current version by sorting the version numbers
  /// (including the current one) in descending order according to release order
  /// and returning the one before the current one.
  String _getLargestPreviousVersion(String currentVersion, List<String> tags) {
    assert(tags != null && tags.isNotEmpty);
    final RegExp normalReleaseRe = new RegExp(r'^([0-9]+)\.([0-9]+)\.([0-9]+)(-dev)?$');
    tags.add(currentVersion);
    tags.sort((String a, String b) {
      final Match matchA = normalReleaseRe.firstMatch(a);
      final Match matchB = normalReleaseRe.firstMatch(b);
      // Make sure non-release (and non-normal release tags) get sorted at the bottom
      // of the list.
      if (matchA == null) {
        return 1;
      }
      if (matchB == null) {
        return -1;
      }
      final int majorDiff = int.parse(matchB.group(1)) - int.parse(matchA.group(1));
      if (majorDiff != 0) {
        return majorDiff;
      }
      final int minorDiff = int.parse(matchB.group(2)) - int.parse(matchA.group(2));
      if (minorDiff != 0) {
        return minorDiff;
      }
      final int revDiff = int.parse(matchB.group(3)) - int.parse(matchA.group(3));
      if (revDiff != 0) {
        return revDiff;
      }
      final int devA = matchA.group(4) == null ? 0 : 1;
      final int devB = matchB.group(4) == null ? 0 : 1;
      return devB - devA;
    });
    return tags[tags.indexOf(currentVersion) + 1];
  }

  /// Gets the output name of the archive.  The output name is a combination
  /// of "flutter_" with the OS, the current version in the VERSION file, and the
  /// number of commits since that version changed appended to it.
  ///
  /// So, for example, when the VERSION file contains '0.0.21-dev', if the
  /// current revision has 85 commits since the last alpha roll, and we're on Linux,
  /// the string returned from this function is:
  ///
  /// flutter_linux_0.0.21-dev.85.tar.xz
  ///
  /// When the version number in VERSION doesn't include '-dev', i.e. when we're
  /// doing an alpha roll, then it is tagged with alpha instead, giving:
  ///
  /// flutter_linux_0.0.22.alpha.tar.xz
  ///
  /// Beta rolls are copied from an alpha roll, so this function doesn't deal with
  /// naming beta rolls. Likewise, production rolls are copied from previous beta
  /// rolls.
  Future<String> _getArchiveName(String revision) async {
    // Parse the version number out of the VERSION file.
    String version;
    final File versionFile = new File(path.join(flutterRoot.path, 'VERSION'));
    try {
      final RegExp versionRegExp = new RegExp(r'^\s*([^#\s]+)\s*(#.*)?$');
      for (String line in const LineSplitter().convert(await versionFile.readAsString())) {
        final Match match = versionRegExp.firstMatch(line);
        if (match != null) {
          version = match[1];
          break;
        }
      }
    } on FileSystemException catch (e) {
      throw new Exception('Unable to read version number from ${versionFile.path}: $e');
    }
    if (version == null) {
      throw new Exception('Unable to find version number in ${versionFile.path}.');
    }

    String revisionCount;
    // If we're not rolling alpha, find the number of revisions since we did.
    if (version.endsWith('-dev')) {
      final List<String> tags = const LineSplitter().convert(await runGit(<String>['tag', '-l']));
      final String largestVersion = _getLargestPreviousVersion(version, tags);

      // Convert the version number into a ref from the tag.
      final String alphaRef =
          await runGit(<String>['tag', '-l', '$largestVersion', '--format', r'%(objectname)']);

      // Count the number of straight-line versions between HEAD and the previous version's ref.
      revisionCount =
          await runGit(<String>['rev-list', '--first-parent', '--count', '$alphaRef..HEAD']);
    } else {
      revisionCount = 'alpha';
    }

    final String suffix = Platform.isWindows ? '.zip' : '.tar.xz';
    return 'flutter_${Platform.operatingSystem.toLowerCase()}_$version.$revisionCount$suffix';
  }
}

/// Prepares a flutter git repo to be packaged up for distribution.
/// It mainly serves to populate the .pub-cache with any appropriate Dart
/// packages, and the flutter cache in bin/cache with the appropriate
/// dependencies and snapshots.
///
/// Note that archives contain the executables and customizations for the
/// platform that they are created on.  So, for instance, a ZIP archive
/// created on a Mac will contain Mac executables and setup, even though
/// it's in a zip file.
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
    help: 'The path to the directory where the output archive should be '
        'written. The output file will have the name '
        '"flutter_linux_<version>.tar.xz" on Linux, '
        '"flutter_mac_<version>.tar.xz" on Mac, and '
        '"flutter_windows_<version>.zip" on Windows, where <version> is the '
        'version number of Flutter for the archive. If --output is not '
        'specified, the archive will be written to the current directory. '
        "If the output directory doesn't exist, it, and the path to it, will "
        'be created.',
  );
  argParser.addFlag(
    'name-only',
    defaultsTo: false,
    help: 'Tells the script to only emit the expected output name to stdout, '
        'without creating an archive. If the Flutter root is already '
        'populated, uses the existing Flutter root.',
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

  String outputPath = args['output'];
  if (outputPath == null || outputPath.isEmpty) {
    outputPath = path.current;
  }

  final Directory outputDirectory = new Directory(outputPath);
  if (!outputDirectory.existsSync()) {
    outputDirectory.createSync(recursive: true);
  }

  final ArchiveCreator preparer =
      new ArchiveCreator(tempDir, outputDirectory, subprocessOutput: !args['name-only']);
  int exitCode = 0;
  String message;
  if (args['name-only']) {
    stdout.write('${await preparer.getArchiveName(args['revision'])}\n');
    return;
  }
  File outputFile;
  try {
    outputFile = await preparer.createArchive(args['revision']);
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
    if (outputFile != null && outputFile.existsSync()) {
      print('ARCHIVE_NAME: ${outputFile.absolute.path}');
    }
    exit(0);
  }
}

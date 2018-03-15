// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:platform/platform.dart' show Platform, LocalPlatform;

const String chromiumRepo = 'https://chromium.googlesource.com/external/github.com/flutter/flutter';
const String githubRepo = 'https://github.com/flutter/flutter.git';
const String mingitForWindowsUrl = 'https://storage.googleapis.com/flutter_infra/mingit/'
    '603511c649b00bbef0a6122a827ac419b656bc19/mingit.zip';
const String gsBase = 'gs://flutter_infra';
const String releaseFolder = '/releases';
const String gsReleaseFolder = '$gsBase$releaseFolder';
const String baseUrl = 'https://storage.googleapis.com/flutter_infra';

/// Exception class for when a process fails to run, so we can catch
/// it and provide something more readable than a stack trace.
class ProcessRunnerException implements Exception {
  ProcessRunnerException(this.message, [this.result]);

  final String message;
  final ProcessResult result;
  int get exitCode => result?.exitCode ?? -1;

  @override
  String toString() {
    String output = runtimeType.toString();
    if (message != null) {
      output += ': $message';
    }
    final String stderr = result?.stderr ?? '';
    if (stderr.isNotEmpty) {
      output += ':\n$stderr';
    }
    return output;
  }
}

enum Branch { dev, beta, release }

String getBranchName(Branch branch) {
  switch (branch) {
    case Branch.beta:
      return 'beta';
    case Branch.dev:
      return 'dev';
    case Branch.release:
      return 'release';
  }
  return null;
}

Branch fromBranchName(String name) {
  switch (name) {
    case 'beta':
      return Branch.beta;
    case 'dev':
      return Branch.dev;
    case 'release':
      return Branch.release;
    default:
      throw new ArgumentError('Invalid branch name.');
  }
}

/// A helper class for classes that want to run a process, optionally have the
/// stderr and stdout reported as the process runs, and capture the stdout
/// properly without dropping any.
class ProcessRunner {
  ProcessRunner({
    ProcessManager processManager,
    this.subprocessOutput: true,
    this.defaultWorkingDirectory,
    this.platform: const LocalPlatform(),
  }) : processManager = processManager ?? const LocalProcessManager() {
    environment = new Map<String, String>.from(platform.environment);
  }

  /// The platform to use for a starting environment.
  final Platform platform;

  /// Set [subprocessOutput] to show output as processes run. Stdout from the
  /// process will be printed to stdout, and stderr printed to stderr.
  final bool subprocessOutput;

  /// Set the [processManager] in order to inject a test instance to perform
  /// testing.
  final ProcessManager processManager;

  /// Sets the default directory used when `workingDirectory` is not specified
  /// to [runProcess].
  final Directory defaultWorkingDirectory;

  /// The environment to run processes with.
  Map<String, String> environment;

  /// Run the command and arguments in `commandLine` as a sub-process from
  /// `workingDirectory` if set, or the [defaultWorkingDirectory] if not. Uses
  /// [Directory.current] if [defaultWorkingDirectory] is not set.
  ///
  /// Set `failOk` if [runProcess] should not throw an exception when the
  /// command completes with a a non-zero exit code.
  Future<String> runProcess(
    List<String> commandLine, {
    Directory workingDirectory,
    bool failOk: false,
  }) async {
    workingDirectory ??= defaultWorkingDirectory ?? Directory.current;
    if (subprocessOutput) {
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
      process = await processManager.start(
        commandLine,
        workingDirectory: workingDirectory.absolute.path,
        environment: environment,
      );
      process.stdout.listen(
        (List<int> event) {
          output.addAll(event);
          if (subprocessOutput) {
            stdout.add(event);
          }
        },
        onDone: () async => stdoutComplete.complete(),
      );
      if (subprocessOutput) {
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
      throw new ProcessRunnerException(message);
    } on ArgumentError catch (e) {
      final String message = 'Running "${commandLine.join(' ')}" in ${workingDirectory.path} '
          'failed with:\n${e.toString()}';
      throw new ProcessRunnerException(message);
    }

    final int exitCode = await allComplete();
    if (exitCode != 0 && !failOk) {
      final String message =
          'Running "${commandLine.join(' ')}" in ${workingDirectory.path} failed';
      throw new ProcessRunnerException(
          message, new ProcessResult(0, exitCode, null, 'returned $exitCode'));
    }
    return utf8.decoder.convert(output).trim();
  }
}

typedef Future<Uint8List> HttpReader(Uri url, {Map<String, String> headers});

/// Creates a pre-populated Flutter archive from a git repo.
class ArchiveCreator {
  /// [tempDir] is the directory to use for creating the archive.  The script
  /// will place several GiB of data there, so it should have available space.
  ///
  /// The processManager argument is used to inject a mock of [ProcessManager] for
  /// testing purposes.
  ///
  /// If subprocessOutput is true, then output from processes invoked during
  /// archive creation is echoed to stderr and stdout.
  ArchiveCreator(
    this.tempDir,
    this.outputDir,
    this.revision,
    this.branch, {
    ProcessManager processManager,
    bool subprocessOutput: true,
    this.platform: const LocalPlatform(),
    HttpReader httpReader,
  }) : assert(revision.length == 40),
       flutterRoot = new Directory(path.join(tempDir.path, 'flutter')),
       httpReader = httpReader ?? http.readBytes,
       _processRunner = new ProcessRunner(
         processManager: processManager,
         subprocessOutput: subprocessOutput,
         platform: platform,
       ) {
    _flutter = path.join(
      flutterRoot.absolute.path,
      'bin',
      'flutter',
    );
    _processRunner.environment['PUB_CACHE'] = path.join(flutterRoot.absolute.path, '.pub-cache');
  }

  /// The platform to use for the environment and determining which
  /// platform we're running on.
  final Platform platform;

  /// The branch to build the archive for.  The branch must contain [revision].
  final Branch branch;

  /// The git revision hash to build the archive for. This revision has
  /// to be available in the [branch], although it doesn't have to be
  /// at HEAD, since we clone the branch and then reset to this revision
  /// to create the archive.
  final String revision;

  /// The flutter root directory in the [tempDir].
  final Directory flutterRoot;

  /// The temporary directory used to build the archive in.
  final Directory tempDir;

  /// The directory to write the output file to.
  final Directory outputDir;

  final Uri _minGitUri = Uri.parse(mingitForWindowsUrl);
  final ProcessRunner _processRunner;

  /// Used to tell the [ArchiveCreator] which function to use for reading
  /// bytes from a URL. Used in tests to inject a fake reader. Defaults to
  /// [http.readBytes].
  final HttpReader httpReader;

  File _outputFile;
  String _version;
  String _flutter;

  /// Get the name of the channel as a string.
  String get branchName => getBranchName(branch);

  /// Returns a default archive name when given a Git revision.
  /// Used when an output filename is not given.
  String get _archiveName {
    final String os = platform.operatingSystem.toLowerCase();
    // We don't use .tar.xz on Mac because although it can unpack them
    // on the command line (with tar), the "Archive Utility" that runs
    // when you double-click on them just does some crazy behavior (it
    // converts it to a compressed cpio archive, and when you double
    // click on that, it converts it back to .tar.xz, without ever
    // unpacking it!) So, we use .zip for Mac, and the files are about
    // 220MB larger than they need to be. :-(
    final String suffix = platform.isLinux ? 'tar.xz' : 'zip';
    return 'flutter_${os}_$_version-$branchName.$suffix';
  }

  /// Checks out the flutter repo and prepares it for other operations.
  ///
  /// Returns the version for this release, as obtained from the git tags.
  Future<String> initializeRepo() async {
    await _checkoutFlutter();
    _version = await _getVersion();
    return _version;
  }

  /// Performs all of the steps needed to create an archive.
  Future<File> createArchive() async {
    assert(_version != null, 'Must run initializeRepo before createArchive');
    _outputFile = new File(path.join(outputDir.absolute.path, _archiveName));
    await _installMinGitIfNeeded();
    await _populateCaches();
    await _archiveFiles(_outputFile);
    return _outputFile;
  }

  /// Returns the version number of this release, according the to tags in
  /// the repo.
  Future<String> _getVersion() async {
    return _runGit(<String>['describe', '--tags', '--abbrev=0']);
  }

  /// Clone the Flutter repo and make sure that the git environment is sane
  /// for when the user will unpack it.
  Future<Null> _checkoutFlutter() async {
    // We want the user to start out the in the specified branch instead of a
    // detached head. To do that, we need to make sure the branch points at the
    // desired revision.
    await _runGit(<String>['clone', '-b', branchName, chromiumRepo], workingDirectory: tempDir);
    await _runGit(<String>['reset', '--hard', revision]);

    // Make the origin point to github instead of the chromium mirror.
    await _runGit(<String>['remote', 'set-url', 'origin', githubRepo]);
  }

  /// Retrieve the MinGit executable from storage and unpack it.
  Future<Null> _installMinGitIfNeeded() async {
    if (!platform.isWindows) {
      return;
    }
    final Uint8List data = await httpReader(_minGitUri);
    final File gitFile = new File(path.join(tempDir.absolute.path, 'mingit.zip'));
    await gitFile.writeAsBytes(data, flush: true);

    final Directory minGitPath =
        new Directory(path.join(flutterRoot.absolute.path, 'bin', 'mingit'));
    await minGitPath.create(recursive: true);
    await _unzipArchive(gitFile, workingDirectory: minGitPath);
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
      final String createName = path.join(tempDir.path, 'create_$template');
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
      await _createZipArchive(outputFile, flutterRoot);
    } else if (outputFile.path.toLowerCase().endsWith('.tar.xz')) {
      await _createTarArchive(outputFile, flutterRoot);
    }
  }

  Future<String> _runFlutter(List<String> args, {Directory workingDirectory}) {
    return _processRunner.runProcess(<String>[_flutter]..addAll(args),
        workingDirectory: workingDirectory ?? flutterRoot);
  }

  Future<String> _runGit(List<String> args, {Directory workingDirectory}) {
    return _processRunner.runProcess(<String>['git']..addAll(args),
        workingDirectory: workingDirectory ?? flutterRoot);
  }

  /// Unpacks the given zip file into the currentDirectory (if set), or the
  /// same directory as the archive.
  Future<String> _unzipArchive(File archive, {Directory workingDirectory}) {
    workingDirectory ??= new Directory(path.dirname(archive.absolute.path));
    List<String> commandLine;
    if (platform.isWindows) {
      commandLine = <String>[
        '7za',
        'x',
        archive.absolute.path,
      ];
    } else {
      commandLine = <String>[
        'unzip',
        archive.absolute.path,
      ];
    }
    return _processRunner.runProcess(commandLine, workingDirectory: workingDirectory);
  }

  /// Create a zip archive from the directory source.
  Future<String> _createZipArchive(File output, Directory source) {
    List<String> commandLine;
    if (platform.isWindows) {
      commandLine = <String>[
        '7za',
        'a',
        '-tzip',
        '-mx=9',
        output.absolute.path,
        path.basename(source.path),
      ];
    } else {
      commandLine = <String>[
        'zip',
        '-r',
        '-9',
        output.absolute.path,
        path.basename(source.path),
      ];
    }
    return _processRunner.runProcess(commandLine,
        workingDirectory: new Directory(path.dirname(source.absolute.path)));
  }

  /// Create a tar archive from the directory source.
  Future<String> _createTarArchive(File output, Directory source) {
    return _processRunner.runProcess(<String>[
      'tar',
      'cJf',
      output.absolute.path,
      path.basename(source.absolute.path),
    ], workingDirectory: new Directory(path.dirname(source.absolute.path)));
  }
}

class ArchivePublisher {
  ArchivePublisher(
    this.tempDir,
    this.revision,
    this.branch,
    this.version,
    this.outputFile, {
    ProcessManager processManager,
    bool subprocessOutput: true,
    this.platform: const LocalPlatform(),
  }) : assert(revision.length == 40),
       platformName = platform.operatingSystem.toLowerCase(),
       metadataGsPath = '$gsReleaseFolder/releases_${platform.operatingSystem.toLowerCase()}.json',
       _processRunner = new ProcessRunner(
         processManager: processManager,
         subprocessOutput: subprocessOutput,
       );

  final Platform platform;
  final String platformName;
  final String metadataGsPath;
  final Branch branch;
  final String revision;
  final String version;
  final Directory tempDir;
  final File outputFile;
  final ProcessRunner _processRunner;
  String get branchName => getBranchName(branch);
  String get destinationArchivePath =>
      '$branchName/$platformName/${path.basename(outputFile.path)}';

  /// Publish the archive to Google Storage.
  Future<Null> publishArchive() async {
    final String destGsPath = '$gsReleaseFolder/$destinationArchivePath';
    await _cloudCopy(outputFile.absolute.path, destGsPath);
    assert(tempDir.existsSync());
    await _updateMetadata();
  }

  Future<Null> _updateMetadata() async {
    final String currentMetadata = await _runGsUtil(<String>['cat', metadataGsPath]);
    if (currentMetadata.isEmpty) {
      throw new ProcessRunnerException('Empty metadata received from server');
    }

    Map<String, dynamic> jsonData;
    try {
      jsonData = json.decode(currentMetadata);
    } on FormatException catch (e) {
      throw new ProcessRunnerException('Unable to parse JSON metadata received from cloud: $e');
    }

    // Update the metadata file with the data for this package.
    jsonData['base_url'] = '$baseUrl$releaseFolder';
    if (!jsonData.containsKey('current_release')) {
      jsonData['current_release'] = <String, String>{};
    }
    jsonData['current_release'][branchName] = revision;
    if (!jsonData.containsKey('releases')) {
      jsonData['releases'] = <String, dynamic>{};
    }
    if (!jsonData['releases'].containsKey(revision)) {
      jsonData['releases'][revision] = <String, Map<String, String>>{};
    }
    final Map<String, String> metadata = <String, String>{};
    metadata['${platformName}_archive'] = destinationArchivePath;
    metadata['release_date'] = new DateTime.now().toUtc().toIso8601String();
    metadata['version'] = version;
    jsonData['releases'][revision][branchName] = metadata;

    final File tempFile = new File(path.join(tempDir.absolute.path, 'releases_$platformName.json'));
    const JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    tempFile.writeAsStringSync(encoder.convert(jsonData));
    await _cloudCopy(tempFile.absolute.path, metadataGsPath);
  }

  Future<String> _runGsUtil(List<String> args,
      {Directory workingDirectory, bool failOk: false}) async {
    return _processRunner.runProcess(
      <String>['gsutil']..addAll(args),
      workingDirectory: workingDirectory,
      failOk: failOk,
    );
  }

  Future<String> _cloudCopy(String src, String dest) async {
    // We often don't have permission to overwrite, but
    // we have permission to remove, so that's what we do.
    await _runGsUtil(<String>['rm', dest], failOk: true);
    String mimeType;
    if (dest.endsWith('.tar.xz')) {
      mimeType = 'application/x-gtar';
    }
    if (dest.endsWith('.zip')) {
      mimeType = 'application/zip';
    }
    if (dest.endsWith('.json')) {
      mimeType = 'application/json';
    }
    final List<String> args = <String>[];
    // Use our preferred MIME type for the files we care about
    // and let gsutil figure it out for anything else.
    if (mimeType != null) {
      args.addAll(<String>['-h', 'Content-Type:$mimeType']);
    }
    args.addAll(<String>['cp', src, dest]);
    return _runGsUtil(args);
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
        'so it should have sufficient free space. If a temp_dir is not '
        'specified, then the default temp_dir will be created, used, and '
        'removed automatically.',
  );
  argParser.addOption('revision',
      defaultsTo: null,
      help: 'The Flutter git repo revision to build the '
          'archive with. Must be the full 40-character hash. Required.');
  argParser.addOption(
    'branch',
    defaultsTo: null,
    allowed: Branch.values.map((Branch branch) => getBranchName(branch)),
    help: 'The Flutter branch to build the archive with. Required.',
  );
  argParser.addOption(
    'output',
    defaultsTo: null,
    help: 'The path to the directory where the output archive should be '
        'written. If --output is not specified, the archive will be written to '
        "the current directory. If the output directory doesn't exist, it, and "
        'the path to it, will be created.',
  );
  argParser.addFlag(
    'publish',
    defaultsTo: false,
    help: 'If set, will publish the archive to Google Cloud Storage upon '
        'successful creation of the archive. Will publish under this '
        'directory: $baseUrl$releaseFolder',
  );
  argParser.addFlag(
    'help',
    defaultsTo: false,
    negatable: false,
    help: 'Print help for this command.',
  );

  final ArgResults args = argParser.parse(argList);

  if (args['help']) {
    print(argParser.usage);
    exit(0);
  }

  void errorExit(String message, {int exitCode = -1}) {
    stderr.write('Error: $message\n\n');
    stderr.write('${argParser.usage}\n');
    exit(exitCode);
  }

  final String revision = args['revision'];
  if (revision.isEmpty) {
    errorExit('Invalid argument: --revision must be specified.');
  }
  if (revision.length != 40) {
    errorExit('Invalid argument: --revision must be the entire hash, not just a prefix.');
  }

  if (args['branch'].isEmpty) {
    errorExit('Invalid argument: --branch must be specified.');
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

  Directory outputDir;
  if (args['output'] == null) {
    outputDir = tempDir;
  } else {
    outputDir = new Directory(args['output']);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
  }

  final Branch branch = fromBranchName(args['branch']);
  final ArchiveCreator creator = new ArchiveCreator(tempDir, outputDir, revision, branch);
  int exitCode = 0;
  String message;
  try {
    final String version = await creator.initializeRepo();
    final File outputFile = await creator.createArchive();
    if (args['publish']) {
      final ArchivePublisher publisher = new ArchivePublisher(
        tempDir,
        revision,
        branch,
        version,
        outputFile,
      );
      await publisher.publishArchive();
    }
  } on ProcessRunnerException catch (e) {
    exitCode = e.exitCode;
    message = e.message;
  } catch (e) {
    exitCode = -1;
    message = e.toString();
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

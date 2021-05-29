// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto/src/digest_sink.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart' show required;
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart' show Platform, LocalPlatform;
import 'package:process/process.dart';

const String chromiumRepo = 'https://chromium.googlesource.com/external/github.com/flutter/flutter';
const String githubRepo = 'https://github.com/flutter/flutter.git';
const String mingitForWindowsUrl = 'https://storage.googleapis.com/flutter_infra_release/mingit/'
    '603511c649b00bbef0a6122a827ac419b656bc19/mingit.zip';
const String oldGsBase = 'gs://flutter_infra';
const String releaseFolder = '/releases';
const String oldGsReleaseFolder = '$oldGsBase$releaseFolder';
const String oldBaseUrl = 'https://storage.googleapis.com/flutter_infra';
const String newGsBase = 'gs://flutter_infra_release';
const String newGsReleaseFolder = '$newGsBase$releaseFolder';
const String newBaseUrl = 'https://storage.googleapis.com/flutter_infra_release';
const int shortCacheSeconds = 60;

/// Exception class for when a process fails to run, so we can catch
/// it and provide something more readable than a stack trace.
class PreparePackageException implements Exception {
  PreparePackageException(this.message, [this.result]);

  final String message;
  final ProcessResult result;
  int get exitCode => result?.exitCode ?? -1;

  @override
  String toString() {
    String output = runtimeType.toString();
    if (message != null) {
      output += ': $message';
    }
    final String stderr = result?.stderr as String ?? '';
    if (stderr.isNotEmpty) {
      output += ':\n$stderr';
    }
    return output;
  }
}

enum Branch { dev, beta, stable }

String getBranchName(Branch branch) {
  switch (branch) {
    case Branch.beta:
      return 'beta';
    case Branch.dev:
      return 'dev';
    case Branch.stable:
      return 'stable';
  }
  return null;
}

Branch fromBranchName(String name) {
  switch (name) {
    case 'beta':
      return Branch.beta;
    case 'dev':
      return Branch.dev;
    case 'stable':
      return Branch.stable;
    default:
      throw ArgumentError('Invalid branch name.');
  }
}

/// A helper class for classes that want to run a process, optionally have the
/// stderr and stdout reported as the process runs, and capture the stdout
/// properly without dropping any.
class ProcessRunner {
  ProcessRunner({
    ProcessManager processManager,
    this.subprocessOutput = true,
    this.defaultWorkingDirectory,
    this.platform = const LocalPlatform(),
  }) : processManager = processManager ?? const LocalProcessManager() {
    environment = Map<String, String>.from(platform.environment);
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
  /// command completes with a non-zero exit code.
  Future<String> runProcess(
    List<String> commandLine, {
    Directory workingDirectory,
    bool failOk = false,
  }) async {
    workingDirectory ??= defaultWorkingDirectory ?? Directory.current;
    if (subprocessOutput) {
      stderr.write('Running "${commandLine.join(' ')}" in ${workingDirectory.path}.\n');
    }
    final List<int> output = <int>[];
    final Completer<void> stdoutComplete = Completer<void>();
    final Completer<void> stderrComplete = Completer<void>();
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
      throw PreparePackageException(message);
    } on ArgumentError catch (e) {
      final String message = 'Running "${commandLine.join(' ')}" in ${workingDirectory.path} '
          'failed with:\n${e.toString()}';
      throw PreparePackageException(message);
    }

    final int exitCode = await allComplete();
    if (exitCode != 0 && !failOk) {
      final String message = 'Running "${commandLine.join(' ')}" in ${workingDirectory.path} failed';
      throw PreparePackageException(
        message,
        ProcessResult(0, exitCode, null, 'returned $exitCode'),
      );
    }
    return utf8.decoder.convert(output).trim();
  }
}

typedef HttpReader = Future<Uint8List> Function(Uri url, {Map<String, String> headers});

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
    this.strict = true,
    ProcessManager processManager,
    bool subprocessOutput = true,
    this.platform = const LocalPlatform(),
    HttpReader httpReader,
  })  : assert(revision.length == 40),
        flutterRoot = Directory(path.join(tempDir.path, 'flutter')),
        httpReader = httpReader ?? http.readBytes,
        _processRunner = ProcessRunner(
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

  /// True if the creator should be strict about checking requirements or not.
  ///
  /// In strict mode, will insist that the [revision] be a tagged revision.
  final bool strict;

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
    _outputFile = File(path.join(outputDir.absolute.path, _archiveName));
    await _installMinGitIfNeeded();
    await _populateCaches();
    await _archiveFiles(_outputFile);
    return _outputFile;
  }

  /// Returns the version number of this release, according the to tags in the
  /// repo.
  ///
  /// This looks for the tag attached to [revision] and, if it doesn't find one,
  /// git will give an error.
  ///
  /// If [strict] is true, the exact [revision] must be tagged to return the
  /// version.  If [strict] is not true, will look backwards in time starting at
  /// [revision] to find the most recent version tag.
  Future<String> _getVersion() async {
    if (strict) {
      try {
        return _runGit(<String>['describe', '--tags', '--exact-match', revision]);
      } on PreparePackageException catch (exception) {
        throw PreparePackageException(
          'Git error when checking for a version tag attached to revision $revision.\n'
          'Perhaps there is no tag at that revision?:\n'
          '$exception'
        );
      }
    } else {
      return _runGit(<String>['describe', '--tags', '--abbrev=0', revision]);
    }
  }

  /// Clone the Flutter repo and make sure that the git environment is sane
  /// for when the user will unpack it.
  Future<void> _checkoutFlutter() async {
    // We want the user to start out the in the specified branch instead of a
    // detached head. To do that, we need to make sure the branch points at the
    // desired revision.
    await _runGit(<String>['clone', '-b', branchName, chromiumRepo], workingDirectory: tempDir);
    await _runGit(<String>['reset', '--hard', revision]);

    // Make the origin point to github instead of the chromium mirror.
    await _runGit(<String>['remote', 'set-url', 'origin', githubRepo]);
  }

  /// Retrieve the MinGit executable from storage and unpack it.
  Future<void> _installMinGitIfNeeded() async {
    if (!platform.isWindows) {
      return;
    }
    final Uint8List data = await httpReader(_minGitUri);
    final File gitFile = File(path.join(tempDir.absolute.path, 'mingit.zip'));
    await gitFile.writeAsBytes(data, flush: true);

    final Directory minGitPath = Directory(path.join(flutterRoot.absolute.path, 'bin', 'mingit'));
    await minGitPath.create(recursive: true);
    await _unzipArchive(gitFile, workingDirectory: minGitPath);
  }

  /// Prepare the archive repo so that it has all of the caches warmed up and
  /// is configured for the user to begin working.
  Future<void> _populateCaches() async {
    await _runFlutter(<String>['doctor']);
    await _runFlutter(<String>['update-packages']);
    await _runFlutter(<String>['precache']);
    await _runFlutter(<String>['ide-config']);

    // Create each of the templates, since they will call 'pub get' on
    // themselves when created, and this will warm the cache with their
    // dependencies too.
    for (final String template in <String>['app', 'package', 'plugin']) {
      final String createName = path.join(tempDir.path, 'create_$template');
      await _runFlutter(
        <String>['create', '--template=$template', createName],
        // Run it outside the cloned Flutter repo to not nest git repos, since
        // they'll be git repos themselves too.
        workingDirectory: tempDir,
      );
    }

    // Yes, we could just skip all .packages files when constructing
    // the archive, but some are checked in, and we don't want to skip
    // those.
    await _runGit(<String>[
      'clean',
      '-f',
      // Do not -X as it could lead to entire bin/cache getting cleaned
      '-x',
      '--',
      '**/.packages',
    ]);
    /// Remove package_config files and any contents in .dart_tool
    await _runGit(<String>[
      'clean',
      '-f',
      '-x',
      '--',
      '**/.dart_tool/',
    ]);

    // Ensure the above commands do not clean out the cache
    final Directory flutterCache = Directory(path.join(flutterRoot.absolute.path, 'bin', 'cache'));
    if (!flutterCache.existsSync()) {
      throw Exception('The flutter cache was not found at ${flutterCache.path}!');
    }

    /// Remove git subfolder from .pub-cache, this contains the flutter goldens
    /// and new flutter_gallery.
    final Directory gitCache = Directory(path.join(flutterRoot.absolute.path, '.pub-cache', 'git'));
    if (gitCache.existsSync()) {
      gitCache.deleteSync(recursive: true);
    }
  }

  /// Write the archive to the given output file.
  Future<void> _archiveFiles(File outputFile) async {
    if (outputFile.path.toLowerCase().endsWith('.zip')) {
      await _createZipArchive(outputFile, flutterRoot);
    } else if (outputFile.path.toLowerCase().endsWith('.tar.xz')) {
      await _createTarArchive(outputFile, flutterRoot);
    }
  }

  Future<String> _runFlutter(List<String> args, {Directory workingDirectory}) {
    return _processRunner.runProcess(
      <String>[_flutter, ...args],
      workingDirectory: workingDirectory ?? flutterRoot,
    );
  }

  Future<String> _runGit(List<String> args, {Directory workingDirectory}) {
    return _processRunner.runProcess(
      <String>['git', ...args],
      workingDirectory: workingDirectory ?? flutterRoot,
    );
  }

  /// Unpacks the given zip file into the currentDirectory (if set), or the
  /// same directory as the archive.
  Future<String> _unzipArchive(File archive, {Directory workingDirectory}) {
    workingDirectory ??= Directory(path.dirname(archive.absolute.path));
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
  Future<String> _createZipArchive(File output, Directory source) async {
    List<String> commandLine;
    if (platform.isWindows) {
      // Unhide the .git folder, https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/attrib.
      await _processRunner.runProcess(
        <String>['attrib', '-h', '.git'],
        workingDirectory: Directory(source.absolute.path),
      );
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
        '--symlinks',
        output.absolute.path,
        path.basename(source.path),
      ];
    }
    return _processRunner.runProcess(
      commandLine,
      workingDirectory: Directory(path.dirname(source.absolute.path)),
    );
  }

  /// Create a tar archive from the directory source.
  Future<String> _createTarArchive(File output, Directory source) {
    return _processRunner.runProcess(<String>[
      'tar',
      'cJf',
      output.absolute.path,
      path.basename(source.absolute.path),
    ], workingDirectory: Directory(path.dirname(source.absolute.path)));
  }
}

class ArchivePublisher {
  ArchivePublisher(
    this.tempDir,
    this.revision,
    this.branch,
    this.version,
    this.outputFile,
    this.dryRun, {
    ProcessManager processManager,
    bool subprocessOutput = true,
    this.platform = const LocalPlatform(),
  })  : assert(revision.length == 40),
        platformName = platform.operatingSystem.toLowerCase(),
        metadataGsPath = '$newGsReleaseFolder/${getMetadataFilename(platform)}',
        _processRunner = ProcessRunner(
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
  final bool dryRun;
  String get branchName => getBranchName(branch);
  String get destinationArchivePath => '$branchName/$platformName/${path.basename(outputFile.path)}';
  static String getMetadataFilename(Platform platform) => 'releases_${platform.operatingSystem.toLowerCase()}.json';

  Future<String> _getChecksum(File archiveFile) async {
    final DigestSink digestSink = DigestSink();
    final ByteConversionSink sink = sha256.startChunkedConversion(digestSink);

    final Stream<List<int>> stream = archiveFile.openRead();
    await stream.forEach((List<int> chunk) {
      sink.add(chunk);
    });
    sink.close();
    return digestSink.value.toString();
  }

  /// Publish the archive to Google Storage.
  ///
  /// This method will throw if the target archive already exists on cloud
  /// storage.
  Future<void> publishArchive([bool forceUpload = false]) async {
    for (final String releaseFolder in <String>[oldGsReleaseFolder, newGsReleaseFolder]) {
      final String destGsPath = '$releaseFolder/$destinationArchivePath';
      if (!forceUpload) {
        if (await _cloudPathExists(destGsPath) && !dryRun) {
          throw PreparePackageException(
            'File $destGsPath already exists on cloud storage!',
          );
        }
      }
      await _cloudCopy(
        src: outputFile.absolute.path,
        dest: destGsPath,
      );
      assert(tempDir.existsSync());
      await _updateMetadata('$releaseFolder/${getMetadataFilename(platform)}', newBucket: false);
    }
  }

  Future<Map<String, dynamic>> _addRelease(Map<String, dynamic> jsonData, {bool newBucket=true}) async {
    final String tmpBaseUrl = newBucket ? newBaseUrl : oldBaseUrl;
    jsonData['base_url'] = '$tmpBaseUrl$releaseFolder';
    if (!jsonData.containsKey('current_release')) {
      jsonData['current_release'] = <String, String>{};
    }
    jsonData['current_release'][branchName] = revision;
    if (!jsonData.containsKey('releases')) {
      jsonData['releases'] = <Map<String, dynamic>>[];
    }

    final Map<String, dynamic> newEntry = <String, dynamic>{};
    newEntry['hash'] = revision;
    newEntry['channel'] = branchName;
    newEntry['version'] = version;
    newEntry['release_date'] = DateTime.now().toUtc().toIso8601String();
    newEntry['archive'] = destinationArchivePath;
    newEntry['sha256'] = await _getChecksum(outputFile);

    // Search for any entries with the same hash and channel and remove them.
    final List<dynamic> releases = jsonData['releases'] as List<dynamic>;
    jsonData['releases'] = <Map<String, dynamic>>[
      for (final Map<String, dynamic> entry in releases.cast<Map<String, dynamic>>())
        if (entry['hash'] != newEntry['hash'] || entry['channel'] != newEntry['channel'])
          entry,
      newEntry,
    ]..sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime aDate = DateTime.parse(a['release_date'] as String);
      final DateTime bDate = DateTime.parse(b['release_date'] as String);
      return bDate.compareTo(aDate);
    });
    return jsonData;
  }

  Future<void> _updateMetadata(String gsPath, {bool newBucket=true}) async {
    // We can't just cat the metadata from the server with 'gsutil cat', because
    // Windows wants to echo the commands that execute in gsutil.bat to the
    // stdout when we do that. So, we copy the file locally and then read it
    // back in.
    final File metadataFile = File(
      path.join(tempDir.absolute.path, getMetadataFilename(platform)),
    );
    await _runGsUtil(<String>['cp', gsPath, metadataFile.absolute.path]);
    if (!dryRun) {
      final String currentMetadata = metadataFile.readAsStringSync();
      if (currentMetadata.isEmpty) {
        throw PreparePackageException('Empty metadata received from server');
      }

      Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(currentMetadata) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw PreparePackageException('Unable to parse JSON metadata received from cloud: $e');
      }

      jsonData = await _addRelease(jsonData, newBucket: newBucket);

      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      metadataFile.writeAsStringSync(encoder.convert(jsonData));
    }
    await _cloudCopy(
      src: metadataFile.absolute.path,
      dest: gsPath,
      // This metadata file is used by the website, so we don't want a long
      // latency between publishing a release and it being available on the
      // site.
      cacheSeconds: shortCacheSeconds,
    );
  }

  Future<String> _runGsUtil(
    List<String> args, {
    Directory workingDirectory,
    bool failOk = false,
  }) async {
    if (dryRun) {
      print('gsutil.py -- $args');
      return '';
    }
    if (platform.isWindows) {
      return _processRunner.runProcess(
        <String>['python', path.join(platform.environment['DEPOT_TOOLS'], 'gsutil.py'), '--', ...args],
        workingDirectory: workingDirectory,
        failOk: failOk,
      );
    }

    return _processRunner.runProcess(
      <String>['gsutil.py', '--', ...args],
      workingDirectory: workingDirectory,
      failOk: failOk,
    );
  }

  /// Determine if a file exists at a given [cloudPath].
  Future<bool> _cloudPathExists(String cloudPath) async {
    try {
      await _runGsUtil(
        <String>['stat', cloudPath],
        failOk: false,
      );
    } on PreparePackageException {
      // `gsutil stat gs://path/to/file` will exit with 1 if file does not exist
      return false;
    }
    return true;
  }

  Future<String> _cloudCopy({
    @required String src,
    @required String dest,
    int cacheSeconds,
  }) async {
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
    return _runGsUtil(<String>[
      // Use our preferred MIME type for the files we care about
      // and let gsutil figure it out for anything else.
      if (mimeType != null) ...<String>['-h', 'Content-Type:$mimeType'],
      if (cacheSeconds != null) ...<String>['-h', 'Cache-Control:max-age=$cacheSeconds'],
      'cp',
      src,
      dest,
    ]);
  }
}

/// Prepares a flutter git repo to be packaged up for distribution.
/// It mainly serves to populate the .pub-cache with any appropriate Dart
/// packages, and the flutter cache in bin/cache with the appropriate
/// dependencies and snapshots.
///
/// Archives contain the executables and customizations for the platform that
/// they are created on.
Future<void> main(List<String> rawArguments) async {
  final ArgParser argParser = ArgParser();
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
    allowed: Branch.values.map<String>((Branch branch) => getBranchName(branch)),
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
        'directory: $newBaseUrl$releaseFolder',
  );
  argParser.addFlag(
    'force',
    abbr: 'f',
    defaultsTo: false,
    help: 'Overwrite a previously uploaded package.',
  );
  argParser.addFlag(
    'dry_run',
    defaultsTo: false,
    negatable: false,
    help: 'Prints gsutil commands instead of executing them.',
  );
  argParser.addFlag(
    'help',
    defaultsTo: false,
    negatable: false,
    help: 'Print help for this command.',
  );

  final ArgResults parsedArguments = argParser.parse(rawArguments);

  if (parsedArguments['help'] as bool) {
    print(argParser.usage);
    exit(0);
  }

  void errorExit(String message, {int exitCode = -1}) {
    stderr.write('Error: $message\n\n');
    stderr.write('${argParser.usage}\n');
    exit(exitCode);
  }

  final String revision = parsedArguments['revision'] as String;
  if (!parsedArguments.wasParsed('revision')) {
    errorExit('Invalid argument: --revision must be specified.');
  }
  if (revision.length != 40) {
    errorExit('Invalid argument: --revision must be the entire hash, not just a prefix.');
  }

  if (!parsedArguments.wasParsed('branch')) {
    errorExit('Invalid argument: --branch must be specified.');
  }

  final String tempDirArg = parsedArguments['temp_dir'] as String;
  Directory tempDir;
  bool removeTempDir = false;
  if (tempDirArg == null || tempDirArg.isEmpty) {
    tempDir = Directory.systemTemp.createTempSync('flutter_package.');
    removeTempDir = true;
  } else {
    tempDir = Directory(tempDirArg);
    if (!tempDir.existsSync()) {
      errorExit("Temporary directory $tempDirArg doesn't exist.");
    }
  }

  Directory outputDir;
  if (parsedArguments['output'] == null) {
    outputDir = tempDir;
  } else {
    outputDir = Directory(parsedArguments['output'] as String);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
  }

  final Branch branch = fromBranchName(parsedArguments['branch'] as String);
  final ArchiveCreator creator = ArchiveCreator(tempDir, outputDir, revision, branch, strict: parsedArguments['publish'] as bool);
  int exitCode = 0;
  String message;
  try {
    final String version = await creator.initializeRepo();
    final File outputFile = await creator.createArchive();
    if (parsedArguments['publish'] as bool) {
      final ArchivePublisher publisher = ArchivePublisher(
        tempDir,
        revision,
        branch,
        version,
        outputFile,
        parsedArguments['dry_run'] as bool,
      );
      await publisher.publishArchive(parsedArguments['force'] as bool);
    }
  } on PreparePackageException catch (e) {
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

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto/src/digest_sink.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart' show LocalPlatform, Platform;
import 'package:process/process.dart';

import 'prepare_package/archive_creator.dart';
import 'prepare_package/common.dart';
import 'prepare_package/process_runner.dart';

class ArchivePublisher {
  ArchivePublisher(
    this.tempDir,
    this.revision,
    this.branch,
    this.version,
    this.outputFile,
    this.dryRun, {
    ProcessManager? processManager,
    bool subprocessOutput = true,
    this.platform = const LocalPlatform(),
  })  : assert(revision.length == 40),
        platformName = platform.operatingSystem.toLowerCase(),
        metadataGsPath = '$gsReleaseFolder/${getMetadataFilename(platform)}',
        _processRunner = ProcessRunner(
          processManager: processManager,
          subprocessOutput: subprocessOutput,
        );

  final Platform platform;
  final String platformName;
  final String metadataGsPath;
  final Branch branch;
  final String revision;
  final Map<String, String> version;
  final Directory tempDir;
  final File outputFile;
  final ProcessRunner _processRunner;
  final bool dryRun;
  String get destinationArchivePath => '${branch.name}/$platformName/${path.basename(outputFile.path)}';
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
    final String destGsPath = '$gsReleaseFolder/$destinationArchivePath';
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
    final String gcsPath = '$gsReleaseFolder/${getMetadataFilename(platform)}';
    await _publishMetadata(gcsPath);
  }

  /// Downloads and updates the metadata file without publishing it.
  Future<void> generateLocalMetadata() async {
    await _updateMetadata('$gsReleaseFolder/${getMetadataFilename(platform)}');
  }

  Future<Map<String, dynamic>> _addRelease(Map<String, dynamic> jsonData) async {
    jsonData['base_url'] = '$baseUrl$releaseFolder';
    if (!jsonData.containsKey('current_release')) {
      jsonData['current_release'] = <String, String>{};
    }
    (jsonData['current_release'] as Map<String, dynamic>)[branch.name] = revision;
    if (!jsonData.containsKey('releases')) {
      jsonData['releases'] = <Map<String, dynamic>>[];
    }

    final Map<String, dynamic> newEntry = <String, dynamic>{};
    newEntry['hash'] = revision;
    newEntry['channel'] = branch.name;
    newEntry['version'] = version[frameworkVersionTag];
    newEntry['dart_sdk_version'] = version[dartVersionTag];
    newEntry['dart_sdk_arch'] = version[dartTargetArchTag];
    newEntry['release_date'] = DateTime.now().toUtc().toIso8601String();
    newEntry['archive'] = destinationArchivePath;
    newEntry['sha256'] = await _getChecksum(outputFile);

    // Search for any entries with the same hash and channel and remove them.
    final List<dynamic> releases = jsonData['releases'] as List<dynamic>;
    jsonData['releases'] = <Map<String, dynamic>>[
      for (final Map<String, dynamic> entry in releases.cast<Map<String, dynamic>>())
        if (entry['hash'] != newEntry['hash'] ||
            entry['channel'] != newEntry['channel'] ||
            entry['dart_sdk_arch'] != newEntry['dart_sdk_arch'])
          entry,
      newEntry,
    ]..sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime aDate = DateTime.parse(a['release_date'] as String);
      final DateTime bDate = DateTime.parse(b['release_date'] as String);
      return bDate.compareTo(aDate);
    });
    return jsonData;
  }

  Future<void> _updateMetadata(String gsPath) async {
    // We can't just cat the metadata from the server with 'gsutil cat', because
    // Windows wants to echo the commands that execute in gsutil.bat to the
    // stdout when we do that. So, we copy the file locally and then read it
    // back in.
    final File metadataFile = File(
      path.join(tempDir.absolute.path, getMetadataFilename(platform)),
    );
    await _runGsUtil(<String>['cp', gsPath, metadataFile.absolute.path]);
    Map<String, dynamic> jsonData = <String, dynamic>{};
    if (!dryRun) {
      final String currentMetadata = metadataFile.readAsStringSync();
      if (currentMetadata.isEmpty) {
        throw PreparePackageException('Empty metadata received from server');
      }
      try {
        jsonData = json.decode(currentMetadata) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw PreparePackageException('Unable to parse JSON metadata received from cloud: $e');
      }
    }
    // Run _addRelease, even on a dry run, so we can inspect the metadata on a
    // dry run. On a dry run, the only thing in the metadata file be the new
    // release.
    jsonData = await _addRelease(jsonData);

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    metadataFile.writeAsStringSync(encoder.convert(jsonData));
  }

  /// Publishes the metadata file to GCS.
  Future<void> _publishMetadata(String gsPath) async {
    final File metadataFile = File(
      path.join(tempDir.absolute.path, getMetadataFilename(platform)),
    );
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
    Directory? workingDirectory,
    bool failOk = false,
  }) async {
    if (dryRun) {
      print('gsutil.py -- $args');
      return '';
    }
    return _processRunner.runProcess(
      <String>['python3', path.join(platform.environment['DEPOT_TOOLS']!, 'gsutil.py'), '--', ...args],
      workingDirectory: workingDirectory,
      failOk: failOk,
    );
  }

  /// Determine if a file exists at a given [cloudPath].
  Future<bool> _cloudPathExists(String cloudPath) async {
    try {
      await _runGsUtil(
        <String>['stat', cloudPath],
      );
    } on PreparePackageException {
      // `gsutil stat gs://path/to/file` will exit with 1 if file does not exist
      return false;
    }
    return true;
  }

  Future<String> _cloudCopy({
    required String src,
    required String dest,
    int? cacheSeconds,
  }) async {
    // We often don't have permission to overwrite, but
    // we have permission to remove, so that's what we do.
    await _runGsUtil(<String>['rm', dest], failOk: true);
    String? mimeType;
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

/// Prepares a flutter git repo to be packaged up for distribution. It mainly
/// serves to populate the .pub-preload-cache with any appropriate Dart
/// packages, and the flutter cache in bin/cache with the appropriate
/// dependencies and snapshots.
///
/// Archives contain the executables and customizations for the platform that
/// they are created on.
Future<void> main(List<String> rawArguments) async {
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    'temp_dir',
    help: 'A location where temporary files may be written. Defaults to a '
        'directory in the system temp folder. Will write a few GiB of data, '
        'so it should have sufficient free space. If a temp_dir is not '
        'specified, then the default temp_dir will be created, used, and '
        'removed automatically.',
  );
  argParser.addOption('revision',
      help: 'The Flutter git repo revision to build the '
          'archive with. Must be the full 40-character hash. Required.');
  argParser.addOption(
    'branch',
    allowed: Branch.values.map<String>((Branch branch) => branch.name),
    help: 'The Flutter branch to build the archive with. Required.',
  );
  argParser.addOption(
    'output',
    help: 'The path to the directory where the output archive should be '
        'written. If --output is not specified, the archive will be written to '
        "the current directory. If the output directory doesn't exist, it, and "
        'the path to it, will be created.',
  );
  argParser.addFlag(
    'publish',
    help: 'If set, will publish the archive to Google Cloud Storage upon '
        'successful creation of the archive. Will publish under this '
        'directory: $baseUrl$releaseFolder',
  );
  argParser.addFlag(
    'force',
    abbr: 'f',
    help: 'Overwrite a previously uploaded package.',
  );
  argParser.addFlag(
    'dry_run',
    negatable: false,
    help: 'Prints gsutil commands instead of executing them.',
  );
  argParser.addFlag(
    'help',
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

  if (!parsedArguments.wasParsed('revision')) {
    errorExit('Invalid argument: --revision must be specified.');
  }
  final String revision = parsedArguments['revision'] as String;
  if (revision.length != 40) {
    errorExit('Invalid argument: --revision must be the entire hash, not just a prefix.');
  }

  if (!parsedArguments.wasParsed('branch')) {
    errorExit('Invalid argument: --branch must be specified.');
  }

  final String? tempDirArg = parsedArguments['temp_dir'] as String?;
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

  final bool publish = parsedArguments['publish'] as bool;
  final bool dryRun = parsedArguments['dry_run'] as bool;
  final Branch branch = Branch.values.byName(parsedArguments['branch'] as String);
  final ArchiveCreator creator = ArchiveCreator(
    tempDir,
    outputDir,
    revision,
    branch,
    strict: publish && !dryRun,
  );
  int exitCode = 0;
  late String message;
  try {
    final Map<String, String> version = await creator.initializeRepo();
    final File outputFile = await creator.createArchive();
    final ArchivePublisher publisher = ArchivePublisher(
      tempDir,
      revision,
      branch,
      version,
      outputFile,
      dryRun,
    );
    await publisher.generateLocalMetadata();
    if (parsedArguments['publish'] as bool) {
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

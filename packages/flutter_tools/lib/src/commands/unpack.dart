// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

/// The directory in the Flutter cache for each platform's artifacts.
const Map<TargetPlatform, String> flutterArtifactPlatformDirectory =
    <TargetPlatform, String>{
  TargetPlatform.linux_x64: 'linux-x64',
  TargetPlatform.darwin_x64: 'darwin-x64',
  TargetPlatform.windows_x64: 'windows-x64',
};

// TODO(jonahwilliams): this should come from a configuration in each build
// directory.
const Map<TargetPlatform, List<String>> artifactFilesByPlatform = <TargetPlatform, List<String>>{
  TargetPlatform.linux_x64: <String>[
    'libflutter_linux_glfw.so',
    'flutter_export.h',
    'flutter_messenger.h',
    'flutter_plugin_registrar.h',
    'flutter_glfw.h',
    'icudtl.dat',
    'cpp_client_wrapper_glfw/',
  ],
  TargetPlatform.darwin_x64: <String>[
    'FlutterMacOS.framework',
  ],
  TargetPlatform.windows_x64: <String>[
    'flutter_windows.dll',
    'flutter_windows.dll.exp',
    'flutter_windows.dll.lib',
    'flutter_windows.dll.pdb',
    'flutter_export.h',
    'flutter_messenger.h',
    'flutter_plugin_registrar.h',
    'flutter_windows.h',
    'icudtl.dat',
    'cpp_client_wrapper/',
  ],
};

/// Copies desktop artifacts to local cache directories.
class UnpackCommand extends FlutterCommand {
  UnpackCommand() {
    argParser.addOption(
      'target-platform',
      allowed: <String>['darwin-x64', 'linux-x64', 'windows-x64'],
    );
    argParser.addOption('cache-dir',
        help: 'Location to output platform specific artifacts.');
  }

  @override
  String get description => 'unpack desktop artifacts';

  @override
  String get name => 'unpack';

  @override
  bool get hidden => true;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    final Set<DevelopmentArtifact> result = <DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    };
    final TargetPlatform targetPlatform = getTargetPlatformForName(argResults['target-platform']);
    switch (targetPlatform) {
      case TargetPlatform.darwin_x64:
        result.add(DevelopmentArtifact.macOS);
        break;
      case TargetPlatform.windows_x64:
        result.add(DevelopmentArtifact.windows);
        break;
      case TargetPlatform.linux_x64:
        result.add(DevelopmentArtifact.linux);
        break;
      default:
    }
    return result;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetName = argResults['target-platform'];
    final String targetDirectory = argResults['cache-dir'];
    if (!fs.directory(targetDirectory).existsSync()) {
      fs.directory(targetDirectory).createSync(recursive: true);
    }
    final TargetPlatform targetPlatform = getTargetPlatformForName(targetName);
    final ArtifactUnpacker flutterArtifactFetcher = ArtifactUnpacker(targetPlatform);
    bool success = true;
    if (artifacts is LocalEngineArtifacts) {
      final LocalEngineArtifacts localEngineArtifacts = artifacts;
      success = flutterArtifactFetcher.copyLocalBuildArtifacts(
        localEngineArtifacts.engineOutPath,
        targetDirectory,
      );
    } else {
      success = flutterArtifactFetcher.copyCachedArtifacts(
        targetDirectory,
      );
    }
    if (!success) {
      throwToolExit('Failed to unpack desktop artifacts.');
    }
    return null;
  }
}

/// Manages the copying of cached or locally built Flutter artifacts, including
/// tracking the last-copied versions and updating only if necessary.
class ArtifactUnpacker {
  /// Creates a new fetcher for the given configuration.
  const ArtifactUnpacker(this.platform);

  /// The platform to copy artifacts for.
  final TargetPlatform platform;

  /// Checks [targetDirectory] to see if artifacts have already been copied for
  /// the current hash, and if not, copies the artifacts for [platform] from the
  /// Flutter cache (after ensuring that the cache is present).
  ///
  /// Returns true if the artifacts were successfully copied, or were already
  /// present with the correct hash.
  bool copyCachedArtifacts(String targetDirectory) {
    String cacheStamp;
    switch (platform) {
      case TargetPlatform.linux_x64:
        cacheStamp = 'linux-sdk';
        break;
      case TargetPlatform.windows_x64:
        cacheStamp = 'windows-sdk';
        break;
      case TargetPlatform.darwin_x64:
        cacheStamp = 'macos-sdk';
        break;
      default:
        throwToolExit('Unsupported target platform: $platform');
    }
    final String targetHash =
        readHashFileIfPossible(Cache.instance.getStampFileFor(cacheStamp));
    if (targetHash == null) {
      printError('Failed to find engine stamp file');
      return false;
    }

    try {
      final String currentHash = _lastCopiedHash(targetDirectory);
      if (currentHash == null || targetHash != currentHash) {
        // Copy them to the target directory.
        final String flutterCacheDirectory = fs.path.join(
          Cache.flutterRoot,
          'bin',
          'cache',
          'artifacts',
          'engine',
          flutterArtifactPlatformDirectory[platform],
        );
        if (!_copyArtifactFiles(flutterCacheDirectory, targetDirectory)) {
          return false;
        }
        _setLastCopiedHash(targetDirectory, targetHash);
        printTrace('Copied artifacts for version $targetHash.');
      } else {
        printTrace('Artifacts for version $targetHash already present.');
      }
    } catch (error, stackTrace) {
      printError(stackTrace.toString());
      printError(error.toString());
      return false;
    }
    return true;
  }

  /// Acts like [copyCachedArtifacts], replacing the artifacts and updating
  /// the version stamp, except that it pulls the artifact from a local engine
  /// build with the given [buildConfiguration] (e.g., host_debug_unopt) whose
  /// checkout is rooted at [engineRoot].
  bool copyLocalBuildArtifacts(String buildOutput, String targetDirectory) {
    if (!_copyArtifactFiles(buildOutput, targetDirectory)) {
      return false;
    }

    // Update the hash file to indicate that it's a local build, so that it's
    // obvious where it came from.
    _setLastCopiedHash(targetDirectory, 'local build: $buildOutput');

    return true;
  }

  /// Copies the artifact files for [platform] from [sourceDirectory] to
  /// [targetDirectory].
  bool _copyArtifactFiles(String sourceDirectory, String targetDirectory) {
    final List<String> artifactFiles = artifactFilesByPlatform[platform];
    if (artifactFiles == null) {
      printError('Unsupported platform: $platform.');
      return false;
    }

    try {
      fs.directory(targetDirectory).createSync(recursive: true);

      // On macOS, delete the existing framework if any before copying in the
      // new one, since it's a directory. On the other platforms, where files
      // are just individual files, this isn't necessary since copying over
      // existing files will do the right thing.
      if (platform == TargetPlatform.darwin_x64) {
        _copyMacOSFramework(
            fs.path.join(sourceDirectory, artifactFiles[0]), targetDirectory);
      } else {
        for (final String entityName in artifactFiles) {
          final String sourcePath = fs.path.join(sourceDirectory, entityName);
          final String targetPath = fs.path.join(targetDirectory, entityName);
          if (entityName.endsWith('/')) {
            copyDirectorySync(
              fs.directory(sourcePath),
              fs.directory(targetPath),
            );
          } else {
            fs.file(sourcePath)
              .copySync(fs.path.join(targetDirectory, entityName));
          }
        }
      }

      printTrace('Copied artifacts from $sourceDirectory.');
    } catch (e, stackTrace) {
      printError(stackTrace.toString());
      printError(e.message);
      return false;
    }
    return true;
  }

  /// Returns a File object for the file containing the last copied hash
  /// in [directory].
  File _lastCopiedHashFile(String directory) {
    return fs.file(fs.path.join(directory, '.last_artifact_version'));
  }

  /// Returns the hash of the artifacts last copied to [directory], or null if
  /// they haven't been copied.
  String _lastCopiedHash(String directory) {
    // Sanity check that at least one file is present; this won't catch every
    // case, but handles someone deleting all the non-hidden cached files to
    // force fresh copy.
    final String artifactFilePath = fs.path.join(
      directory,
      artifactFilesByPlatform[platform].first,
    );
    if (!fs.file(artifactFilePath).existsSync()) {
      return null;
    }
    final File hashFile = _lastCopiedHashFile(directory);
    return readHashFileIfPossible(hashFile);
  }

  /// Writes [hash] to the file that stores the last copied hash for
  /// in [directory].
  void _setLastCopiedHash(String directory, String hash) {
    _lastCopiedHashFile(directory).writeAsStringSync(hash);
  }

  /// Copies the framework at [frameworkPath] to [targetDirectory]
  /// by invoking 'cp -R'.
  ///
  /// The shelling out is done to avoid complications with preserving special
  /// files (e.g., symbolic links) in the framework structure.
  ///
  /// Removes any previous version of the framework that already exists in the
  /// target directory.
  void _copyMacOSFramework(String frameworkPath, String targetDirectory) {
    _deleteFrameworkIfPresent(
        fs.path.join(targetDirectory, fs.path.basename(frameworkPath)));

    final RunResult result = processUtils
        .runSync(<String>['cp', '-R', frameworkPath, targetDirectory]);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to copy framework (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}',
      );
    }
  }

  /// Recursively deletes the framework at [frameworkPath], if it exists.
  void _deleteFrameworkIfPresent(String frameworkPath) {
    // Ensure that the path is a framework, to minimize the potential for
    // catastrophic deletion bugs with bad arguments.
    if (fs.path.extension(frameworkPath) != '.framework') {
      throw Exception(
          'Attempted to delete a non-framework directory: $frameworkPath');
    }

    final Directory directory = fs.directory(frameworkPath);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  /// Returns the engine hash from [file] as a String, or null.
  ///
  /// If the file is missing, or cannot be read, returns null.
  String readHashFileIfPossible(File file) {
    if (!file.existsSync()) {
      return null;
    }
    try {
      return file.readAsStringSync().trim();
    } on FileSystemException {
      // If the file can't be read for any reason, just treat it as missing.
      return null;
    }
  }
}

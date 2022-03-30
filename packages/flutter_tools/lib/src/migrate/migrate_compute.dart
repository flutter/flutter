// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../cache.dart';
import '../commands/migrate.dart';
import '../flutter_project_metadata.dart';
import '../project.dart';
import '../version.dart';
import 'custom_merge.dart';
import 'migrate_manifest.dart';
import 'migrate_utils.dart';

/// Defines available merge techniques.
enum MergeType {
  threeWay,
  twoWay,
}

// This defines files and directories that should be skipped regardless
// of gitignore and config settings
const List<String> _skippedFiles = <String>[
  'lib/main.dart',
  'ios/Runner.xcodeproj/project.pbxproj',
  'README.md', // changes to this shouldn't be overwritten since is is user owned.
];

const List<String> _skippedDirectories = <String>[
  '.dart_tool', // ignore the .dart_tool generated dir
  '.git', // ignore the git metadata
  'lib', // Files here are always user owned and we don't want to overwrite their apps.
  'test', // Files here are typically user owned and flutter-side changes are not relevant.
  'assets', // Common directory for user assets.
];

bool _skipped(String localPath) {
  if (_skippedFiles.contains(localPath)) {
    return true;
  }
  for (final String dir in _skippedDirectories) {
    if (localPath.startsWith('$dir/')) {
      return true;
    }
  }
  return false;
}

const List<String> _skippedMergeFileExt = <String>[
  // Don't merge image files
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
];

/// True for files that should not be merged. Typically, images and binary files.
bool _skippedMerge(String localPath) {
  for (final String ext in _skippedMergeFileExt) {
    if (localPath.endsWith(ext)) {
      return true;
    }
  }
  return false;
}

/// Stores a file that has been marked for migraton and metadata about the file.
class FilePendingMigration {
  FilePendingMigration(this.localPath, this.file);
  String localPath;
  File file;
}

/// Data class that holds all results and generated directories from a computeMigration run.
///
/// mergeResults, addedFiles, and deletedFiles includes the sets of files to be migrated while
/// the other members track the temporary sdk and generated app directories created by the tool.
///
/// The compute function does not clean up the temp directories, as the directories may be reused,
/// so this must be done manually afterwards.
class MigrateResult {
  MigrateResult({
    required this.mergeResults,
    required this.addedFiles,
    required this.deletedFiles,
    required this.tempDirectories,
    required this.sdkDirs,
    required this.mergeTypeMap,
    required this.diffMap,
    this.generatedBaseTemplateDirectory,
    this.generatedTargetTemplateDirectory});

  /// Creates a MigrateResult with all empty members.
  MigrateResult.empty()
    : mergeResults = <MergeResult>[],
      addedFiles = <FilePendingMigration>[],
      deletedFiles = <FilePendingMigration>[],
      tempDirectories = <Directory>[],
      mergeTypeMap = <String, MergeType>{},
      diffMap = <String, DiffResult>{},
      sdkDirs = <String, Directory>{};

  final List<MergeResult> mergeResults;
  final List<FilePendingMigration> addedFiles;
  final List<FilePendingMigration> deletedFiles;
  final List<Directory> tempDirectories;
  final Map<String, MergeType> mergeTypeMap;
  final Map<String, DiffResult> diffMap;
  Directory? generatedBaseTemplateDirectory;
  Directory? generatedTargetTemplateDirectory;
  Map<String, Directory> sdkDirs;
}

/// Computes the changes that migrates the current flutter project to the target revision.
///
/// This method attempts to find a base revision, which is the revision of the Flutter SDK
/// the app was generated with or the last revision the app was migrated to. The base revision
/// typically comes from the .metadata, but for legacy apps, the config may not exist. In
/// this case, we fallback to using the revision in .metadata, and if that does not exist, we
/// use the target revision as the base revision. In the final fallback case, the migration should
/// still work, but will likely generate slightly less accurate merges.
///
/// Operations the computation performs:
/// 
///  - Parse .metadata file
///  - Collect revisions to use for each platform
///  - Download each flutter revision and call `flutter create` for each.
///  - Call `flutter create` with target revision (target is typically current flutter version)
///  - Diff base revision generated app with target revision generated app
///  - Compute all newly added files between base and target revisions
///  - Compute merge of all files that are modifed by user and flutter
///  - Track temp dirs to be deleted
Future<MigrateResult?> computeMigration({
    bool verbose = false,
    FlutterProject? flutterProject,
    String? baseAppPath,
    String? targetAppPath,
    String? baseRevision,
    String? targetRevision,
    bool deleteTempDirectories = true,
    List<SupportedPlatform>? platforms,
    bool preferTwoWayMerge = false,
    required FileSystem fileSystem,
    required Logger logger,
  }) async {
  flutterProject ??= FlutterProject.current();

  logger.printStatus('Computing migration - this command may take a while to complete.');
  // We keep a spinner going and print periodic progress messages
  // to assure the developer that the command is still working due to
  // the long expected runtime.
  final Status status = logger.startSpinner();
  status.pause();
  logger.printStatus('Obtaining revisions.', indent: 2, color: TerminalColor.grey);
  status.resume();

  final FlutterProjectMetadata metadata = FlutterProjectMetadata(flutterProject.directory.childFile('.metadata'), logger);
  final MigrateConfig config = metadata.migrateConfig;

  // We call populate in case MigrateConfig is empty. If it is filled, populate should not do anything.
  config.populate(
    projectDirectory: flutterProject.directory,
    logger: logger,
  );
  final FlutterVersion version = FlutterVersion(workingDirectory: flutterProject.directory.absolute.path);
  final String fallbackRevision = getFallbackBaseRevision(metadata, version);
  targetRevision ??= version.frameworkRevision;
  String rootBaseRevision = '';
  final Map<String, List<MigratePlatformConfig>> revisionToConfigs = <String, List<MigratePlatformConfig>>{};
  final Set<String> revisions = <String>{};
  if (baseRevision == null) {
    for (final MigratePlatformConfig platform in config.platformConfigs.values) {
      final String effectiveRevision = platform.baseRevision == null ? fallbackRevision : platform.baseRevision!;
      if (platforms != null && !platforms.contains(platform.platform)) {
        continue;
      }
      if (platform.platform == SupportedPlatform.root) {
        rootBaseRevision = effectiveRevision;
      }
      revisions.add(effectiveRevision);
      if (revisionToConfigs[effectiveRevision] == null) {
        revisionToConfigs[effectiveRevision] = <MigratePlatformConfig>[];
      }
      revisionToConfigs[effectiveRevision]!.add(platform);
    }
  } else {
    rootBaseRevision = baseRevision;
  }
  // Reorder such that the root revision is created first.
  revisions.remove(rootBaseRevision);
  final List<String> revisionsList = List<String>.from(revisions);
  if (rootBaseRevision != '') {
    revisionsList.insert(0, rootBaseRevision);
  }
  if (verbose) {
    logger.printStatus('Potential base revisions: $revisionsList');
  }

  // Extract the files/paths that should be ignored by the migrate tool.
  // These paths are absolute paths.
  if (verbose) {
    logger.printStatus('Parsing unmanagedFiles.');
  }
  final List<String> unmanagedFiles = <String>[];
  final List<String> unmanagedDirectories = <String>[];
  final String basePath = flutterProject.directory.path;
  for (final String localPath in config.unmanagedFiles) {
    if (localPath.endsWith(fileSystem.path.separator)) {
      unmanagedDirectories.add(fileSystem.path.join(basePath, localPath));
    } else {
      unmanagedFiles.add(fileSystem.path.join(basePath, localPath));
    }
  }
  status.pause();
  logger.printStatus('Generating base reference app', indent: 2, color: TerminalColor.grey);
  status.resume();

  final MigrateResult migrateResult = MigrateResult.empty();

  // Generate the base templates
  final bool customBaseAppDir = baseAppPath != null;
  final bool customTargetAppDir = targetAppPath != null;
  if (customBaseAppDir) {
    migrateResult.generatedBaseTemplateDirectory = fileSystem.directory(baseAppPath);
  } else {
    migrateResult.generatedBaseTemplateDirectory = await MigrateUtils.createTempDirectory('generatedBaseTemplate');
  }
  if (customTargetAppDir) {
    migrateResult.generatedTargetTemplateDirectory = fileSystem.directory(targetAppPath);
  } else {
    migrateResult.generatedTargetTemplateDirectory = await MigrateUtils.createTempDirectory('generatedTargetTemplate');
  }

  await MigrateUtils.gitInit(migrateResult.generatedBaseTemplateDirectory!.absolute.path);
  await MigrateUtils.gitInit(migrateResult.generatedTargetTemplateDirectory!.absolute.path);

  final String name = flutterProject.manifest.appName;
  final String androidLanguage = flutterProject.android.isKotlin ? 'kotlin' : 'java';
  final String iosLanguage = flutterProject.ios.isSwift ? 'swift' : 'objc';

  final Directory targetFlutterDirectory = fileSystem.directory(Cache.flutterRoot);

  // Create the base reference vanilla app.
  //
  // This step clones the base flutter sdk, and uses it to create a new vanilla app.
  // The vanilla base app is used as part of a 3 way merge between the base app, target
  // app, and the current user-owned app.
  await createBase(
    migrateResult,
    flutterProject,
    baseAppPath,
    revisionsList,
    revisionToConfigs,
    fallbackRevision,
    targetRevision,
    name,
    androidLanguage,
    iosLanguage,
    targetFlutterDirectory,
    logger,
    fileSystem,
    status
  );

  // Create target reference app when not provided.
  //
  // This step directly calls flutter create with the target (the current installed revision)
  // flutter sdk.
  if (targetAppPath == null) {
    // Create target
    status.pause();
    logger.printStatus('Creating target app with revision $targetRevision.', indent: 2, color: TerminalColor.grey);
    status.resume();
    if (verbose) {
      logger.printStatus('Creating target app.');
    }
    await MigrateUtils.createFromTemplates(
      targetFlutterDirectory.childDirectory('bin').absolute.path,
      name: name,
      androidLanguage: androidLanguage,
      iosLanguage: iosLanguage,
      outputDirectory: migrateResult.generatedTargetTemplateDirectory!.absolute.path
    );
  }

  await MigrateUtils.gitInit(flutterProject.directory.absolute.path);

  // Generate diffs. These diffs are used to determine if a file is newly added, needs merging,
  // or deleted (rare). Only files with diffs between the base and target revisions need to be
  // migrated. If files are unchanged between base and target, then there are no changes to merge.
  status.pause();
  logger.printStatus('Diffing base and target reference app.', indent: 2, color: TerminalColor.grey);
  status.resume();
  await diffBaseAndTarget(
    migrateResult,
    flutterProject,
    logger,
    verbose,
    fileSystem,
    status
  );

  // Check for any new files that were added in the target reference app that did not
  // exist in the base reference app.
  status.pause();
  logger.printStatus('Finding newly added files', indent: 2, color: TerminalColor.grey);
  status.resume();
  await computeNewlyAddedFiles(
    migrateResult,
    flutterProject,
    logger,
    verbose,
    fileSystem,
    status
  );

  // Merge any base->target changed files with the version in the developer's project.
  // Files that the developer left unchanged are fully updated to match the target reference.
  // Files that the developer changed and were changed from base->target are merged.
  status.pause();
  logger.printStatus('Merging changes with existing project.', indent: 2, color: TerminalColor.grey);
  status.resume();
  await computeMerge(
    migrateResult,
    flutterProject,
    unmanagedFiles,
    unmanagedDirectories,
    preferTwoWayMerge,
    logger,
    verbose,
    fileSystem,
    status
  );

  // Clean up any temp directories generated by this tool.
  status.pause();
  logger.printStatus('Cleaning up temp directories.', indent: 2, color: TerminalColor.grey);
  status.resume();
  if (deleteTempDirectories) {
    // Don't delete user-provided directories
    if (!customBaseAppDir) {
      migrateResult.tempDirectories.add(migrateResult.generatedBaseTemplateDirectory!);
    }
    if (!customTargetAppDir) {
      migrateResult.tempDirectories.add(migrateResult.generatedTargetTemplateDirectory!);
    }
    migrateResult.tempDirectories.addAll(migrateResult.sdkDirs.values);
  }
  status.stop();
  return migrateResult;
}

String getLocalPath(String path, String basePath, FileSystem fileSystem) {
  return path.replaceFirst(basePath + fileSystem.path.separator, '');
}

/// Returns a base revision to fallback to in case a true base revision is unknown.
String getFallbackBaseRevision(FlutterProjectMetadata metadata, FlutterVersion version) {
  if (metadata.versionRevision != null) {
    return metadata.versionRevision!;
  }
  return version.frameworkRevision;
}

/// Creates the base reference app based off of the migrate config in the .metadata file.
Future<void> createBase(
  MigrateResult migrateResult,
  FlutterProject flutterProject,
  String? baseAppPath,
  List<String> revisionsList, 
  Map<String, List<MigratePlatformConfig>> revisionToConfigs,
  String fallbackRevision,
  String targetRevision,
  String name,
  String androidLanguage,
  String iosLanguage,
  Directory targetFlutterDirectory,
  Logger logger,
  FileSystem fileSystem,
  Status status,
) async {
  // Create base
  // Clone base flutter
  if (baseAppPath == null) {
    final Map<String, Directory> revisionToFlutterSdkDir = <String, Directory>{};
    for (final String revision in revisionsList) {
      final List<String> platforms = <String>[];
      for (final MigratePlatformConfig config in revisionToConfigs[revision]!) {
        platforms.add(config.platform.toString().split('.').last);
      }
      platforms.remove('root'); // Root does not need to be listed and is not a valid platform

      // In the case of the revision being invalid or not a hash of the master branch,
      // we want to fallback in the following order:
      //   - parsed revision
      //   - fallback revision
      //   - target revision (currently installed flutter)
      late Directory sdkDir;
      final List<String> revisionsToTry = <String>[revision];
      if (revision != fallbackRevision) {
        revisionsToTry.add(fallbackRevision);
      }
      bool sdkAvailable = false;
      int index = 0;
      do {
        if (index < revisionsToTry.length) {
          final String activeRevision = revisionsToTry[index++];
          if (activeRevision != revision && revisionToFlutterSdkDir.containsKey(activeRevision)) {
            sdkDir = revisionToFlutterSdkDir[activeRevision]!;
            revisionToFlutterSdkDir[revision] = sdkDir;
            sdkAvailable = true;
          } else {
            sdkDir = await MigrateUtils.createTempDirectory('flutter_$activeRevision');
            migrateResult.sdkDirs[activeRevision] = sdkDir;
            status.pause();
            logger.printStatus('Cloning SDK $activeRevision', indent: 2, color: TerminalColor.grey);
            status.resume();
            sdkAvailable = await MigrateUtils.cloneFlutter(activeRevision, sdkDir.absolute.path);
            revisionToFlutterSdkDir[revision] = sdkDir;
          }
        } else {
          // fallback to just using the modern target version of flutter.
          sdkDir = targetFlutterDirectory;
          revisionToFlutterSdkDir[revision] = sdkDir;
          sdkAvailable = true;
        }
      } while (!sdkAvailable);
      status.pause();
      logger.printStatus('Creating base app for $platforms with revision $revision.', indent: 2, color: TerminalColor.grey);
      status.resume();
      await MigrateUtils.createFromTemplates(
        sdkDir.childDirectory('bin').absolute.path,
        name: name,
        androidLanguage: androidLanguage,
        iosLanguage: iosLanguage,
        outputDirectory: migrateResult.generatedBaseTemplateDirectory!.absolute.path,
        platforms: platforms,
      );
      // Determine merge type for each newly generated file.
      final List<FileSystemEntity> generatedBaseFiles = migrateResult.generatedBaseTemplateDirectory!.listSync(recursive: true);
      for (final FileSystemEntity entity in generatedBaseFiles) {
        if (entity is! File) {
          continue;
        }
        final File baseTemplateFile = entity.absolute;
        final String localPath = getLocalPath(baseTemplateFile.path, migrateResult.generatedBaseTemplateDirectory!.absolute.path, fileSystem);
        if (!migrateResult.mergeTypeMap.containsKey(localPath)) {
          // Use two way merge when the base revision is the same as the target revision.
          migrateResult.mergeTypeMap[localPath] = revision == targetRevision ? MergeType.twoWay : MergeType.threeWay;
        }
      }
    }
  }
}

/// Run git diff over each matching pair of files in the base reference app and target reference app.
Future<void> diffBaseAndTarget(
  MigrateResult migrateResult,
  FlutterProject flutterProject,
  Logger logger,
  bool verbose,
  FileSystem fileSystem,
  Status status
) async {
  final List<FileSystemEntity> generatedBaseFiles = migrateResult.generatedBaseTemplateDirectory!.listSync(recursive: true);
  final List<FileSystemEntity> generatedTargetFiles = migrateResult.generatedTargetTemplateDirectory!.listSync(recursive: true);
  int modifiedFilesCount = 0;
  for (final FileSystemEntity entity in generatedBaseFiles) {
    if (entity is! File) {
      continue;
    }
    final File baseTemplateFile = entity.absolute;
    final String localPath = getLocalPath(baseTemplateFile.path, migrateResult.generatedBaseTemplateDirectory!.absolute.path, fileSystem);
    if (_skipped(localPath)) {
      continue;
    }
    if (await MigrateUtils.isGitIgnored(baseTemplateFile.absolute.path, migrateResult.generatedBaseTemplateDirectory!.absolute.path)) {
      migrateResult.diffMap[localPath] = DiffResult.ignored();
    }
    final File targetTemplateFile = migrateResult.generatedTargetTemplateDirectory!.childFile(localPath);
    if (targetTemplateFile.existsSync()) {
      final DiffResult diff = await MigrateUtils.diffFiles(baseTemplateFile, targetTemplateFile);
      migrateResult.diffMap[localPath] = diff;
      if (verbose && diff.diff != '') {
        status.pause();
        logger.printStatus('Found ${diff.exitCode} changes in $localPath', indent: 4, color: TerminalColor.grey);
        status.resume();
        modifiedFilesCount++;
      }
    } else {
      // Current file has no new template counterpart, which is equivalent to a deletion.
      // This could also indicate a renaming if there is an addition with equivalent contents.
      migrateResult.diffMap[localPath] = DiffResult.deletion();
    }
  }
  if (verbose) {
    status.pause();
    logger.printStatus('$modifiedFilesCount files were modified between base and target apps.');
    status.resume();
  }
}

/// Find all files that exist in the target reference app but not in the base reference app.
Future<void> computeNewlyAddedFiles(
  MigrateResult migrateResult,
  FlutterProject flutterProject,
  Logger logger,
  bool verbose,
  FileSystem fileSystem,
  Status status
) async {
  final List<FileSystemEntity> generatedTargetFiles = migrateResult.generatedTargetTemplateDirectory!.listSync(recursive: true);
  for (final FileSystemEntity entity in generatedTargetFiles) {
    if (entity is! File) {
      continue;
    }
    final File targetTemplateFile = entity.absolute;
    final String localPath = getLocalPath(targetTemplateFile.path, migrateResult.generatedTargetTemplateDirectory!.absolute.path, fileSystem);
    if (migrateResult.diffMap.containsKey(localPath) || _skipped(localPath)) {
      continue;
    }
    if (await MigrateUtils.isGitIgnored(targetTemplateFile.absolute.path, migrateResult.generatedTargetTemplateDirectory!.absolute.path)) {
      migrateResult.diffMap[localPath] = DiffResult.ignored();
    }
    migrateResult.diffMap[localPath] = DiffResult.addition();
    migrateResult.addedFiles.add(FilePendingMigration(localPath, targetTemplateFile));
  }
  if (verbose) {
    status.pause();
    logger.printStatus('${migrateResult.addedFiles.length} files were newly added in the target app.');
    status.resume();
  }
}

/// Loops through each existing file and intelligently merges it with the base->target changes.
Future<void> computeMerge(
  MigrateResult migrateResult,
  FlutterProject flutterProject,
  List<String> unmanagedFiles,
  List<String> unmanagedDirectories,
  bool preferTwoWayMerge,
  Logger logger,
  bool verbose,
  FileSystem fileSystem,
  Status status
) async {
  final List<CustomMerge> customMerges = <CustomMerge>[
    MetadataCustomMerge(logger: logger),
  ];
  // For each existing file in the project, we attampt to 3 way merge if it is changed by the user.
  final List<FileSystemEntity> currentFiles = flutterProject.directory.listSync(recursive: true);
  final String projectRootPath = flutterProject.directory.absolute.path;
  for (final FileSystemEntity entity in currentFiles) {
    if (entity is! File) {
      continue;
    }
    // check if the file is unmanaged/ignored by the migration tool.
    bool ignored = false;
    ignored = unmanagedFiles.contains(entity.absolute.path);
    for (final String path in unmanagedDirectories) {
      if (entity.absolute.path.startsWith(path)) {
        ignored = true;
        break;
      }
    }
    if (ignored) {
      continue; // Skip if marked as unmanaged
    }

    final File currentFile = entity.absolute;
    if (!currentFile.path.startsWith(projectRootPath)) {
      continue; // Not a project file.
    }
    // Diff the current file against the old generated template
    final String localPath = getLocalPath(currentFile.path, projectRootPath, fileSystem);
    if (migrateResult.diffMap.containsKey(localPath) && migrateResult.diffMap[localPath]!.isIgnored ||
        await MigrateUtils.isGitIgnored(currentFile.path, flutterProject.directory.absolute.path) ||
        _skipped(localPath) ||
        _skippedMerge(localPath)) {
      continue;
    }
    final File baseTemplateFile = migrateResult.generatedBaseTemplateDirectory!.childFile(localPath);
    final File targetTemplateFile = migrateResult.generatedTargetTemplateDirectory!.childFile(localPath);
    final DiffResult userDiff = await MigrateUtils.diffFiles(currentFile, baseTemplateFile);
    final DiffResult targetDiff = await MigrateUtils.diffFiles(currentFile, targetTemplateFile);
    if (targetDiff.exitCode == 0) {
      // current file is already the same as the target file.
      continue;
    }

    // Current file unchanged by user, thus we consider it owned by the tool.
    if (userDiff.exitCode == 0) {
      if (migrateResult.diffMap.containsKey(localPath)) {
        // File changed between base and target
        if (migrateResult.diffMap[localPath]!.isDeletion) {
          // File is deleted in new template
          migrateResult.deletedFiles.add(FilePendingMigration(localPath, currentFile));
        }
        if (migrateResult.diffMap[localPath]!.exitCode != 0) {
          // Accept the target version wholesale
          MergeResult result;
          try {
            result = MergeResult.explicit(
              mergedString: targetTemplateFile.readAsStringSync(),
              hasConflict: false,
              exitCode: 0,
              localPath: localPath,
            );
          } on FileSystemException {
            result = MergeResult.explicit(
              mergedBytes: targetTemplateFile.readAsBytesSync(),
              hasConflict: false,
              exitCode: 0,
              localPath: localPath,
            );
          }
          migrateResult.mergeResults.add(result);
          continue;
        }
      }
      continue;
    }

    // File changed by user
    if (migrateResult.diffMap.containsKey(localPath)) {
      MergeResult? result;
      for (final CustomMerge customMerge in customMerges) {
        if (customMerge.localPath == localPath) {
          result = customMerge.merge(currentFile, baseTemplateFile, targetTemplateFile);
          break;
        }
      }
      if (result == null) {
        // Default to two way merge as it does not require the base file to exist.
        MergeType mergeType = migrateResult.mergeTypeMap[localPath] ?? MergeType.twoWay;
        // Use two way merge if diff between base and target are the same.
        // This prevents the three way merge re-deleting the base->target changes.
        if (preferTwoWayMerge || userDiff.diff.substring(userDiff.diff.indexOf('@@')) == targetDiff.diff.substring(targetDiff.diff.indexOf('@@'))) {
          mergeType = MergeType.twoWay;
        }
        switch (mergeType) {
          case MergeType.twoWay: {
            result = await MigrateUtils.gitMergeFile(
              base: currentFile.path,
              current: currentFile.path,
              target: fileSystem.path.join(migrateResult.generatedTargetTemplateDirectory!.path, localPath),
              localPath: localPath,
            );
            break;
          }
          case MergeType.threeWay: {
            result = await MigrateUtils.gitMergeFile(
              base: fileSystem.path.join(migrateResult.generatedBaseTemplateDirectory!.path, localPath),
              current: currentFile.path,
              target: fileSystem.path.join(migrateResult.generatedTargetTemplateDirectory!.path, localPath),
              localPath: localPath,
            );
            break;
          }
        }
      }
      migrateResult.mergeResults.add(result);
      if (verbose) {
        status.pause();
        logger.printStatus('$localPath was merged.');
        status.resume();
      }
      continue;
    }
  }
}

/// Writes the files into the working directory for the developer to review and resolve any conflicts.
Future<void> writeWorkingDir(MigrateResult migrateResult, Logger logger, {bool verbose = false, FlutterProject? flutterProject}) async {
  flutterProject ??= FlutterProject.current();
  final Directory workingDir = flutterProject.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
  if (verbose) {
    logger.printStatus('Writing migrate working directory at `${workingDir.path}`');
  }
  // Write files in working dir
  for (final MergeResult result in migrateResult.mergeResults) {
    final File file = workingDir.childFile(result.localPath);
    file.createSync(recursive: true);
    if (result.mergedString != null) {
      file.writeAsStringSync(result.mergedString!, flush: true);
    } else {
      file.writeAsBytesSync(result.mergedBytes!, flush: true);
    }
  }
  // Write all files that are newly added in targetl
  for (final FilePendingMigration addedFile in migrateResult.addedFiles) {
    final File file = workingDir.childFile(addedFile.localPath);
    file.createSync(recursive: true);
    try {
      file.writeAsStringSync(addedFile.file.readAsStringSync(), flush: true);
    } on FileSystemException {
      file.writeAsBytesSync(addedFile.file.readAsBytesSync(), flush: true);
    }
  }

  // Write the MigrateManifest.
  final MigrateManifest manifest = MigrateManifest(
    migrateRootDir: workingDir,
    migrateResult: migrateResult,
  );
  manifest.writeFile();

  logger.printBox('Working directory created at `${workingDir.path}`');
  logger.printStatus(''); // newline

  // output the manifest contents.
  checkAndPrintMigrateStatus(manifest, workingDir, logger: logger);
}

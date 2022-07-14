// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
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
import 'migrate_result.dart';
import 'migrate_utils.dart';

// This defines files and directories that should be skipped regardless
// of gitignore and config settings
const List<String> _skippedFiles = <String>[
  'lib/main.dart', // Almost always user owned.
  'ios/Runner.xcodeproj/project.pbxproj', // Xcode managed configs that may not merge cleanly.
  'README.md', // changes to this shouldn't be overwritten since is is user owned.
];

const List<String> _skippedDirectories = <String>[
  '.dart_tool', // ignore the .dart_tool generated dir
  '.git', // ignore the git metadata
  'lib', // Files here are always user owned and we don't want to overwrite their apps.
  'test', // Files here are typically user owned and flutter-side changes are not relevant.
  'assets', // Common directory for user assets.
];

bool _skipped(String localPath, {Set<String?>? blacklistPrefixes}) {
  if (_skippedFiles.contains(localPath)) {
    return true;
  }
  for (final String dir in _skippedDirectories) {
    if (localPath.startsWith('$dir/')) {
      return true;
    }
  }
  if (blacklistPrefixes != null) {
    for (final String? prefix in blacklistPrefixes) {
      if (localPath.startsWith('${prefix!}/')) {
        return true;
      }
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
  '.bmp',
  '.svg',
  // Don't merge compiled artifacts and executables
  '.jar',
  '.so',
  '.exe',
];

const Set<String> _alwaysMigrateFiles = <String>{
  '.metadata', // .metadata tracks key migration information.
  'android/gradle/wrapper/gradle-wrapper.jar',
  // Always add .gitignore back in even if user-deleted as it makes it
  // difficult to migrate in the future and the migrate tool enforces git
  // usage.
  '.gitignore',
};

/// True for files that should not be merged. Typically, images and binary files.
bool _skippedMerge(String localPath) {
  for (final String ext in _skippedMergeFileExt) {
    if (localPath.endsWith(ext) && !_alwaysMigrateFiles.contains(localPath)) {
      return true;
    }
  }
  return false;
}

/// Data class holds the common context that is used throughout the steps of a migrate computation.
class MigrateContext {
  MigrateContext({
    required this.migrateResult,
    required this.flutterProject,
    required this.blacklistPrefixes,
    required this.logger,
    required this.verbose,
    required this.fileSystem,
    required this.status,
    required this.migrateUtils,
    this.baseProject,
    this.targetProject,
  });

  MigrateResult migrateResult;
  FlutterProject flutterProject;
  Set<String?> blacklistPrefixes;
  Logger logger;
  bool verbose;
  FileSystem fileSystem;
  Status status;
  MigrateUtils migrateUtils;

  MigrateBaseFlutterProject? baseProject;
  MigrateTargetFlutterProject? targetProject;
}

/// Computes the changes that migrates the current flutter project to the target revision.
///
/// This is the entry point to the core migration computations.
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
///  - Compute merge of all files that are modified by user and flutter
///  - Track temp dirs to be deleted
///
/// Structure: This method builds upon a MigrateResult instance
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
    bool allowFallbackBaseRevision = false,
    required FileSystem fileSystem,
    required Logger logger,
    required MigrateUtils migrateUtils,
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

  // Find the path prefixes to ignore. This allows subdirectories of platforms
  // not part of the migration to be skipped.
  platforms ??= flutterProject.getSupportedPlatforms(includeRoot: true);
  final Set<String?> blacklistPrefixes = <String?>{};
  for (final SupportedPlatform platform in SupportedPlatform.values) {
    blacklistPrefixes.add(platformToSubdirectoryPrefix(platform));
  }
  for (final SupportedPlatform platform in platforms) {
    blacklistPrefixes.remove(platformToSubdirectoryPrefix(platform));
  }
  blacklistPrefixes.remove('root');
  blacklistPrefixes.remove(null);

  final MigrateContext context = MigrateContext(
    migrateResult: MigrateResult.empty(),
    flutterProject: flutterProject,
    blacklistPrefixes: blacklistPrefixes,
    logger: logger,
    verbose: verbose,
    fileSystem: fileSystem,
    status: status,
    migrateUtils: migrateUtils,
  );

  final MigrateRevisions revisionConfig = MigrateRevisions(
    context: context,
    baseRevision: baseRevision,
    allowFallbackBaseRevision: allowFallbackBaseRevision,
    platforms: platforms!,
  );

  // Extract the files/paths that should be ignored by the migrate tool.
  // These paths are absolute paths.
  if (verbose) {
    logger.printStatus('Parsing unmanagedFiles.');
  }
  final List<String> unmanagedFiles = <String>[];
  final List<String> unmanagedDirectories = <String>[];
  final String basePath = flutterProject.directory.path;
  for (final String localPath in revisionConfig.config.unmanagedFiles) {
    if (localPath.endsWith(fileSystem.path.separator)) {
      unmanagedDirectories.add(fileSystem.path.join(basePath, localPath));
    } else {
      unmanagedFiles.add(fileSystem.path.join(basePath, localPath));
    }
  }
  status.pause();
  logger.printStatus('Generating base reference app', indent: 2, color: TerminalColor.grey);
  status.resume();

  // Generate the base templates
  final bool customBaseProjectDir = baseAppPath != null;
  final bool customTargetProjectDir = targetAppPath != null;
  Directory? baseProjectDir;
  Directory? targetProjectDir;
  if (customBaseProjectDir) {
    baseProjectDir = fileSystem.directory(baseAppPath);
  } else {
    baseProjectDir = fileSystem.systemTempDirectory.createTempSync('baseProject');
    if (verbose) {
      logger.printStatus('Created temporary directory: ${baseProjectDir.path}', indent: 2, color: TerminalColor.grey);
    }
  }
  if (customTargetProjectDir) {
    targetProjectDir = fileSystem.directory(targetAppPath);
  } else {
    targetProjectDir = fileSystem.systemTempDirectory.createTempSync('targetProject');
    if (verbose) {
      logger.printStatus('Created temporary directory: ${targetProjectDir.path}', indent: 2, color: TerminalColor.grey);
    }
  }
  context.migrateResult.generatedBaseTemplateDirectory = baseProjectDir;
  context.migrateResult.generatedTargetTemplateDirectory = targetProjectDir;

  await migrateUtils.gitInit(context.migrateResult.generatedBaseTemplateDirectory!.absolute.path);
  await migrateUtils.gitInit(context.migrateResult.generatedTargetTemplateDirectory!.absolute.path);

  final String name = flutterProject.manifest.appName;
  final String androidLanguage = flutterProject.android.isKotlin ? 'kotlin' : 'java';
  final String iosLanguage = flutterProject.ios.isSwift ? 'swift' : 'objc';

  final Directory targetFlutterDirectory = fileSystem.directory(Cache.flutterRoot);

  // Create the base reference vanilla app.
  //
  // This step clones the base flutter sdk, and uses it to create a new vanilla app.
  // The vanilla base app is used as part of a 3 way merge between the base app, target
  // app, and the current user-owned app.
  MigrateBaseFlutterProject baseProject = MigrateBaseFlutterProject(
    path: baseAppPath,
    directory: baseProjectDir,
    name: name,
    androidLanguage: androidLanguage,
    iosLanguage: iosLanguage,
    platformWhitelist: platforms,
  );
  context.baseProject = baseProject;
  await baseProject.createProject(
    context,
    revisionConfig.revisionsList,
    revisionConfig.revisionToConfigs,
    baseRevision ?? revisionConfig.metadataRevision ?? _getFallbackBaseRevision(allowFallbackBaseRevision, verbose, logger, status),
    revisionConfig.targetRevision,
    targetFlutterDirectory,
  );

  // Create target reference app when not provided.
  //
  // This step directly calls flutter create with the target (the current installed revision)
  // flutter sdk.
  MigrateTargetFlutterProject targetProject = MigrateTargetFlutterProject(
    path: targetAppPath,
    directory: targetProjectDir,
    name: name,
    androidLanguage: androidLanguage,
    iosLanguage: iosLanguage,
    platformWhitelist: platforms,
  );
  context.targetProject = targetProject;
  await targetProject.createProject(
    context,
    revisionConfig.targetRevision,
    targetFlutterDirectory,
  );

  await migrateUtils.gitInit(flutterProject.directory.absolute.path);

  // Generate diffs. These diffs are used to determine if a file is newly added, needs merging,
  // or deleted (rare). Only files with diffs between the base and target revisions need to be
  // migrated. If files are unchanged between base and target, then there are no changes to merge.
  status.pause();
  logger.printStatus('Diffing base and target reference app.', indent: 2, color: TerminalColor.grey);
  status.resume();

  context.migrateResult.diffMap.addAll(await baseProject.diff(context, targetProject));

  // Check for any new files that were added in the target reference app that did not
  // exist in the base reference app.
  status.pause();
  logger.printStatus('Finding newly added files', indent: 2, color: TerminalColor.grey);
  status.resume();
  context.migrateResult.addedFiles.addAll(await baseProject.newlyAddedFiles(context, targetProject));

  // Merge any base->target changed files with the version in the developer's project.
  // Files that the developer left unchanged are fully updated to match the target reference.
  // Files that the developer changed and were changed from base->target are merged.
  status.pause();
  logger.printStatus('Merging changes with existing project.', indent: 2, color: TerminalColor.grey);
  status.resume();
  await MigrateFlutterProject.merge(
    context,
    baseProject,
    targetProject,
    unmanagedFiles,
    unmanagedDirectories,
    preferTwoWayMerge,
  );

  // Clean up any temp directories generated by this tool.
  status.pause();
  logger.printStatus('Cleaning up temp directories.', indent: 2, color: TerminalColor.grey);
  status.resume();
  if (deleteTempDirectories) {
    // Don't delete user-provided directories
    if (!customBaseProjectDir) {
      context.migrateResult.tempDirectories.add(context.migrateResult.generatedBaseTemplateDirectory!);
    }
    if (!customTargetProjectDir) {
      context.migrateResult.tempDirectories.add(context.migrateResult.generatedTargetTemplateDirectory!);
    }
    context.migrateResult.tempDirectories.addAll(context.migrateResult.sdkDirs.values);
  }
  status.stop();
  return context.migrateResult;
}

String getLocalPath(String path, String basePath, FileSystem fileSystem) {
  return path.replaceFirst(basePath + fileSystem.path.separator, '');
}

/// Returns a base revision to fallback to in case a true base revision is unknown.
String _getFallbackBaseRevision(bool allowFallbackBaseRevision, bool verbose, Logger logger, Status status) {
  if (!allowFallbackBaseRevision) {
    status.stop();
    logger.printError('Could not determine base revision this app was created with:');
    logger.printError('.metadata file did not exist or did not contain a valid revision.', indent: 2);
    logger.printError('Run this command again with the `--allow-fallback-base-revision` flag to use Flutter v1.0.0 as the base revision or manually pass a revision with `--base-revision=<revision>`', indent: 2);
    throwToolExit('Failed to resolve base revision');
  }
  // Earliest version of flutter with .metadata: c17099f474675d8066fec6984c242d8b409ae985 (2017)
  // Flutter 2.0.0: 60bd88df915880d23877bfc1602e8ddcf4c4dd2a
  // Flutter v1.0.0: 5391447fae6209bb21a89e6a5a6583cac1af9b4b
  //
  // TODO(garyq): Use things like dart sdk version and other hints to better fine-tune this fallback.
  //
  // We fall back on flutter v1.0.0 if .metadata doesn't exist.
  if (verbose) {
    status.pause();
    logger.printStatus('Could not determine base revision, falling back on `v1.0.0`, revision 5391447fae6209bb21a89e6a5a6583cac1af9b4b', color: TerminalColor.grey, indent: 4);
    status.resume();
  }
  return '5391447fae6209bb21a89e6a5a6583cac1af9b4b';
}

abstract class MigrateFlutterProject {
  MigrateFlutterProject({
    required this.path,
    required this.directory,
    required this.name,
    required this.androidLanguage,
    required this.iosLanguage,
    this.platformWhitelist,
  });

  final String? path;
  final Directory directory;
  final String name;
  final String androidLanguage;
  final String iosLanguage;
  final List<SupportedPlatform>? platformWhitelist;

  /// Run git diff over each matching pair of files in the this project and the provided target project.
  Future<Map<String, DiffResult>> diff(
    MigrateContext context,
    MigrateFlutterProject other,
  ) async {
    final Map<String, DiffResult> diffMap = <String, DiffResult>{};
    final List<FileSystemEntity> thisFiles = directory.listSync(recursive: true);
    int modifiedFilesCount = 0;
    for (final FileSystemEntity entity in thisFiles) {
      if (entity is! File) {
        continue;
      }
      final File thisFile = entity.absolute;
      final String localPath = getLocalPath(thisFile.path, directory.absolute.path, context.fileSystem);
      if (_skipped(localPath, blacklistPrefixes: context.blacklistPrefixes)) {
        continue;
      }
      if (await context.migrateUtils.isGitIgnored(thisFile.absolute.path, directory.absolute.path)) {
        diffMap[localPath] = DiffResult(diffType: DiffType.ignored);
      }
      final File otherFile = other.directory.childFile(localPath);
      if (otherFile.existsSync()) {
        final DiffResult diff = await context.migrateUtils.diffFiles(thisFile, otherFile);
        diffMap[localPath] = diff;
        if (context.verbose && diff.diff != '') {
          context.status.pause();
          context.logger.printStatus('Found ${diff.exitCode} changes in $localPath', indent: 4, color: TerminalColor.grey);
          context.status.resume();
          modifiedFilesCount++;
        }
      } else {
        // Current file has no new template counterpart, which is equivalent to a deletion.
        // This could also indicate a renaming if there is an addition with equivalent contents.
        diffMap[localPath] = DiffResult(diffType: DiffType.deletion);
      }
    }
    if (context.verbose) {
      context.status.pause();
      context.logger.printStatus('$modifiedFilesCount files were modified between base and target apps.');
      context.status.resume();
    }
    return diffMap;
  }

  /// Find all files that exist in the target reference app but not in the base reference app.
  Future<List<FilePendingMigration>> newlyAddedFiles(MigrateContext context, MigrateFlutterProject other) async {
    final List<FilePendingMigration> addedFiles = <FilePendingMigration>[];
    final List<FileSystemEntity> otherFiles = other.directory.listSync(recursive: true);
    for (final FileSystemEntity entity in otherFiles) {
      if (entity is! File) {
        continue;
      }
      final File otherFile = entity.absolute;
      final String localPath = getLocalPath(otherFile.path, other.directory.absolute.path, context.fileSystem);
      if (directory.childFile(localPath).existsSync() || _skipped(localPath, blacklistPrefixes: context.blacklistPrefixes)) {
        continue;
      }
      if (await context.migrateUtils.isGitIgnored(otherFile.absolute.path, other.directory.absolute.path)) {
        context.migrateResult.diffMap[localPath] = DiffResult(diffType: DiffType.ignored);
      }
      context.migrateResult.diffMap[localPath] = DiffResult(diffType: DiffType.addition);
      if (context.flutterProject.directory.childFile(localPath).existsSync()) {
        // Don't store as added file if file already exists in the project.
        continue;
      }
      addedFiles.add(FilePendingMigration(localPath, otherFile));
    }
    if (context.verbose) {
      context.status.pause();
      context.logger.printStatus('${context.migrateResult.addedFiles.length} files were newly added in the target app.');
      context.status.resume();
    }
    return addedFiles;
  }

  /// Loops through each existing file and intelligently merges it with the base->target changes.
  static Future<void> merge(
    MigrateContext context,
    MigrateFlutterProject baseProject,
    MigrateFlutterProject targetProject,
    List<String> unmanagedFiles,
    List<String> unmanagedDirectories,
    bool preferTwoWayMerge,
  ) async {
    final List<CustomMerge> customMerges = <CustomMerge>[
      MetadataCustomMerge(logger: context.logger),
    ];
    // For each existing file in the project, we attempt to 3 way merge if it is changed by the user.
    final List<FileSystemEntity> currentFiles = context.flutterProject.directory.listSync(recursive: true);
    final String projectRootPath = context.flutterProject.directory.absolute.path;
    final Set<String> missingAlwaysMigrateFiles = Set<String>.of(_alwaysMigrateFiles);
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
      // Diff the current file against the old generated template
      final String localPath = getLocalPath(currentFile.path, projectRootPath, context.fileSystem);
      missingAlwaysMigrateFiles.remove(localPath);
      if (context.migrateResult.diffMap.containsKey(localPath) && context.migrateResult.diffMap[localPath]!.diffType == DiffType.ignored ||
          await context.migrateUtils.isGitIgnored(currentFile.path, context.flutterProject.directory.absolute.path) ||
          _skipped(localPath, blacklistPrefixes: context.blacklistPrefixes) ||
          _skippedMerge(localPath)) {
        continue;
      }
      final File baseTemplateFile = baseProject.directory.childFile(localPath);
      final File targetTemplateFile = targetProject.directory.childFile(localPath);
      final DiffResult userDiff = await context.migrateUtils.diffFiles(currentFile, baseTemplateFile);
      final DiffResult targetDiff = await context.migrateUtils.diffFiles(currentFile, targetTemplateFile);
      if (targetDiff.exitCode == 0) {
        // current file is already the same as the target file.
        continue;
      }

      final bool alwaysMigrate = _alwaysMigrateFiles.contains(localPath);

      // Current file unchanged by user, thus we consider it owned by the tool.
      if (userDiff.exitCode == 0 || alwaysMigrate) {
        if (context.migrateResult.diffMap.containsKey(localPath) || alwaysMigrate) {
          // File changed between base and target
          if (context.migrateResult.diffMap[localPath]!.diffType == DiffType.deletion) {
            // File is deleted in new template
            context.migrateResult.deletedFiles.add(FilePendingMigration(localPath, currentFile));
            continue;
          }
          if (context.migrateResult.diffMap[localPath]!.exitCode != 0 || alwaysMigrate) {
            // Accept the target version wholesale
            MergeResult result;
            try {
              result = StringMergeResult.explicit(
                mergedString: targetTemplateFile.readAsStringSync(),
                hasConflict: false,
                exitCode: 0,
                localPath: localPath,
              );
            } on FileSystemException {
              result = BinaryMergeResult.explicit(
                mergedBytes: targetTemplateFile.readAsBytesSync(),
                hasConflict: false,
                exitCode: 0,
                localPath: localPath,
              );
            }
            context.migrateResult.mergeResults.add(result);
            continue;
          }
        }
        continue;
      }

      // File changed by user
      if (context.migrateResult.diffMap.containsKey(localPath)) {
        MergeResult? result;
        // Default to two way merge as it does not require the base file to exist.
        MergeType mergeType = context.migrateResult.mergeTypeMap[localPath] ?? MergeType.twoWay;
        for (final CustomMerge customMerge in customMerges) {
          if (customMerge.localPath == localPath) {
            result = customMerge.merge(currentFile, baseTemplateFile, targetTemplateFile);
            mergeType = MergeType.custom;
            break;
          }
        }
        if (result == null) {
          late String basePath;
          late String currentPath;
          late String targetPath;

          // Use two way merge if diff between base and target are the same.
          // This prevents the three way merge re-deleting the base->target changes.
          if (preferTwoWayMerge) {
            mergeType = MergeType.twoWay;
          }
          switch (mergeType) {
            case MergeType.twoWay: {
              basePath = currentFile.path;
              currentPath = currentFile.path;
              targetPath = context.fileSystem.path.join(context.migrateResult.generatedTargetTemplateDirectory!.path, localPath);
              break;
            }
            case MergeType.threeWay: {
              basePath = context.fileSystem.path.join(context.migrateResult.generatedBaseTemplateDirectory!.path, localPath);
              currentPath = currentFile.path;
              targetPath = context.fileSystem.path.join(context.migrateResult.generatedTargetTemplateDirectory!.path, localPath);
              break;
            }
            case MergeType.custom: {
              break; // handled above
            }
          }
          if (mergeType != MergeType.custom) {
            result = await context.migrateUtils.gitMergeFile(
              base: basePath,
              current: currentPath,
              target: targetPath,
              localPath: localPath,
            );
          }
        }
        if (result != null) {
          // Don't include if result is identical to the current file.
          if (result is StringMergeResult) {
            if (result.mergedString == currentFile.readAsStringSync()) {
              context.status.pause();
              context.logger.printStatus('$localPath was merged with a $mergeType.');
              context.status.resume();
              continue;
            }
          } else {
            if ((result as BinaryMergeResult).mergedBytes == currentFile.readAsBytesSync()) {
              continue;
            }
          }
          context.migrateResult.mergeResults.add(result);
        }
        if (context.verbose) {
          context.status.pause();
          context.logger.printStatus('$localPath was merged with a $mergeType.');
          context.status.resume();
        }
        continue;
      }
    }

    // Add files that are in the target, marked as always migrate, and missing in the current project.
    for (final String localPath in missingAlwaysMigrateFiles) {
      final File targetTemplateFile = context.migrateResult.generatedTargetTemplateDirectory!.childFile(localPath);
      if (targetTemplateFile.existsSync() && !_skipped(localPath, blacklistPrefixes: context.blacklistPrefixes)) {
        context.migrateResult.addedFiles.add(FilePendingMigration(localPath, targetTemplateFile));
      }
    }
  }
}

/// The base reference project used in a migration computation.
class MigrateBaseFlutterProject extends MigrateFlutterProject {
  MigrateBaseFlutterProject({
    required super.path,
    required super.directory,
    required super.name,
    required super.androidLanguage,
    required super.iosLanguage,
    super.platformWhitelist,
  });

  /// Creates the base reference app based off of the migrate config in the .metadata file.
  Future<void> createProject(
    MigrateContext context,
    List<String> revisionsList,
    Map<String, List<MigratePlatformConfig>> revisionToConfigs,
    String fallbackRevision,
    String targetRevision,
    Directory targetFlutterDirectory,
  ) async {
    // Create base
    // Clone base flutter
    if (path == null) {
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
              sdkDir = context.fileSystem.systemTempDirectory.createTempSync('flutter_$activeRevision');
              context.migrateResult.sdkDirs[activeRevision] = sdkDir;
              context.status.pause();
              context.logger.printStatus('Cloning SDK $activeRevision', indent: 2, color: TerminalColor.grey);
              context.status.resume();
              sdkAvailable = await context.migrateUtils.cloneFlutter(activeRevision, sdkDir.absolute.path);
              revisionToFlutterSdkDir[revision] = sdkDir;
            }
          } else {
            // fallback to just using the modern target version of flutter.
            sdkDir = targetFlutterDirectory;
            revisionToFlutterSdkDir[revision] = sdkDir;
            sdkAvailable = true;
          }
        } while (!sdkAvailable);
        context.status.pause();
        context.logger.printStatus('Creating base app for $platforms with revision $revision.', indent: 2, color: TerminalColor.grey);
        context.status.resume();
        final String newDirectoryPath = await context.migrateUtils.createFromTemplates(
          sdkDir.childDirectory('bin').absolute.path,
          name: name,
          androidLanguage: androidLanguage,
          iosLanguage: iosLanguage,
          outputDirectory: context.migrateResult.generatedBaseTemplateDirectory!.absolute.path,
          platforms: platforms,
        );
        if (newDirectoryPath != context.migrateResult.generatedBaseTemplateDirectory?.path) {
          context.migrateResult.generatedBaseTemplateDirectory = context.fileSystem.directory(newDirectoryPath);
        }
        // Determine merge type for each newly generated file.
        final List<FileSystemEntity> generatedBaseFiles = context.migrateResult.generatedBaseTemplateDirectory!.listSync(recursive: true);
        for (final FileSystemEntity entity in generatedBaseFiles) {
          if (entity is! File) {
            continue;
          }
          final File baseTemplateFile = entity.absolute;
          final String localPath = getLocalPath(baseTemplateFile.path, context.migrateResult.generatedBaseTemplateDirectory!.absolute.path, context.fileSystem);
          if (!context.migrateResult.mergeTypeMap.containsKey(localPath)) {
            // Use two way merge when the base revision is the same as the target revision.
            context.migrateResult.mergeTypeMap[localPath] = revision == targetRevision ? MergeType.twoWay : MergeType.threeWay;
          }
        }
        if (newDirectoryPath != context.migrateResult.generatedBaseTemplateDirectory?.path) {
          context.migrateResult.generatedBaseTemplateDirectory = context.fileSystem.directory(newDirectoryPath);
          break; // The create command is old and does not distinguish between platforms so it only needs to be called once.
        }
      }
    }
  }
}

class MigrateTargetFlutterProject extends MigrateFlutterProject {
  MigrateTargetFlutterProject({
    required super.path,
    required super.directory,
    required super.name,
    required super.androidLanguage,
    required super.iosLanguage,
    super.platformWhitelist,
  });

  /// Creates the base reference app based off of the migrate config in the .metadata file.
  Future<void> createProject(
    MigrateContext context,
    String targetRevision,
    Directory targetFlutterDirectory,
  ) async {
    if (path == null) {
      // Create target
      context.status.pause();
      context.logger.printStatus('Creating target app with revision $targetRevision.', indent: 2, color: TerminalColor.grey);
      context.status.resume();
      if (context.verbose) {
        context.logger.printStatus('Creating target app.');
      }
      await context.migrateUtils.createFromTemplates(
        targetFlutterDirectory.childDirectory('bin').absolute.path,
        name: name,
        androidLanguage: androidLanguage,
        iosLanguage: iosLanguage,
        outputDirectory: context.migrateResult.generatedTargetTemplateDirectory!.absolute.path,
      );
    }
  }
}

/// Parses the metadata of the flutter project, extracts, computes, and stores the
/// revisions that the migration should use to migrate between.
class MigrateRevisions {
  MigrateRevisions({
    required MigrateContext context,
    required String? baseRevision,
    required bool allowFallbackBaseRevision,
    required List<SupportedPlatform> platforms,
  }) {
    _computeRevisions(context, baseRevision, allowFallbackBaseRevision, platforms);
  }

  late List<String> revisionsList;
  late Map<String, List<MigratePlatformConfig>> revisionToConfigs;
  late String fallbackRevision;
  late String targetRevision;
  late String? metadataRevision;
  late MigrateConfig config;

  void _computeRevisions(
    MigrateContext context,
    String? baseRevision,
    bool allowFallbackBaseRevision,
    List<SupportedPlatform> platforms
  ) {
    final FlutterProjectMetadata metadata = FlutterProjectMetadata(context.flutterProject.directory.childFile('.metadata'), context.logger);
    config = metadata.migrateConfig;

    // We call populate in case MigrateConfig is empty. If it is filled, populate should not do anything.
    config.populate(
      projectDirectory: context.flutterProject.directory,
      logger: context.logger,
    );

    final FlutterVersion version = FlutterVersion(workingDirectory: context.flutterProject.directory.absolute.path);
    metadataRevision = metadata.versionRevision;
    targetRevision = version.frameworkRevision;
    String rootBaseRevision = '';
    revisionToConfigs = <String, List<MigratePlatformConfig>>{};
    final Set<String> revisions = <String>{};
    if (baseRevision == null) {
      for (final MigratePlatformConfig platform in config.platformConfigs.values) {
        final String effectiveRevision = platform.baseRevision == null ?
            metadataRevision ?? _getFallbackBaseRevision(allowFallbackBaseRevision, context.verbose, context.logger, context.status) :
            platform.baseRevision!;
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
      revisionToConfigs[baseRevision] = <MigratePlatformConfig>[];
      for (final SupportedPlatform platform in platforms) {
        revisionToConfigs[baseRevision]!.add(MigratePlatformConfig(platform: platform, baseRevision: baseRevision));
      }
    }
    // Reorder such that the root revision is created first.
    revisions.remove(rootBaseRevision);
    revisionsList = List<String>.from(revisions);
    if (rootBaseRevision != '') {
      revisionsList.insert(0, rootBaseRevision);
    }
    if (context.verbose) {
      context.logger.printStatus('Potential base revisions: $revisionsList');
    }
    fallbackRevision = _getFallbackBaseRevision(true, context.verbose, context.logger, context.status);
    if (revisionsList.contains(fallbackRevision) && baseRevision != fallbackRevision && metadataRevision != fallbackRevision) {
      context.status.pause();
      context.logger.printStatus('Using Flutter v1.0.0 ($fallbackRevision) as the base revision since a valid base revision could not be found in the .metadata file. This may result in more merge conflicts than normally expected.', indent: 4, color: TerminalColor.grey);
      context.status.resume();
    }
  }
}

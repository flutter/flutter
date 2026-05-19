// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/version.dart';
import '../cache.dart';
import '../convert.dart';
import '../project.dart';

typedef PreviewManifestContents = Map<String, Object?>;

class PreviewManifest {
  PreviewManifest({
    required this.logger,
    required this.rootProject,
    required this.fs,
    required this.cache,
  });

  static const previewManifestPath = 'preview_manifest.json';
  static final previewManifestVersion = Version(0, 0, 2);
  static const kManifestVersion = 'version';
  static const kSdkVersion = 'sdk-version';
  static const kPubspecHashes = 'pubspec-hashes';

  final Logger logger;
  final FlutterProject rootProject;
  final FileSystem fs;
  final Cache cache;

  Directory get widgetPreviewScaffold => rootProject.widgetPreviewScaffold;
  String get _manifestPath => fs.path.join(widgetPreviewScaffold.path, previewManifestPath);
  File get _manifest => fs.file(_manifestPath);

  PreviewManifestContents? _tryLoadManifest() {
    final File manifest = fs.file(_manifestPath);
    if (!manifest.existsSync()) {
      return null;
    }
    return json.decode(manifest.readAsStringSync()) as PreviewManifestContents;
  }

  void generate() {
    logger.printStatus('Creating the Widget Preview Scaffold manifest at ${_manifest.path}');
    assert(!_manifest.existsSync());
    final manifestContents = <String, Object?>{
      kManifestVersion: previewManifestVersion.toString(),
      kSdkVersion: cache.dartSdkVersion,
      kPubspecHashes: _calculatePubspecHashes(),
    };
    _manifest.createSync(recursive: true);
    _updateManifest(manifestContents);
  }

  void _updateManifest(PreviewManifestContents contents) {
    _manifest.writeAsStringSync(json.encode(contents));
  }

  bool _isPubspecPathForProject({required FlutterProject project, required String path}) {
    return project.pubspecFile.absolute.path == path;
  }

  Map<String, String> _buildPubspecHashesMap() {
    return <String, String>{
      for (final FlutterProject project in <FlutterProject>[
        rootProject,
        ...rootProject.workspaceProjects.where((e) => e.pubspecFile.existsSync()),
      ])
        project.pubspecFile.absolute.path: project.computeManifestMD5Hash(logger: logger, fs: fs),
    };
  }

  Map<String, String> _calculatePubspecHashes({String? updatedPubspecPath}) {
    // Keep track of the set of previous workspace projects to see if there have been any changes
    // since the last time we checked.
    final List<FlutterProject> previousWorkspaceProjects = rootProject.workspaceProjects;

    // Ensure the root project's manifest is up to date.
    rootProject.reloadManifest(logger: logger, fs: fs);
    final PreviewManifestContents? manifest = _tryLoadManifest();

    if (updatedPubspecPath == null || manifest == null) {
      return _buildPubspecHashesMap();
    }

    // If the workspace's pubspec has changed and the set of workspace projects has been
    // modified since the last time we calculated hashes, recalculate all the hashes for
    // simplicity.
    if (_isPubspecPathForProject(project: rootProject, path: updatedPubspecPath)) {
      final bool workspaceProjectUpdates = !const SetEquality<Directory>().equals(
        previousWorkspaceProjects.map((p) => p.directory).toSet(),
        rootProject.workspaceProjects.map((p) => p.directory).toSet(),
      );
      if (workspaceProjectUpdates) {
        return _buildPubspecHashesMap();
      }
    }

    final FlutterProject? project = <FlutterProject>[rootProject, ...rootProject.workspaceProjects]
        .firstWhereOrNull(
          (FlutterProject project) =>
              _isPubspecPathForProject(project: project, path: updatedPubspecPath),
        );
    final Map<String, String> pubspecHashes = (manifest[kPubspecHashes]! as Map<String, Object?>)
        .cast<String, String>();
    // If the project isn't found, the pubspec is not actually part of the workspace and can be
    // ignored.
    if (project != null) {
      if (fs.file(updatedPubspecPath).existsSync()) {
        // Update the hash for the pubspec, as long as it exists.
        pubspecHashes[updatedPubspecPath] = project.computeManifestMD5Hash(logger: logger, fs: fs);
      } else {
        // The pubspec has been deleted, so it shouldn't continue to be tracked.
        pubspecHashes.remove(updatedPubspecPath);
      }
    }
    return pubspecHashes;
  }

  bool shouldGenerateProject() {
    if (!widgetPreviewScaffold.existsSync()) {
      return true;
    }
    final PreviewManifestContents? manifest = _tryLoadManifest();
    // If the manifest doesn't exist or the SDK version isn't present, the widget preview scaffold
    // should be regenerated and rebuilt.
    if (manifest == null ||
        !manifest.containsKey(kManifestVersion) ||
        !manifest.containsKey(kSdkVersion)) {
      logger.printWarning(
        'Invalid Widget Preview Scaffold manifest at ${_manifest.path}. Regenerating Widget '
        'Preview Scaffold.',
      );
      return true;
    }
    final Version? manifestVersion = Version.parse(manifest[kManifestVersion]! as String);
    // If the manifest version in the scaffold doesn't match the current preview manifest spec,
    // we should regenerate it.
    // TODO(bkonyi): is this actually what we want to do, or do we want to just update the manifest?
    if (manifestVersion == null || manifestVersion != previewManifestVersion) {
      logger.printStatus(
        'The existing Widget Preview Scaffold manifest version ($manifestVersion) '
        'is older than the currently supported version ($previewManifestVersion). Regenerating '
        'Widget Preview Scaffold.',
      );
      return true;
    }
    // If the SDK version of the widget preview scaffold doesn't match the current SDK version
    // the widget preview scaffold should also be regenerated to pick up any new functionality and
    // avoid possible binary compatibility issues.
    final sdkVersionMismatch = manifest[kSdkVersion] != cache.dartSdkVersion;
    if (sdkVersionMismatch) {
      logger.printStatus(
        'The existing Widget Preview Scaffold was generated with Dart SDK '
        'version ${manifest[kSdkVersion]}, which does not match the current Dart SDK version '
        '(${cache.dartSdkVersion}). Regenerating Widget Preview Scaffold.',
      );
    }
    return sdkVersionMismatch;
  }

  bool shouldRegeneratePubspec() {
    final PreviewManifestContents manifest = _tryLoadManifest()!;
    if (!manifest.containsKey(kPubspecHashes)) {
      logger.printWarning(
        'The Widget Preview Scaffold manifest does not include the last known state of the root '
        "project's pubspec.yaml.",
      );
      return true;
    }
    final Map<String, String> pubspecHashes = (manifest[kPubspecHashes]! as Map<String, Object?>)
        .cast<String, String>();
    return !const MapEquality<String, String>().equals(pubspecHashes, _calculatePubspecHashes());
  }

  void updatePubspecHash({String? updatedPubspecPath}) {
    final PreviewManifestContents? manifest = _tryLoadManifest();
    if (manifest == null) {
      generate();
      return;
    }
    manifest[kPubspecHashes] = _calculatePubspecHashes(updatedPubspecPath: updatedPubspecPath);
    _updateManifest(manifest);
  }

  @visibleForTesting
  Map<String, String> get pubspecHashes {
    final PreviewManifestContents manifest = _tryLoadManifest()!;
    return (manifest[kPubspecHashes]! as Map).cast<String, String>();
  }

  @visibleForTesting
  PreviewManifest copyWith({Cache? cache}) {
    return PreviewManifest(
      logger: logger,
      rootProject: rootProject,
      fs: fs,
      cache: cache ?? this.cache,
    );
  }
}

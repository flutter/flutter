// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

/// Information about a Gn workspace.
class GnWorkspace extends Workspace {
  /// The name of the directory that identifies the root of the workspace.
  static const String _jiriRootName = '.jiri_root';

  /// The resource provider used to access the file system.
  final ResourceProvider provider;

  /// The absolute workspace root path (the directory containing the
  /// `.jiri_root` directory).
  @override
  final String root;

  final File buildGnFile;

  /// Information about packages available in the workspace.
  final Packages packages;

  GnWorkspace._(this.provider, this.root, this.buildGnFile, this.packages);

  /// TODO(scheglov) Finish switching to [packages].
  Map<String, List<Folder>> get packageMap {
    var packageMap = <String, List<Folder>>{};
    for (var package in packages.packages) {
      packageMap[package.name] = [package.libFolder];
    }
    return packageMap;
  }

  @override
  UriResolver get packageUriResolver =>
      PackageMapUriResolver(provider, packageMap);

  @override
  SourceFactory createSourceFactory(
    DartSdk? sdk,
    SummaryDataStore? summaryData,
  ) {
    if (summaryData != null) {
      throw UnsupportedError(
          'Summary files are not supported in a GN workspace.');
    }
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(ResourceUriResolver(provider));
    return SourceFactory(resolvers);
  }

  /// Return the file with the given [absolutePath].
  ///
  /// Return `null` if the given [absolutePath] is not in the workspace [root].
  File? findFile(String absolutePath) {
    try {
      File writableFile = provider.getFile(absolutePath);
      if (writableFile.exists) {
        return writableFile;
      }
    } catch (_) {}
    return null;
  }

  @override
  WorkspacePackage? findPackageFor(String filePath) {
    var startFolder = provider.getFolder(filePath);
    for (var folder in startFolder.withAncestors) {
      if (folder.path.length < root.length) {
        // We've walked up outside of [root], so [path] is definitely not
        // defined in any package in this workspace.
        return null;
      }

      if (folder.getChildAssumingFile(file_paths.buildGn).exists) {
        return GnWorkspacePackage(folder.path, this);
      }
    }
    return null;
  }

  /// Find the GN workspace for the given [buildGnFile].
  ///
  /// Return `null` if a workspace could not be found. For a workspace to be
  /// found, the `.jiri_root` folder must be found, and at least one
  /// `<anything>package_config.json` file must be found in [buildGnFile]'s
  /// output directory.
  static GnWorkspace? find(File buildGnFile) {
    var provider = buildGnFile.provider;

    for (var folder in buildGnFile.parent.withAncestors) {
      if (folder.getChildAssumingFolder(_jiriRootName).exists) {
        // Found the .jiri_root file, must be a non-git workspace.
        String root = folder.path;

        var packagesFiles = _findPackagesFile(provider, root, buildGnFile);
        if (packagesFiles.isEmpty) {
          return null;
        }

        var packageMap = <String, Package>{};
        for (var packagesFile in packagesFiles) {
          var packages = parsePackageConfigJsonFile(provider, packagesFile);
          for (var package in packages.packages) {
            packageMap[package.name] = package;
          }
        }

        return GnWorkspace._(provider, root, buildGnFile, Packages(packageMap));
      }
    }
    return null;
  }

  /// For a source at `$root/foo/bar`, the packages files are generated in
  /// `$root/out/<debug|release>-XYZ/dartlang/gen/foo/bar`.
  ///
  /// Note that in some cases multiple package_config.json files can be found at
  /// that location, for example if the package contains both a library and a
  /// binary target. For a complete view of the package, all of these files need
  /// to be taken into account.
  ///
  /// Additionally, often times the package_config file name is prepended by
  /// extra words, which results in file names like
  /// `tiler_component_package_config.json`. Because of this, we cannot simply
  /// check for `pathContext.basename(file.path) == 'package_config.json'`.
  static List<File> _findPackagesFile(
    ResourceProvider provider,
    String root,
    File buildGnFile,
  ) {
    path.Context pathContext = provider.pathContext;
    String sourceDirectory =
        pathContext.relative(buildGnFile.parent.path, from: root);
    var outDirectory = _getOutDirectory(root, provider);
    if (outDirectory == null) {
      return const <File>[];
    }
    Folder genDir = outDirectory.getChildAssumingFolder(
        pathContext.join('dartlang', 'gen', sourceDirectory));
    if (!genDir.exists) {
      return const <File>[];
    }
    return genDir
        .getChildren()
        .whereType<File>()
        .where((File file) => file.path.endsWith('package_config.json'))
        .toList();
  }

  /// Returns the output directory of the build, or `null` if it could not be
  /// found.
  ///
  /// First attempts to read a config file at the root of the source tree. If
  /// that file cannot be found, looks for standard output directory locations.
  static Folder? _getOutDirectory(String root, ResourceProvider provider) {
    const String fuchsiaDirConfigFile = '.fx-build-dir';

    path.Context pathContext = provider.pathContext;
    File configFile =
        provider.getFile(pathContext.join(root, fuchsiaDirConfigFile));
    if (configFile.exists) {
      String buildDirPath = configFile.readAsStringSync().trim();
      if (buildDirPath.isNotEmpty) {
        if (pathContext.isRelative(buildDirPath)) {
          buildDirPath = pathContext.join(root, buildDirPath);
        }
        return provider.getFolder(buildDirPath);
      }
    }
    Folder outDirectory = provider.getFolder(pathContext.join(root, 'out'));
    if (!outDirectory.exists) {
      return null;
    }
    return outDirectory.getChildren().whereType<Folder>().firstWhereOrNull(
      (folder) {
        String baseName = pathContext.basename(folder.path);
        // Taking a best guess to identify a build dir. This is clearly a fallback
        // to the config-based method.
        return baseName.startsWith('debug') || baseName.startsWith('release');
      },
    );
  }
}

/// Information about a package defined in a GnWorkspace.
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a GnWorkspace.
class GnWorkspacePackage extends WorkspacePackage {
  @override
  final String root;

  @override
  final GnWorkspace workspace;

  GnWorkspacePackage(this.root, this.workspace);

  @override
  bool contains(Source source) {
    var filePath = filePathFromSource(source);
    if (filePath == null) return false;
    if (workspace.findFile(filePath) == null) {
      return false;
    }
    if (!workspace.provider.pathContext.isWithin(root, filePath)) {
      return false;
    }

    // Just because [filePath] is within [root] does not mean it is in this
    // package; it could be in a "subpackage." Must go through the work of
    // learning exactly which package [filePath] is contained in.
    return workspace.findPackageFor(filePath)!.root == root;
  }

  @override
  Packages packagesAvailableTo(String libraryPath) => workspace.packages;

  @override
  bool sourceIsInPublicApi(Source source) {
    var filePath = filePathFromSource(source);
    if (filePath == null) return false;
    var libFolder = workspace.provider.pathContext.join(root, 'lib');
    if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      var libSrcFolder =
          workspace.provider.pathContext.join(root, 'lib', 'src');
      return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
    }
    return false;
  }
}

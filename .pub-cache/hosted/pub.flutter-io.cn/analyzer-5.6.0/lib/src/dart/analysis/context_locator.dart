// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// An implementation of a context locator.
class ContextLocatorImpl implements ContextLocator {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// Initialize a newly created context locator. If a [resourceProvider] is
  /// supplied, it will be used to access the file system. Otherwise the default
  /// resource provider will be used.
  ContextLocatorImpl({ResourceProvider? resourceProvider})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  @override
  List<ContextRoot> locateRoots({
    required List<String> includedPaths,
    List<String>? excludedPaths,
    String? optionsFile,
    String? packagesFile,
  }) {
    //
    // Compute the list of folders and files that are to be included.
    //
    List<Folder> includedFolders = <Folder>[];
    List<File> includedFiles = <File>[];
    _resourcesFromPaths(includedPaths, includedFolders, includedFiles);
    //
    // Compute the list of folders and files that are to be excluded.
    //
    List<Folder> excludedFolders = <Folder>[];
    List<File> excludedFiles = <File>[];
    _resourcesFromPaths(
        excludedPaths ?? const <String>[], excludedFolders, excludedFiles);
    //
    // Use the excluded folders and files to filter the included folders and
    // files.
    //
    includedFolders = includedFolders
        .where((Folder includedFolder) =>
            !_containedInAny(excludedFolders, includedFolder))
        .toList();
    includedFiles = includedFiles
        .where((File includedFile) =>
            !_containedInAny(excludedFolders, includedFile) &&
            !excludedFiles.contains(includedFile))
        .toList();
    //
    // We now have a list of all of the files and folders that need to be
    // analyzed. For each, walk the directory structure and figure out where to
    // create context roots.
    //
    File? defaultOptionsFile;
    if (optionsFile != null) {
      defaultOptionsFile = resourceProvider.getFile(optionsFile);
      if (!defaultOptionsFile.exists) {
        defaultOptionsFile = null;
      }
    }
    File? defaultPackagesFile;
    if (packagesFile != null) {
      defaultPackagesFile = resourceProvider.getFile(packagesFile);
      if (!defaultPackagesFile.exists) {
        defaultPackagesFile = null;
      }
    }

    var roots = <ContextRootImpl>[];
    for (Folder folder in includedFolders) {
      var location = _contextRootLocation(
        folder,
        defaultOptionsFile: defaultOptionsFile,
        defaultPackagesFile: defaultPackagesFile,
        defaultRootFolder: () => folder,
      );

      ContextRootImpl? root;
      for (var existingRoot in roots) {
        if (existingRoot.root.isOrContains(folder.path) &&
            _matchRootWithLocation(existingRoot, location)) {
          root = existingRoot;
          break;
        }
      }

      root ??= _createContextRoot(
        roots,
        rootFolder: folder,
        workspace: location.workspace,
        optionsFile: location.optionsFile,
        packagesFile: location.packagesFile,
      );

      if (!root.isAnalyzed(folder.path)) {
        root.included.add(folder);
      }

      _createContextRootsIn(roots, {}, folder, excludedFolders, root,
          root.excludedGlobs, defaultOptionsFile, defaultPackagesFile);
    }

    for (File file in includedFiles) {
      Folder parent = file.parent;

      var location = _contextRootLocation(
        parent,
        defaultOptionsFile: defaultOptionsFile,
        defaultPackagesFile: defaultPackagesFile,
        defaultRootFolder: () => _fileSystemRoot(parent),
      );

      ContextRootImpl? root;
      for (var existingRoot in roots) {
        if (existingRoot.root.isOrContains(file.path) &&
            _matchRootWithLocation(existingRoot, location)) {
          root = existingRoot;
          break;
        }
      }

      root ??= _createContextRoot(
        roots,
        rootFolder: location.rootFolder,
        workspace: location.workspace,
        optionsFile: location.optionsFile,
        packagesFile: location.packagesFile,
      );

      if (!root.isAnalyzed(file.path)) {
        root.included.add(file);
      }
    }
    return roots;
  }

  /// Return `true` if the given [resource] is contained in one or more of the
  /// given [folders].
  bool _containedInAny(Iterable<Folder> folders, Resource resource) =>
      folders.any((Folder folder) => folder.contains(resource.path));

  /// Return the location of a context root for a file in the [parent].
  ///
  /// If the [defaultOptionsFile] is provided, it will be used, not a file
  /// found relative to the [parent].
  ///
  /// If the [defaultPackagesFile] is provided, it will be used, not a file
  /// found relative to the [parent].
  ///
  /// The root folder of the context is the parent of either the options,
  /// or the packages (grand-parent for `.dart_tool/package_config.json`) file,
  /// whichever is lower.
  _RootLocation _contextRootLocation(
    Folder parent, {
    required File? defaultOptionsFile,
    required File? defaultPackagesFile,
    required Folder Function() defaultRootFolder,
  }) {
    File? optionsFile;
    Folder? optionsFolderToChooseRoot;
    if (defaultOptionsFile != null) {
      optionsFile = defaultOptionsFile;
    } else {
      optionsFile = parent.findAnalysisOptionsYamlFile();
      optionsFolderToChooseRoot = optionsFile?.parent;
    }

    File? packagesFile;
    Folder? packagesFolderToChooseRoot;
    if (defaultPackagesFile != null) {
      packagesFile = defaultPackagesFile;
    } else {
      var foundPackages = _findPackagesFile(parent);
      packagesFile = foundPackages?.file;
      packagesFolderToChooseRoot = foundPackages?.parent;
    }

    var buildGnFile = _findBuildGnFile(parent);

    var rootFolder = _lowest([
      optionsFolderToChooseRoot,
      packagesFolderToChooseRoot,
      buildGnFile?.parent,
    ]);

    var workspace = _createWorkspace(
      folder: parent,
      packagesFile: packagesFile,
      buildGnFile: buildGnFile,
    );
    if (workspace is! BasicWorkspace) {
      rootFolder = _lowest([
        rootFolder,
        resourceProvider.getFolder(workspace.root),
      ]);
    }

    if (rootFolder == null) {
      rootFolder = defaultRootFolder();
      if (workspace is BasicWorkspace) {
        workspace = _createWorkspace(
          folder: rootFolder,
          packagesFile: packagesFile,
          buildGnFile: buildGnFile,
        );
      }
    }

    return _RootLocation(
      rootFolder: rootFolder,
      workspace: workspace,
      optionsFile: optionsFile,
      packagesFile: packagesFile,
    );
  }

  ContextRootImpl _createContextRoot(
    List<ContextRootImpl> roots, {
    required Folder rootFolder,
    required Workspace workspace,
    required File? optionsFile,
    required File? packagesFile,
  }) {
    optionsFile ??= _findDefaultOptionsFile(workspace);

    var root = ContextRootImpl(resourceProvider, rootFolder, workspace);
    root.packagesFile = packagesFile;
    root.optionsFile = optionsFile;
    root.excludedGlobs = _getExcludedGlobs(root);
    roots.add(root);
    return root;
  }

  /// If the given [folder] should be the root of a new analysis context, then
  /// create a new context root for it and add it to the list of context
  /// [roots]. The [containingRoot] is the context root from an enclosing
  /// directory and is used to inherit configuration information that isn't
  /// overridden.
  ///
  /// If either the [optionsFile] or [packagesFile] is non-`null` then the given
  /// file will be used even if there is a local version of the file.
  ///
  /// For each directory within the given [folder] that is neither in the list
  /// of [excludedFolders] nor excluded by the [excludedGlobs], recursively
  /// search for nested context roots.
  void _createContextRoots(
      List<ContextRoot> roots,
      Set<String> visited,
      Folder folder,
      List<Folder> excludedFolders,
      ContextRoot containingRoot,
      List<LocatedGlob> excludedGlobs,
      File? optionsFile,
      File? packagesFile) {
    //
    // If the options and packages files are allowed to be locally specified,
    // then look to see whether they are.
    //
    File? localOptionsFile;
    if (optionsFile == null) {
      localOptionsFile = folder.existingAnalysisOptionsYamlFile;
    }
    File? localPackagesFile;
    if (packagesFile == null) {
      localPackagesFile = _getPackagesFile(folder);
    }
    var buildGnFile = folder.getExistingFile(file_paths.buildGn);
    //
    // Create a context root for the given [folder] if at least one of the
    // options and packages file is locally specified.
    //
    if (localPackagesFile != null ||
        localOptionsFile != null ||
        buildGnFile != null) {
      if (optionsFile != null) {
        localOptionsFile = optionsFile;
      }
      if (packagesFile != null) {
        localPackagesFile = packagesFile;
      }
      var rootPackagesFile = localPackagesFile ?? containingRoot.packagesFile;
      var workspace = _createWorkspace(
        folder: folder,
        packagesFile: rootPackagesFile,
        buildGnFile: buildGnFile,
      );
      var root = ContextRootImpl(resourceProvider, folder, workspace);
      root.packagesFile = rootPackagesFile;
      root.optionsFile = localOptionsFile ?? containingRoot.optionsFile;
      root.included.add(folder);
      containingRoot.excluded.add(folder);
      roots.add(root);
      containingRoot = root;
      excludedGlobs = _getExcludedGlobs(root);
      root.excludedGlobs = excludedGlobs;
    }
    _createContextRootsIn(roots, visited, folder, excludedFolders,
        containingRoot, excludedGlobs, optionsFile, packagesFile);
  }

  /// For each directory within the given [folder] that is neither in the list
  /// of [excludedFolders] nor excluded by the [excludedGlobs], recursively
  /// search for nested context roots and add them to the list of [roots].
  ///
  /// If either the [optionsFile] or [packagesFile] is non-`null` then the given
  /// file will be used even if there is a local version of the file.
  void _createContextRootsIn(
      List<ContextRoot> roots,
      Set<String> visited,
      Folder folder,
      List<Folder> excludedFolders,
      ContextRoot containingRoot,
      List<LocatedGlob> excludedGlobs,
      File? optionsFile,
      File? packagesFile) {
    bool isExcluded(Folder folder) {
      if (excludedFolders.contains(folder) ||
          folder.shortName.startsWith('.')) {
        return true;
      }
      // TODO(scheglov) Why not take it from `containingRoot`?
      for (var pattern in excludedGlobs) {
        if (pattern.matches(folder.path)) {
          return true;
        }
      }
      return false;
    }

    // Stop infinite recursion via links.
    try {
      var canonicalFolderPath = folder.resolveSymbolicLinksSync().path;
      if (!visited.add(canonicalFolderPath)) {
        return;
      }
    } on FileSystemException {
      return;
    }

    //
    // Check each of the subdirectories to see whether a context root needs to
    // be added for it.
    //
    try {
      for (Resource child in folder.getChildren()) {
        if (child is Folder) {
          if (excludedFolders.contains(child)) {
            containingRoot.excluded.add(child);
          } else if (!isExcluded(child)) {
            _createContextRoots(roots, visited, child, excludedFolders,
                containingRoot, excludedGlobs, optionsFile, packagesFile);
          }
        }
      }
    } on FileSystemException {
      // The directory either doesn't exist or cannot be read. Either way, there
      // are no subdirectories that need to be added.
    }
  }

  Workspace _createWorkspace({
    required Folder folder,
    required File? packagesFile,
    required File? buildGnFile,
  }) {
    if (buildGnFile != null) {
      var workspace = GnWorkspace.find(buildGnFile);
      if (workspace != null) {
        return workspace;
      }
    }

    Packages packages;
    if (packagesFile != null) {
      packages = parsePackageConfigJsonFile(resourceProvider, packagesFile);
    } else {
      packages = Packages.empty;
    }

    var rootPath = folder.path;

    Workspace? workspace;
    workspace = BlazeWorkspace.find(resourceProvider, rootPath,
        lookForBuildFileSubstitutes: false);
    workspace = _mostSpecificWorkspace(workspace,
        PackageBuildWorkspace.find(resourceProvider, packages, rootPath));
    workspace = _mostSpecificWorkspace(
        workspace, PubWorkspace.find(resourceProvider, packages, rootPath));
    workspace ??= BasicWorkspace.find(resourceProvider, packages, rootPath);
    return workspace;
  }

  File? _findBuildGnFile(Folder folder) {
    for (var current in folder.withAncestors) {
      var file = current.getExistingFile(file_paths.buildGn);
      if (file != null) {
        return file;
      }
    }
    return null;
  }

  File? _findDefaultOptionsFile(Workspace workspace) {
    // TODO(scheglov) Create SourceFactory once.
    var sourceFactory = workspace.createSourceFactory(null, null);

    String? uriStr;
    if (workspace is WorkspaceWithDefaultAnalysisOptions) {
      uriStr = WorkspaceWithDefaultAnalysisOptions.uri;
    } else {
      uriStr = 'package:flutter/analysis_options_user.yaml';
    }

    var path = sourceFactory.forUri(uriStr)?.fullName;
    if (path != null) {
      var file = resourceProvider.getFile(path);
      if (file.exists) {
        return file;
      }
    }
    return null;
  }

  /// Return the packages file to be used to analyze files in the given
  /// [folder], or `null` if there is no packages file in the given folder or
  /// any parent folder.
  _PackagesFile? _findPackagesFile(Folder folder) {
    for (var current in folder.withAncestors) {
      var file = _getPackagesFile(current);
      if (file != null) {
        return _PackagesFile(current, file);
      }
    }
    return null;
  }

  /// Return a list containing the glob patterns used to exclude files from the
  /// given context [root]. The patterns are extracted from the analysis options
  /// file associated with the context root. The list will be empty if there are
  /// no exclusion patterns in the options file, or if there is no options file
  /// associated with the context root.
  List<LocatedGlob> _getExcludedGlobs(ContextRootImpl root) {
    List<LocatedGlob> patterns = [];
    File? optionsFile = root.optionsFile;
    if (optionsFile != null) {
      try {
        var doc = AnalysisOptionsProvider(
                root.workspace.createSourceFactory(null, null))
            .getOptionsFromFile(optionsFile);

        var analyzerOptions = doc.valueAt(AnalyzerOptions.analyzer);
        if (analyzerOptions is YamlMap) {
          var excludeOptions = analyzerOptions.valueAt(AnalyzerOptions.exclude);
          if (excludeOptions is YamlList) {
            var pathContext = resourceProvider.pathContext;

            void addGlob(List<String> components) {
              var pattern = posix.joinAll(components);
              patterns.add(
                LocatedGlob(
                  optionsFile.parent,
                  Glob(pattern, context: pathContext),
                ),
              );
            }

            for (String excludedPath in excludeOptions.whereType<String>()) {
              var excludedComponents = posix.split(excludedPath);
              addGlob(excludedComponents);
              if (excludedComponents.last == '**') {
                addGlob(excludedComponents..removeLast());
              }
            }
          }
        }
      } catch (exception) {
        // If we can't read and parse the analysis options file, then there
        // aren't any excluded files that need to be read.
      }
    }
    return patterns;
  }

  /// Return the packages file in the given [folder], or `null` if the folder
  /// does not contain a packages file.
  File? _getPackagesFile(Folder folder) {
    var file = folder
        .getChildAssumingFolder(file_paths.dotDartTool)
        .getChildAssumingFile(file_paths.packageConfigJson);
    if (file.exists) {
      return file;
    }

    return null;
  }

  /// Add to the given lists of [folders] and [files] all of the resources in
  /// the given list of [paths] that exist and are not contained within one of
  /// the folders.
  void _resourcesFromPaths(
      List<String> paths, List<Folder> folders, List<File> files) {
    for (String path in _uniqueSortedPaths(paths)) {
      Resource resource = resourceProvider.getResource(path);
      if (resource is Folder) {
        folders.add(resource);
      } else if (resource is File) {
        files.add(resource);
      } else {
        // Internal error: unhandled kind of resource.
      }
    }
  }

  /// Return a list of paths that contains all of the unique elements from the
  /// given list of [paths], sorted such that shorter paths are first.
  List<String> _uniqueSortedPaths(List<String> paths) {
    Set<String> uniquePaths = HashSet<String>.from(paths);
    List<String> sortedPaths = uniquePaths.toList();
    sortedPaths.sort((a, b) => a.length - b.length);
    return sortedPaths;
  }

  static Folder _fileSystemRoot(Resource resource) {
    for (var current = resource.parent;; current = current.parent) {
      if (current.isRoot) {
        return current;
      }
    }
  }

  /// Every element in [folders] must be a folder on the path from a file to
  /// the root of the file system. As such, they are either the same folder,
  /// or one is strictly above the other.
  static Folder? _lowest(List<Folder?> folders) {
    return folders.fold<Folder?>(null, (result, folder) {
      if (result == null) {
        return folder;
      } else if (folder != null && result.contains(folder.path)) {
        return folder;
      } else {
        return result;
      }
    });
  }

  /// Return `true` if the configuration of [existingRoot] is the same as
  /// the requested configuration for the [location].
  static bool _matchRootWithLocation(
    ContextRootImpl existingRoot,
    _RootLocation location,
  ) {
    if (existingRoot.optionsFile != location.optionsFile) {
      return false;
    }

    if (existingRoot.packagesFile != location.packagesFile) {
      return false;
    }

    // BasicWorkspace has no special meaning, so can be ignored.
    // Other workspaces have semantic meaning, so must match.
    var workspace = location.workspace;
    if (workspace is! BasicWorkspace) {
      if (existingRoot.workspace.root != workspace.root) {
        return false;
      }
    }

    return true;
  }

  /// Pick a workspace with the most specific root. If the root of [first] is
  /// non-null and is within the root of [second], return [second]. If any of
  /// [first] and [second] is null, return the other one. If the roots aren't
  /// within each other, return [first].
  static Workspace? _mostSpecificWorkspace(
      Workspace? first, Workspace? second) {
    if (first == null) return second;
    if (second == null) return first;
    if (isWithin(first.root, second.root)) {
      return second;
    }
    return first;
  }
}

/// The packages [file] found for the [parent].
///
/// In case of `.packages` file, [parent] is the parent of [file].
///
/// In case of `.dart_tool/package_config.json` it is a grand-parent.
class _PackagesFile {
  final Folder parent;
  final File file;

  _PackagesFile(this.parent, this.file);
}

class _RootLocation {
  final Folder rootFolder;
  final Workspace workspace;
  final File? optionsFile;
  final File? packagesFile;

  _RootLocation({
    required this.rootFolder,
    required this.workspace,
    required this.optionsFile,
    required this.packagesFile,
  });
}

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
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/bazel.dart';
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
      Folder parent = file.parent2;

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
      optionsFile = _findOptionsFile(parent);
      optionsFolderToChooseRoot = optionsFile?.parent2;
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

    var rootFolder = _lowest2(
      optionsFolderToChooseRoot,
      packagesFolderToChooseRoot,
    );

    var workspace = _createWorkspace(parent, packagesFile);
    if (workspace is! BasicWorkspace) {
      rootFolder = _lowest2(
        rootFolder,
        resourceProvider.getFolder(workspace.root),
      );
    }

    if (rootFolder == null) {
      rootFolder = defaultRootFolder();
      if (workspace is BasicWorkspace) {
        workspace = _createWorkspace(rootFolder, packagesFile);
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
      List<Glob> excludedGlobs,
      File? optionsFile,
      File? packagesFile) {
    //
    // If the options and packages files are allowed to be locally specified,
    // then look to see whether they are.
    //
    File? localOptionsFile;
    if (optionsFile == null) {
      localOptionsFile = _getOptionsFile(folder);
    }
    File? localPackagesFile;
    if (packagesFile == null) {
      localPackagesFile = _getPackagesFile(folder);
    }
    //
    // Create a context root for the given [folder] if at least one of the
    // options and packages file is locally specified.
    //
    if (localPackagesFile != null || localOptionsFile != null) {
      if (optionsFile != null) {
        localOptionsFile = optionsFile;
      }
      if (packagesFile != null) {
        localPackagesFile = packagesFile;
      }
      var rootPackagesFile = localPackagesFile ?? containingRoot.packagesFile;
      var workspace = _createWorkspace(folder, rootPackagesFile);
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
      List<Glob> excludedGlobs,
      File? optionsFile,
      File? packagesFile) {
    bool isExcluded(Folder folder) {
      if (excludedFolders.contains(folder) ||
          folder.shortName.startsWith('.')) {
        return true;
      }
      // TODO(scheglov) Why not take it from `containingRoot`?
      for (Glob pattern in excludedGlobs) {
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

  Workspace _createWorkspace(Folder folder, File? packagesFile) {
    Packages packages;
    if (packagesFile != null) {
      packages = parsePackagesFile(resourceProvider, packagesFile);
    } else {
      packages = Packages.empty;
    }

    // TODO(scheglov) Can we use Packages instead?
    var packageMap = <String, List<Folder>>{};
    for (var package in packages.packages) {
      packageMap[package.name] = [package.libFolder];
    }

    var rootPath = folder.path;

    // TODO(scheglov) Do we need this?
    if (_hasPackageFileInPath(rootPath)) {
      // A Bazel or Gn workspace that includes a '.packages' file is treated
      // like a normal (non-Bazel/Gn) directory. But may still use
      // package:build or Pub.
      return PackageBuildWorkspace.find(
              resourceProvider, packageMap, rootPath) ??
          PubWorkspace.find(resourceProvider, packageMap, rootPath) ??
          BasicWorkspace.find(resourceProvider, packageMap, rootPath);
    }

    Workspace? workspace;
    workspace = BazelWorkspace.find(resourceProvider, rootPath,
        lookForBuildFileSubstitutes: false);
    workspace ??= GnWorkspace.find(resourceProvider, rootPath);
    workspace ??=
        PackageBuildWorkspace.find(resourceProvider, packageMap, rootPath);
    workspace ??= PubWorkspace.find(resourceProvider, packageMap, rootPath);
    workspace ??= BasicWorkspace.find(resourceProvider, packageMap, rootPath);
    return workspace;
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
  }

  /// Return the analysis options file to be used to analyze files in the given
  /// [folder], or `null` if there is no analysis options file in the given
  /// folder or any parent folder.
  File? _findOptionsFile(Folder folder) {
    for (var current in folder.withAncestors) {
      var file = _getOptionsFile(current);
      if (file != null) {
        return file;
      }
    }
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
  }

  /// Return a list containing the glob patterns used to exclude files from the
  /// given context [root]. The patterns are extracted from the analysis options
  /// file associated with the context root. The list will be empty if there are
  /// no exclusion patterns in the options file, or if there is no options file
  /// associated with the context root.
  List<Glob> _getExcludedGlobs(ContextRootImpl root) {
    List<Glob> patterns = [];
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
              patterns.add(Glob(pattern, context: pathContext));
            }

            for (String excludedPath in excludeOptions.whereType<String>()) {
              var excludedComponents = posix.split(excludedPath);
              if (pathContext.isRelative(excludedPath)) {
                excludedComponents = [
                  ...pathContext.split(optionsFile.parent2.path),
                  ...excludedComponents,
                ];
              }
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

  /// If the given [directory] contains a file with the given [name], then
  /// return the file. Otherwise, return `null`.
  File? _getFile(Folder directory, String name) {
    var file = directory.getChildAssumingFile(name);
    return file.exists ? file : null;
  }

  /// Return the analysis options file in the given [folder], or `null` if the
  /// folder does not contain an analysis options file.
  File? _getOptionsFile(Folder folder) =>
      _getFile(folder, file_paths.analysisOptionsYaml);

  /// Return the packages file in the given [folder], or `null` if the folder
  /// does not contain a packages file.
  File? _getPackagesFile(Folder folder) {
    var file = folder
        .getChildAssumingFolder(file_paths.dotDartTool)
        .getChildAssumingFile(file_paths.packageConfigJson);
    if (file.exists) {
      return file;
    }

    return _getFile(folder, file_paths.dotPackages);
  }

  /// Return `true` if either the directory at [rootPath] or a parent of that
  /// directory contains a `.packages` file.
  bool _hasPackageFileInPath(String rootPath) {
    var folder = resourceProvider.getFolder(rootPath);
    return folder.withAncestors.any((current) {
      return current.getChildAssumingFile('.packages').exists;
    });
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
    for (var current = resource.parent2;; current = current.parent2) {
      if (current.isRoot) {
        return current;
      }
    }
  }

  /// The [first] and [second] must be folders on the path from a file to
  /// the root of the file system. As such, they are either the same folder,
  /// or one is strictly above the other.
  static Folder? _lowest2(Folder? first, Folder? second) {
    if (first != null) {
      if (second != null) {
        if (first.contains(second.path)) {
          return second;
        }
      }
      return first;
    }
    return second;
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

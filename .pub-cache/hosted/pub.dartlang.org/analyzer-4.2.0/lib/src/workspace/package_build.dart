// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Instances of the class `PackageBuildFileUriResolver` resolve `file` URI's by
/// first resolving file uri's in the expected way, and then by looking in the
/// corresponding generated directories.
class PackageBuildFileUriResolver extends ResourceUriResolver {
  final PackageBuildWorkspace workspace;

  PackageBuildFileUriResolver(this.workspace) : super(workspace.provider);

  @override
  Source? resolveAbsolute(Uri uri) {
    if (!ResourceUriResolver.isFileUri(uri)) {
      return null;
    }
    String filePath = fileUriToNormalizedPath(provider.pathContext, uri);
    Resource resource = provider.getResource(filePath);
    if (resource is! File) {
      return null;
    }
    var file = workspace.findFile(filePath);
    if (file != null) {
      return file.createSource(uri);
    }
    return null;
  }
}

/// The [UriResolver] that can resolve `package` URIs in
/// [PackageBuildWorkspace].
class PackageBuildPackageUriResolver extends UriResolver {
  final PackageBuildWorkspace _workspace;
  final UriResolver _normalUriResolver;
  final path.Context _context;

  PackageBuildPackageUriResolver(
      PackageBuildWorkspace workspace, this._normalUriResolver)
      : _workspace = workspace,
        _context = workspace.provider.pathContext;

  /// TODO(scheglov) Finish switching to [Packages].
  Map<String, List<Folder>> get packageMap => _workspace.packageMap;

  @override
  Uri? pathToUri(String path) {
    if (_context.isWithin(_workspace.root, path)) {
      var uriParts = _restoreUriParts(path);
      if (uriParts != null) {
        return Uri.parse('package:${uriParts[0]}/${uriParts[1]}');
      }
    }

    return _normalUriResolver.pathToUri(path);
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (!uri.isScheme('package')) {
      return null;
    }

    var basicResolverSource = _normalUriResolver.resolveAbsolute(uri);
    if (basicResolverSource != null && basicResolverSource.exists()) {
      return basicResolverSource;
    }

    String uriPath = uri.path;
    int slash = uriPath.indexOf('/');

    // If the path either starts with a slash or has no slash, it is invalid.
    if (slash < 1) {
      return null;
    }

    String packageName = uriPath.substring(0, slash);
    String fileUriPart = uriPath.substring(slash + 1);
    String filePath = fileUriPart.replaceAll('/', _context.separator);

    var file = _workspace.builtFile(
        _workspace.builtPackageSourcePath(filePath), packageName);
    if (file != null && file.exists) {
      return file.createSource(uri);
    }
    return basicResolverSource;
  }

  List<String>? _restoreUriParts(String filePath) {
    String relative = _context.relative(filePath, from: _workspace.root);
    List<String> components = _context.split(relative);
    if (components.length > 5 &&
        components[0] == '.dart_tool' &&
        components[1] == 'build' &&
        components[2] == 'generated' &&
        components[4] == 'lib') {
      String packageName = components[3];
      String pathInLib = components.skip(5).join('/');
      return [packageName, pathInLib];
    }
    return null;
  }
}

/// Information about a package:build workspace.
class PackageBuildWorkspace extends Workspace implements PubWorkspace {
  /// The name of the directory that identifies the root of the workspace. Note,
  /// the presence of this file does not show package:build is used. For that,
  /// the subdirectory [_dartToolBuildName] must exist. A `pub` subdirectory
  /// will usually exist in non-package:build projects too.
  static const String _dartToolRootName = '.dart_tool';

  /// The name of the subdirectory in [_dartToolName] that distinguishes
  /// projects built with package:build.
  static const String _dartToolBuildName = 'build';

  static const List<String> _generatedPathParts = [
    '.dart_tool',
    'build',
    'generated'
  ];

  /// The associated pubspec file.
  final File _pubspecFile;

  /// The content of the `pubspec.yaml` file.
  /// We read it once, so that all usages return consistent results.
  final String? _pubspecContent;

  @override
  final Packages packages;

  /// The resource provider used to access the file system.
  @override
  final ResourceProvider provider;

  /// The absolute workspace root path (the directory containing the
  /// `.dart_tool` directory).
  @override
  final String root;

  /// The name of the package under development as defined in pubspec.yaml. This
  /// matches the behavior of package:build.
  final String projectPackageName;

  /// `.dart_tool/build/generated` in [root].
  final String generatedRootPath;

  /// [projectPackageName] in [generatedRootPath].
  final String generatedThisPath;

  /// The singular package in this workspace.
  ///
  /// Each "package:build" workspace is itself one package.
  late final PackageBuildWorkspacePackage _theOnlyPackage;

  PackageBuildWorkspace._(
    this.provider,
    this.packages,
    this.root,
    this.projectPackageName,
    this.generatedRootPath,
    this.generatedThisPath,
    File pubspecFile,
  )   : _pubspecFile = pubspecFile,
        _pubspecContent = _fileContentOrNull(pubspecFile) {
    _theOnlyPackage = PackageBuildWorkspacePackage(root, this);
  }

  @override
  bool get isConsistentWithFileSystem {
    return _fileContentOrNull(_pubspecFile) == _pubspecContent;
  }

  /// TODO(scheglov) Finish switching to [packages].
  @override
  Map<String, List<Folder>> get packageMap {
    var packageMap = <String, List<Folder>>{};
    for (var package in packages.packages) {
      packageMap[package.name] = [package.libFolder];
    }
    return packageMap;
  }

  @override
  UriResolver get packageUriResolver => PackageBuildPackageUriResolver(
      this, PackageMapUriResolver(provider, packageMap));

  /// For some package file, which may or may not be a package source (it could
  /// be in `bin/`, `web/`, etc), find where its built counterpart will exist if
  /// its a generated source.
  ///
  /// To get a [builtPath] for a package source file to use in this method,
  /// use [builtPackageSourcePath]. For `bin/`, `web/`, etc, it must be relative
  /// to the project root.
  File? builtFile(String builtPath, String packageName) {
    if (packages[packageName] == null) {
      return null;
    }
    path.Context context = provider.pathContext;
    String fullBuiltPath = context.normalize(context.join(
        root, _dartToolRootName, 'build', 'generated', packageName, builtPath));
    return provider.getFile(fullBuiltPath);
  }

  /// Unlike the way that sources are resolved against `.packages` (if foo
  /// points to folder bar, then `foo:baz.dart` is found at `bar/baz.dart`), the
  /// built sources for a package require the `lib/` prefix first. This is
  /// because `bin/`, `web/`, and `test/` etc can all be built as well. This
  /// method exists to give a name to that prefix processing step.
  String builtPackageSourcePath(String filePath) {
    path.Context context = provider.pathContext;
    assert(context.isRelative(filePath), 'Not a relative path: $filePath');
    return context.join('lib', filePath);
  }

  @internal
  @override
  void contributeToResolutionSalt(ApiSignature buffer) {
    buffer.addString(_pubspecContent ?? '');
  }

  @override
  SourceFactory createSourceFactory(
    DartSdk? sdk,
    SummaryDataStore? summaryData,
  ) {
    if (summaryData != null) {
      throw UnsupportedError(
          'Summary files are not supported in a package:build workspace.');
    }
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(PackageBuildFileUriResolver(this));
    return SourceFactory(resolvers);
  }

  /// Return the file with the given [filePath], looking first in the generated
  /// directory `.dart_tool/build/generated/$projectPackageName/`, then in
  /// source directories.
  ///
  /// The file in the workspace [root] is returned even if it does not exist.
  /// Return `null` if the given [filePath] is not in the workspace root.
  File? findFile(String filePath) {
    path.Context context = provider.pathContext;
    assert(context.isAbsolute(filePath), 'Not an absolute path: $filePath');
    try {
      final String relativePath = context.relative(filePath, from: root);
      final file = builtFile(relativePath, projectPackageName);

      if (file!.exists) {
        return file;
      }

      return provider.getFile(filePath);
    } catch (_) {
      return null;
    }
  }

  @override
  PackageBuildWorkspacePackage? findPackageFor(String filePath) {
    var pathContext = provider.pathContext;

    // Must be in this workspace.
    if (!pathContext.isWithin(root, filePath)) {
      return null;
    }

    // If generated, must be for this package.
    if (pathContext.isWithin(generatedRootPath, filePath)) {
      if (!pathContext.isWithin(generatedThisPath, filePath)) {
        return null;
      }
    }

    return _theOnlyPackage;
  }

  /// Find the package:build workspace that contains the given [filePath].
  ///
  /// Return `null` if the filePath is not in a package:build workspace.
  static PackageBuildWorkspace? find(
      ResourceProvider provider, Packages packages, String filePath) {
    var startFolder = provider.getFolder(filePath);
    for (var folder in startFolder.withAncestors) {
      final File pubspec = folder.getChildAssumingFile(file_paths.pubspecYaml);
      final Folder dartToolDir =
          folder.getChildAssumingFolder(_dartToolRootName);
      final Folder dartToolBuildDir =
          dartToolDir.getChildAssumingFolder(_dartToolBuildName);

      // Found the .dart_tool file, that's our project root. We also require a
      // pubspec, to know the package name that package:build will assume.
      if (dartToolBuildDir.exists && pubspec.exists) {
        try {
          final yaml = loadYaml(pubspec.readAsStringSync()) as YamlMap;
          final packageName = yaml['name'] as String;
          final generatedRootPath = provider.pathContext
              .joinAll([folder.path, ..._generatedPathParts]);
          final generatedThisPath =
              provider.pathContext.join(generatedRootPath, packageName);
          return PackageBuildWorkspace._(provider, packages, folder.path,
              packageName, generatedRootPath, generatedThisPath, pubspec);
        } catch (_) {
          return null;
        }
      }

      // We found `pubspec.yaml`, but not `.dart_tool/build`.
      // Stop going up, this package does not have package:build results.
      // We don't want to find results of a parent package.
      if (pubspec.exists) {
        return null;
      }
    }
    return null;
  }

  /// Return the content of the [file], `null` if cannot be read.
  static String? _fileContentOrNull(File file) {
    try {
      return file.readAsStringSync();
    } catch (_) {
      return null;
    }
  }
}

/// Information about a package defined in a PackageBuildWorkspace.
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a PackageBuildWorkspace.
class PackageBuildWorkspacePackage extends WorkspacePackage
    implements PubWorkspacePackage {
  @override
  late final Pubspec? pubspec = () {
    final content = workspace._pubspecContent;
    if (content != null) {
      return Pubspec.parse(content);
    }
  }();

  @override
  final String root;

  @override
  final PackageBuildWorkspace workspace;

  PackageBuildWorkspacePackage(this.root, this.workspace);

  @override
  bool contains(Source source) {
    var uri = source.uri;

    if (uri.isScheme('package')) {
      var packageName = uri.pathSegments[0];
      return packageName == workspace.projectPackageName;
    }

    if (uri.isScheme('file')) {
      var path = source.fullName;
      return workspace.findPackageFor(path) != null;
    }

    return false;
  }

  @override
  Packages packagesAvailableTo(String libraryPath) => workspace.packages;

  @override
  bool sourceIsInPublicApi(Source source) {
    var filePath = filePathFromSource(source);
    if (filePath == null) return false;
    var libFolder = workspace.provider.pathContext.join(root, 'lib');
    if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      // A file in "$root/lib" is public iff it is not in "$root/lib/src".
      var libSrcFolder = workspace.provider.pathContext.join(libFolder, 'src');
      return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
    }

    libFolder = workspace.provider.pathContext.joinAll(
        [root, ...PackageBuildWorkspace._generatedPathParts, 'test', 'lib']);
    if (workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      // A file in "$generated/lib" is public iff it is not in
      // "$generated/lib/src".
      var libSrcFolder = workspace.provider.pathContext.join(libFolder, 'src');
      return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
    }
    return false;
  }
}

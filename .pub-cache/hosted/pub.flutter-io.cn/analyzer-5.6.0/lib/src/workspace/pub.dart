// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/simple.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';

/// Information about a Pub workspace.
class PubWorkspace extends SimpleWorkspace {
  /// The singular package in this workspace.
  ///
  /// Each Pub workspace is itself one package.
  late final PubWorkspacePackage _theOnlyPackage;

  /// The associated pubspec file.
  final File _pubspecFile;

  /// The content of the `pubspec.yaml` file.
  /// We read it once, so that all usages return consistent results.
  final String? _pubspecContent;

  PubWorkspace._(
    ResourceProvider provider,
    Packages packages,
    String root,
    File pubspecFile,
  )   : _pubspecFile = pubspecFile,
        _pubspecContent = _fileContentOrNull(pubspecFile),
        super(provider, packages, root) {
    _theOnlyPackage = PubWorkspacePackage(root, this);
  }

  @override
  bool get isConsistentWithFileSystem {
    return _fileContentOrNull(_pubspecFile) == _pubspecContent;
  }

  @internal
  @override
  void contributeToResolutionSalt(ApiSignature buffer) {
    buffer.addString(_pubspecContent ?? '');
  }

  @override
  WorkspacePackage? findPackageFor(String filePath) {
    final Folder folder = provider.getFolder(filePath);
    if (provider.pathContext.isWithin(root, folder.path)) {
      return _theOnlyPackage;
    } else {
      return null;
    }
  }

  /// Find the pub workspace that contains the given [filePath].
  static PubWorkspace? find(
    ResourceProvider provider,
    Packages packages,
    String filePath,
  ) {
    var start = provider.getFolder(filePath);
    for (var current in start.withAncestors) {
      var pubspec = current.getChildAssumingFile(file_paths.pubspecYaml);
      if (pubspec.exists) {
        var root = current.path;
        return PubWorkspace._(provider, packages, root, pubspec);
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

/// Information about a package defined in a [PubWorkspace].
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a [PubWorkspace].
class PubWorkspacePackage extends WorkspacePackage {
  @override
  final String root;

  Pubspec? _pubspec;

  /// A flag to indicate if we've tried to parse the pubspec.
  bool _parsedPubspec = false;

  @override
  final PubWorkspace workspace;

  PubWorkspacePackage(this.root, this.workspace);

  /// Get the associated parsed [Pubspec], or `null` if there was an error in
  /// reading or parsing.
  Pubspec? get pubspec {
    if (!_parsedPubspec) {
      _parsedPubspec = true;
      final content = workspace._pubspecContent;
      if (content != null) {
        _pubspec = Pubspec.parse(content);
      }
    }
    return _pubspec;
  }

  @override
  bool contains(Source source) {
    var filePath = filePathFromSource(source);
    if (filePath == null) return false;
    // There is a 1-1 relationship between [PubWorkspace]s and
    // [PubWorkspacePackage]s. If a file is in a package's workspace, then it
    // is in the package as well.
    return workspace.provider.pathContext.isWithin(root, filePath);
  }

  @override
  Packages packagesAvailableTo(String libraryPath) {
    // TODO(brianwilkerson) Consider differentiating based on whether the
    //  [libraryPath] is inside the `lib` directory.
    return workspace.packages;
  }

  @override

  /// A Pub package's public API consists of libraries found in the top-level
  /// "lib" directory, and any subdirectories, excluding the "src" directory
  /// just inside the top-level "lib" directory.
  bool sourceIsInPublicApi(Source source) {
    var filePath = filePathFromSource(source);
    if (filePath == null) return false;
    var libFolder = workspace.provider.pathContext.join(root, 'lib');
    if (!workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      return false;
    }
    var libSrcFolder = workspace.provider.pathContext.join(root, 'lib', 'src');
    return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';

/// The directory under `web/` that holds flavor-specific web resources.
///
/// This directory is reserved. It is never copied to the build output and it is
/// never served by the development server.
const String kWebFlavorsDirectoryName = 'flavors';

/// A web resource together with the path it is served at.
class WebResource {
  const WebResource({required this.relativePath, required this.file});

  /// Path of the resource relative to the `web/` directory, always using `/` as
  /// the separator.
  final String relativePath;

  /// The file that provides this resource, either in `web/` or in a flavor
  /// directory.
  final File file;
}

/// Whether [flavor] can be used as a directory name under `web/flavors/`.
///
/// The flavor comes from the command line and is used as a path segment, so
/// values that could escape `web/` are rejected.
bool isValidWebFlavorName(String flavor) {
  if (flavor.isEmpty || flavor == '.' || flavor == '..') {
    return false;
  }
  return !flavor.contains('/') && !flavor.contains(r'\');
}

/// Whether [relativePath] is inside the reserved `web/flavors/` directory.
bool isWebFlavorsPath(String relativePath) {
  final String firstSegment = relativePath.split('/').first;
  return firstSegment.toLowerCase() == kWebFlavorsDirectoryName;
}

String _relativePath(FileSystem fileSystem, File file, Directory directory) {
  return fileSystem.path
      .relative(file.path, from: directory.path)
      .replaceAll(fileSystem.path.separator, '/');
}

/// Resolves the web resources for the web app with the given [flavor].
///
/// A file in `web/flavors/<flavor>/` replaces the file in [webDirectory] at the
/// same relative path. Directories are merged rather than replaced, and files
/// that only exist in the flavor directory are added. The `web/flavors/`
/// directory itself is never part of the result.
///
/// If [flavor] is null, invalid, or names a directory that does not exist, the
/// result is the shared resources under [webDirectory].
List<WebResource> resolveWebResources({required Directory webDirectory, String? flavor}) {
  if (!webDirectory.existsSync()) {
    return const <WebResource>[];
  }
  final FileSystem fileSystem = webDirectory.fileSystem;

  // Keyed by relative path so that a flavor file shadows the shared file.
  final resources = <String, WebResource>{};

  if (flavor != null && isValidWebFlavorName(flavor)) {
    final Directory flavorDirectory = webDirectory
        .childDirectory(kWebFlavorsDirectoryName)
        .childDirectory(flavor);
    if (flavorDirectory.existsSync()) {
      for (final File file in flavorDirectory.listSync(recursive: true).whereType<File>()) {
        final String relativePath = _relativePath(fileSystem, file, flavorDirectory);
        resources[relativePath] = WebResource(relativePath: relativePath, file: file);
      }
    }
  }

  for (final File file in webDirectory.listSync(recursive: true).whereType<File>()) {
    final String relativePath = _relativePath(fileSystem, file, webDirectory);
    if (isWebFlavorsPath(relativePath)) {
      continue;
    }
    resources.putIfAbsent(relativePath, () => WebResource(relativePath: relativePath, file: file));
  }

  final List<WebResource> result = resources.values.toList()
    ..sort((WebResource a, WebResource b) => a.relativePath.compareTo(b.relativePath));
  return result;
}

/// Resolves a single web resource with the relative path [relativePath].
///
/// Returns the flavor-specific file when it exists, otherwise the shared file.
/// Returns null when neither exists.
File? resolveWebResourceFile({
  required Directory webDirectory,
  required String relativePath,
  String? flavor,
}) {
  final FileSystem fileSystem = webDirectory.fileSystem;
  final List<String> segments = relativePath.split('/');
  if (flavor != null && isValidWebFlavorName(flavor)) {
    final File flavorFile = fileSystem.file(
      fileSystem.path.joinAll(<String>[
        webDirectory.path,
        kWebFlavorsDirectoryName,
        flavor,
        ...segments,
      ]),
    );
    if (flavorFile.existsSync()) {
      return flavorFile;
    }
  }
  final File sharedFile = fileSystem.file(
    fileSystem.path.joinAll(<String>[webDirectory.path, ...segments]),
  );
  return sharedFile.existsSync() ? sharedFile : null;
}

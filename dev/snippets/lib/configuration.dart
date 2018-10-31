// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' hide Platform;

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:path/path.dart' as path;

/// What type of snippet to produce.
enum SnippetType {
  /// Produces a snippet that includes the code interpolated into an application
  /// template.
  application,
  /// Produces a nicely formatted sample code, but no application.
  sample,
}

/// Return the name of an enum item.
String getEnumName(dynamic enumItem) {
  final String name = '$enumItem';
  final int index = name.indexOf('.');
  return index == -1 ? name : name.substring(index + 1);
}

/// A class to compute the configuration of the snippets input and output
/// locations based in the current location of the snippets main.dart.
class Configuration {
  const Configuration({Platform platform}) : platform = platform ?? const LocalPlatform();

  final Platform platform;

  /// This is the configuration directory for the snippets system, containing
  /// the skeletons and templates.
  @visibleForTesting
  Directory getConfigDirectory(String kind) {
    final String platformScriptPath = path.dirname(platform.script.toFilePath());
    final String configPath =
        path.canonicalize(path.join(platformScriptPath, '..', 'config', kind));
    return Directory(configPath);
  }

  /// This is where the snippets themselves will be written, in order to be
  /// uploaded to the docs site.
  Directory get outputDirectory {
    final String platformScriptPath = path.dirname(platform.script.toFilePath());
    final String docsDirectory =
      path.canonicalize(path.join(platformScriptPath, '..', '..', 'docs', 'doc', 'snippets'));
    return Directory(docsDirectory);
  }

  /// This makes sure that the output directory exists.
  void createOutputDirectory() {
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync(recursive: true);
    }
  }

  /// The directory containing the HTML skeletons to be filled out with metadata
  /// and returned to dartdoc for insertion in the output.
  Directory get skeletonsDirectory => getConfigDirectory('skeletons');

  /// The directory containing the code templates that can be referenced by the
  /// dartdoc.
  Directory get templatesDirectory => getConfigDirectory('templates');

  /// Gets the skeleton file to use for the given [SnippetType].
  File getHtmlSkeletonFile(SnippetType type) {
    return File(path.join(skeletonsDirectory.path, '${getEnumName(type)}.html'));
  }
}

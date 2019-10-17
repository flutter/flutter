// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' hide Platform;

import 'package:meta/meta.dart';
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
  Configuration({@required this.flutterRoot}) : assert(flutterRoot != null);

  final Directory flutterRoot;

  /// This is the configuration directory for the snippets system, containing
  /// the skeletons and templates.
  @visibleForTesting
  Directory get configDirectory {
    _configPath ??= Directory(
        path.canonicalize(path.join(flutterRoot.absolute.path, 'dev', 'snippets', 'config')));
    return _configPath;
  }

  Directory _configPath;

  /// This is where the snippets themselves will be written, in order to be
  /// uploaded to the docs site.
  Directory get outputDirectory {
    _docsDirectory ??= Directory(
        path.canonicalize(path.join(flutterRoot.absolute.path, 'dev', 'docs', 'doc', 'snippets')));
    return _docsDirectory;
  }

  Directory _docsDirectory;

  /// This makes sure that the output directory exists.
  void createOutputDirectory() {
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync(recursive: true);
    }
  }

  /// The directory containing the HTML skeletons to be filled out with metadata
  /// and returned to dartdoc for insertion in the output.
  Directory get skeletonsDirectory => Directory(path.join(configDirectory.path,'skeletons'));

  /// The directory containing the code templates that can be referenced by the
  /// dartdoc.
  Directory get templatesDirectory => Directory(path.join(configDirectory.path, 'templates'));

  /// Gets the skeleton file to use for the given [SnippetType] and DartPad preference.
  File getHtmlSkeletonFile(SnippetType type, {bool showDartPad = false}) {
    assert(!showDartPad || type == SnippetType.application,
        'Only application snippets work with dartpad.');
    final String filename =
        '${showDartPad ? 'dartpad-' : ''}${getEnumName(type)}.html';
    return File(path.join(skeletonsDirectory.path, filename));
  }
}

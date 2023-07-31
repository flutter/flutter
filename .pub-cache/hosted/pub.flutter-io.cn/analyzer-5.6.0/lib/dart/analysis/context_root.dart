// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/workspace/workspace.dart';

/// Information about the root directory associated with an analysis context.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ContextRoot {
  /// A list of the files and directories within the root directory that should
  /// not be analyzed.
  List<Resource> get excluded;

  /// A collection of the absolute, normalized paths of files and directories
  /// within the root directory that should not be analyzed.
  Iterable<String> get excludedPaths;

  /// A list of the files and directories within the root directory that should
  /// be analyzed. If all of the files in the root directory (other than those
  /// that are explicitly excluded) should be analyzed, then this list will
  /// contain the root directory.
  List<Resource> get included;

  /// A collection of the absolute, normalized paths of files within the root
  /// directory that should be analyzed. If all of the files in the root
  /// directory (other than those that are explicitly excluded) should be
  /// analyzed, then this collection will contain the path of the root
  /// directory.
  Iterable<String> get includedPaths;

  /// The analysis options file that should be used when analyzing the files
  /// within this context root, or `null` if there is no options file.
  File? get optionsFile;

  /// The packages file that should be used when analyzing the files within this
  /// context root, or `null` if there is no packages file.
  File? get packagesFile;

  /// The resource provider used to access the file system.
  ResourceProvider get resourceProvider;

  /// The root directory containing the files to be analyzed.
  Folder get root;

  /// Return the workspace that contains this context root.
  Workspace get workspace;

  /// Return the absolute, normalized paths of all of the files that are
  /// contained in this context. These are all of the files that are included
  /// directly or indirectly by one or more of the [includedPaths] and that are
  /// not excluded by any of the [excludedPaths].
  ///
  /// Note that the list is not filtered based on the file suffix, so non-Dart
  /// files can be returned.
  Iterable<String> analyzedFiles();

  /// Return `true` if the file or directory with the given [path] will be
  /// analyzed in this context. A file (or directory) will be analyzed if it is
  /// either the same as or contained in one of the [includedPaths] and, if it
  /// is contained in one of the [includedPaths], is not the same as or
  /// contained in one of the [excludedPaths].
  bool isAnalyzed(String path);
}

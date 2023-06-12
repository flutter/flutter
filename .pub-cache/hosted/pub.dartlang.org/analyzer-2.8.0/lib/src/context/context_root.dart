// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;

/// Information about the root directory associated with an analysis context.
///
/// Clients may not extend, implement or mix-in this class.
class ContextRoot {
  /// The path context to use when manipulating paths.
  final path.Context pathContext;

  /// The absolute path of the root directory containing the files to be
  /// analyzed.
  final String root;

  /// A list of the absolute paths of files and directories within the root
  /// directory that should not be analyzed.
  final List<String> exclude;

  /// An informative value for the file path that the analysis options were read
  /// from. This value can be `null` if there is no analysis options file or if
  /// the location of the file has not yet been discovered.
  String? optionsFilePath;

  /// Initialize a newly created context root.
  ContextRoot(this.root, this.exclude, {required this.pathContext});

  @override
  int get hashCode => Object.hash(root, exclude);

  @override
  bool operator ==(Object other) {
    if (other is ContextRoot) {
      return root == other.root &&
          _listEqual(exclude, other.exclude, (String a, String b) => a == b);
    }
    return false;
  }

  /// Return `true` if the file with the given [filePath] is contained within
  /// this context root. A file contained in a context root if it is within the
  /// context [root] neither explicitly excluded or within one of the excluded
  /// directories.
  bool containsFile(String filePath) {
    if (!pathContext.isWithin(root, filePath)) {
      return false;
    }
    for (String excluded in exclude) {
      if (filePath == excluded || pathContext.isWithin(excluded, filePath)) {
        return false;
      }
    }
    return true;
  }

  /// Compare the lists [listA] and [listB], using [itemEqual] to compare list
  /// elements.
  bool _listEqual<T>(
      List<T>? listA, List<T>? listB, bool Function(T a, T b) itemEqual) {
    if (listA == null) {
      return listB == null;
    }
    if (listB == null) {
      return false;
    }
    if (listA.length != listB.length) {
      return false;
    }
    for (int i = 0; i < listA.length; i++) {
      if (!itemEqual(listA[i], listB[i])) {
        return false;
      }
    }
    return true;
  }
}

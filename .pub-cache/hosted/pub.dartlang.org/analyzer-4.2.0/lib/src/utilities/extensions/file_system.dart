// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

extension FolderExtension on Folder {
  /// Returns the existing analysis options file in the target, or `null`.
  File? get existingAnalysisOptionsYamlFile {
    return getExistingFile(file_paths.analysisOptionsYaml);
  }

  /// Return the analysis options file to be used for files in the target.
  File? findAnalysisOptionsYamlFile() {
    for (final current in withAncestors) {
      final file = current.existingAnalysisOptionsYamlFile;
      if (file != null) {
        return file;
      }
    }
    return null;
  }

  /// If the target contains an existing file with the given [name], then
  /// returns it. Otherwise, return `null`.
  File? getExistingFile(String name) {
    final file = getChildAssumingFile(name);
    return file.exists ? file : null;
  }
}

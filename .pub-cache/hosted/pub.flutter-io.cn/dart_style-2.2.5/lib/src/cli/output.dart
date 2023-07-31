// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:io';

import '../source_code.dart';

/// Where formatted code results should go.
enum Output {
  /// Overwrite files on disc.
  write,

  /// Print the code to the terminal as human-friendly text.
  show,

  /// Print the code to the terminal as JSON.
  json,

  /// Do nothing. (Used when the user just wants the list of files that would
  /// be changed.)
  none;

  /// Write the file to disc.
  ///
  /// If stdin is being formatted, then [file] is `null`.
  bool writeFile(File? file, String displayPath, SourceCode result) {
    if (this != Output.write) return false;

    try {
      file!.writeAsStringSync(result.text);
    } on FileSystemException catch (err) {
      stderr.writeln('Could not overwrite $displayPath: '
          '${err.osError!.message} (error code ${err.osError!.errorCode})');
    }

    return true;
  }

  /// Print the file to the terminal in some way.
  void showFile(String path, SourceCode result) {
    switch (this) {
      case Output.show:
        // Don't add an extra newline.
        stdout.write(result.text);
        break;

      case Output.json:
        // TODO(rnystrom): Put an empty selection in here to remain compatible with
        // the old formatter. Since there's no way to pass a selection on the
        // command line, this will never be used, which is why it's hard-coded to
        // -1, -1. If we add support for passing in a selection, put the real
        // result here.
        print(jsonEncode({
          'path': path,
          'source': result.text,
          'selection': {
            'offset': result.selectionStart ?? -1,
            'length': result.selectionLength ?? -1
          }
        }));
        break;

      case Output.write:
      case Output.none:
        // Do nothing.
        break;
    }
  }
}

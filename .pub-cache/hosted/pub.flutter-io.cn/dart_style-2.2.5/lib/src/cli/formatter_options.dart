// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../source_code.dart';
import '../style_fix.dart';
import 'output.dart';
import 'show.dart';
import 'summary.dart';

// Note: The following line of code is modified by tool/grind.dart.
const dartStyleVersion = '2.2.5-dev';

/// Global options that affect how the formatter produces and uses its outputs.
class FormatterOptions {
  /// The number of spaces of indentation to prefix the output with.
  final int indent;

  /// The number of columns that formatted output should be constrained to fit
  /// within.
  final int pageWidth;

  /// Whether symlinks should be traversed when formatting a directory.
  final bool followLinks;

  /// The style fixes to apply while formatting.
  final List<StyleFix> fixes;

  /// Which affected files should be shown.
  final Show show;

  /// Where formatted code should be output.
  final Output output;

  final Summary summary;

  /// Sets the exit code to 1 if any changes are made.
  final bool setExitIfChanged;

  FormatterOptions(
      {this.indent = 0,
      this.pageWidth = 80,
      this.followLinks = false,
      Iterable<StyleFix>? fixes,
      this.show = Show.changed,
      this.output = Output.write,
      this.summary = Summary.none,
      this.setExitIfChanged = false})
      : fixes = [...?fixes];

  /// Called when [file] is about to be formatted.
  ///
  /// If stdin is being formatted, then [file] is `null`.
  void beforeFile(File? file, String label) {
    summary.beforeFile(file, label);
  }

  /// Describe the processed file at [path] with formatted [result]s.
  ///
  /// If the contents of the file are the same as the formatted output,
  /// [changed] will be false.
  ///
  /// If stdin is being formatted, then [file] is `null`.
  void afterFile(File? file, String displayPath, SourceCode result,
      {required bool changed}) {
    summary.afterFile(this, file, displayPath, result, changed: changed);

    // Save the results to disc.
    var overwritten = false;
    if (changed) {
      overwritten = output.writeFile(file, displayPath, result);
    }

    // Show the user.
    if (show.file(displayPath, changed: changed, overwritten: overwritten)) {
      output.showFile(displayPath, result);
    }

    // Set the exit code.
    if (setExitIfChanged && changed) exitCode = 1;
  }

  /// Describes the directory whose contents are about to be processed.
  void showDirectory(String path) {
    if (output != Output.json) {
      show.directory(path);
    }
  }

  /// Describes the symlink at [path] that wasn't followed.
  void showSkippedLink(String path) {
    show.skippedLink(path);
  }

  /// Describes the hidden [path] that wasn't processed.
  void showHiddenPath(String path) {
    show.hiddenPath(path);
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PreprocessorOptions {
  /// Generate polyfill code (e.g., var, etc.)
  final bool polyfill;

  /// Report warnings as errors.
  final bool warningsAsErrors;

  /// Throw an exception on warnings (not used by command line tool).
  final bool throwOnWarnings;

  /// Throw an exception on errors (not used by command line tool).
  final bool throwOnErrors;

  /// True to show informational messages. The `--verbose` flag.
  final bool verbose;

  /// True to show warning messages for bad CSS.  The '--checked' flag.
  final bool checked;

  // TODO(terry): Add mixin support and nested rules.
  /// Subset of Less commands enabled; disable with '--no-less'.
  /// Less syntax supported:
  /// - @name at root level statically defines variables resolved at compilation
  /// time.  Essentially a directive e.g., @var-name.
  final bool lessSupport;

  /// Whether to use colors to print messages on the terminal.
  final bool useColors;

  /// File to process by the compiler.
  final String? inputFile;

  const PreprocessorOptions(
      {this.verbose = false,
      this.checked = false,
      this.lessSupport = true,
      this.warningsAsErrors = false,
      this.throwOnErrors = false,
      this.throwOnWarnings = false,
      this.useColors = true,
      this.polyfill = false,
      this.inputFile});
}

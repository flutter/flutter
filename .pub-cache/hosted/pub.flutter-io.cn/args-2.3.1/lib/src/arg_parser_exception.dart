// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An exception thrown by `ArgParser`.
class ArgParserException extends FormatException {
  /// The command(s) that were parsed before discovering the error.
  ///
  /// This will be empty if the error was on the root parser.
  final List<String> commands;

  ArgParserException(String message, [Iterable<String>? commands])
      : commands = commands == null ? const [] : List.unmodifiable(commands),
        super(message);
}

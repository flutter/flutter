// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'artifacts.dart';
import 'base/config.dart';
import 'base/context.dart';
import 'base/io.dart' as io;
import 'base/logger.dart';
import 'base/terminal.dart';
import 'cache.dart';

Logger get logger => context[Logger];
Cache get cache => Cache.instance;
Config get config => Config.instance;
Artifacts get artifacts => Artifacts.instance;

/// Display an error level message to the user. Commands should use this if they
/// fail in some way.
///
/// Set [emphasis] to true to make the output bold if it's supported.
/// Set [color] to a [TerminalColor] to color the output, if the logger
/// supports it. The [color] defaults to [TerminalColor.red].
void printError(
  String message, {
  StackTrace stackTrace,
  bool emphasis,
  TerminalColor color,
}) {
  logger.printError(
    wrapText(message),
    stackTrace: stackTrace,
    emphasis: emphasis ?? false,
    color: color,
  );
}

/// Display normal output of the command. This should be used for things like
/// progress messages, success messages, or just normal command output.
///
/// Set `emphasis` to true to make the output bold if it's supported.
///
/// Set `newline` to false to skip the trailing linefeed.
///
/// If `indent` is provided, each line of the message will be prepended by the
/// specified number of whitespaces.
void printStatus(
  String message, {
  bool emphasis,
  bool newline,
  TerminalColor color,
  int indent,
}) {
  logger.printStatus(
    wrapText(message, indent: indent),
    emphasis: emphasis ?? false,
    color: color,
    newline: newline ?? true,
    indent: indent,
  );
}

/// Use this for verbose tracing output. Users can turn this output on in order
/// to help diagnose issues with the toolchain or with their setup.
void printTrace(String message) => logger.printTrace(message);

/// The terminal width used by the [wrapText] function if there is no terminal
/// attached to [io.Stdio].
const int kDefaultTerminalColumns = 100;

// Smallest column that will be used. If the requested column width is smaller
// than this, then this is what will be used.
const int _kMinColumnWidth = 10;

/// Wraps a block of text into lines no longer than [columnWidth].
///
/// Tries to split at whitespace, but if that's not good enough to keep it
/// under the limit, then it splits in the middle of a word.
///
/// Preserves indentation (leading whitespace) for each line (delimited by '\n')
/// in the input, and will indent wrapped lines the same amount.
///
/// If [hangingIndent] is supplied, then that many spaces will be added to each
/// line, except for the first line. This is useful for flowing text with a
/// heading prefix (e.g. "Usage: "):
///
/// ```dart
/// String prefix = "Usage: ";
/// print(prefix + wrapText(invocation, hangingIndent: prefix.length, columnWidth: 40));
/// ```
///
/// yields:
/// ```
/// Usage: app main_command <subcommand>
///        [arguments]
/// ```
///
/// If [columnWidth] is not specified, then the column width will be the width of the
/// terminal window by default. If the stdout is not a terminal window, then the
/// default will be [kDefaultTerminalColumns].
///
/// The [indent] must be smaller than [columnWidth].
String wrapText(String text, {int columnWidth, int hangingIndent, int indent}) {
  if (text == null || text.isEmpty) {
    return '';
  }
  indent ??= 0;
  columnWidth ??= (const io.Stdio().terminalColumns ?? kDefaultTerminalColumns) - indent;
  assert(columnWidth >= 0);

  hangingIndent ??= 0;
  final List<String> splitText = text.split('\n');
  final List<String> result = <String>[];
  for (String line in splitText) {
    String trimmedText = line.trimLeft();
    final String leadingWhitespace =
    line.substring(0, line.length - trimmedText.length);
    List<String> notIndented;
    if (hangingIndent != 0) {
      // When we have a hanging indent, we want to wrap the first line at one
      // width, and the rest at another (offset by hangingIndent), so we wrap
      // them twice and recombine.
      final List<String> firstLineWrap = _wrapTextAsLines(
        trimmedText,
        columnWidth: columnWidth - leadingWhitespace.length,
      );
      notIndented = <String>[firstLineWrap.removeAt(0)];
      trimmedText = trimmedText.substring(notIndented[0].length).trimLeft();
      if (firstLineWrap.isNotEmpty) {
        notIndented.addAll(_wrapTextAsLines(
          trimmedText,
          columnWidth: columnWidth - leadingWhitespace.length - hangingIndent,
        ));
      }
    } else {
      notIndented = _wrapTextAsLines(
        trimmedText,
        columnWidth: columnWidth - leadingWhitespace.length,
      );
    }
    String hangingIndentString;
    final String indentString = ' ' * indent;
    result.addAll(notIndented.map(
        (String line) {
        // Don't return any lines with just whitespace on them.
        if (line.isEmpty) {
          return '';
        }
        final String result = '$indentString${hangingIndentString ?? ''}$leadingWhitespace$line';
        hangingIndentString ??= ' ' * hangingIndent;
        return result;
      },
    ));
  }
  return result.join('\n');
}

/// Wraps a block of text into lines no longer than [columnWidth], starting at the
/// [start] column, and returning the result as a list of strings.
///
/// Tries to split at whitespace, but if that's not good enough to keep it
/// under the limit, then splits in the middle of a word. Preserves embedded
/// newlines, but not indentation (it trims whitespace from each line).
///
/// If [columnWidth] is not specified, then the column width will be the width of the
/// terminal window by default. If the stdout is not a terminal window, then the
/// default will be [kDefaultTerminalColumns].
List<String> _wrapTextAsLines(String text, {int start = 0, int columnWidth}) {
  if (text == null || text.isEmpty) {
    return <String>[];
  }
  columnWidth ??= const io.Stdio().terminalColumns ?? kDefaultTerminalColumns;
  assert(columnWidth >= 0);
  assert(start >= 0);

  /// Returns true if the code unit at [index] in [text] is a whitespace
  /// character.
  ///
  /// Based on: https://en.wikipedia.org/wiki/Whitespace_character#Unicode
  bool isWhitespace(String text, int index) {
    final int rune = text.codeUnitAt(index);
    return rune >= 0x0009 && rune <= 0x000D
        || rune == 0x0020
        || rune == 0x0085
        || rune == 0x1680
        || rune == 0x180E
        || rune >= 0x2000 && rune <= 0x200A
        || rune == 0x2028
        || rune == 0x2029
        || rune == 0x202F
        || rune == 0x205F
        || rune == 0x3000
        || rune == 0xFEFF;
  }

  final List<String> result = <String>[];
  final int effectiveLength = math.max(columnWidth - start, _kMinColumnWidth);
  for (String line in text.split('\n')) {
    line = line.trim();
    if (line.length <= effectiveLength) {
      result.add(line);
      continue;
    }

    int currentLineStart = 0;
    int lastWhitespace;
    for (int index = 0; index < line.length; ++index) {
      if (isWhitespace(line, index)) {
        lastWhitespace = index;
      }

      if (index - currentLineStart >= effectiveLength) {
        // Back up to the last whitespace, unless there wasn't any, in which
        // case we just split where we are.
        if (lastWhitespace != null) {
          index = lastWhitespace;
        }

        result.add(line.substring(currentLineStart, index).trim());

        // Skip any intervening whitespace.
        while (isWhitespace(line, index) && index < line.length) {
          index++;
        }

        currentLineStart = index;
        lastWhitespace = null;
      }
    }
    result.add(line.substring(currentLineStart).trim());
  }
  return result;
}

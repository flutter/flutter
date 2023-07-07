// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../args.dart';
import 'utils.dart';

/// Generates a string of usage (i.e. help) text for a list of options.
///
/// Internally, it works like a tabular printer. The output is divided into
/// three horizontal columns, like so:
///
///     -h, --help  Prints the usage information
///     |  |        |                                 |
///
/// It builds the usage text up one column at a time and handles padding with
/// spaces and wrapping to the next line to keep the cells correctly lined up.
///
/// [lineLength] specifies the horizontal character position at which the help
/// text is wrapped. Help that extends past this column will be wrapped at the
/// nearest whitespace (or truncated if there is no available whitespace). If
/// `null` there will not be any wrapping.
String generateUsage(List optionsAndSeparators, {int? lineLength}) =>
    _Usage(optionsAndSeparators, lineLength).generate();

class _Usage {
  /// Abbreviation, long name, help.
  static const _columnCount = 3;

  /// A list of the [Option]s intermingled with [String] separators.
  final List _optionsAndSeparators;

  /// The working buffer for the generated usage text.
  final _buffer = StringBuffer();

  /// The column that the "cursor" is currently on.
  ///
  /// If the next call to [write()] is not for this column, it will correctly
  /// handle advancing to the next column (and possibly the next row).
  int _currentColumn = 0;

  /// The width in characters of each column.
  late final _columnWidths = _calculateColumnWidths();

  /// How many newlines need to be rendered before the next bit of text can be
  /// written.
  ///
  /// We do this lazily so that the last bit of usage doesn't have dangling
  /// newlines. We only write newlines right *before* we write some real
  /// content.
  int _newlinesNeeded = 0;

  /// The horizontal character position at which help text is wrapped.
  ///
  /// Help that extends past this column will be wrapped at the nearest
  /// whitespace (or truncated if there is no available whitespace).
  final int? lineLength;

  _Usage(this._optionsAndSeparators, this.lineLength);

  /// Generates a string displaying usage information for the defined options.
  /// This is basically the help text shown on the command line.
  String generate() {
    for (var optionOrSeparator in _optionsAndSeparators) {
      if (optionOrSeparator is String) {
        _writeSeparator(optionOrSeparator);
        continue;
      }
      var option = optionOrSeparator as Option;
      if (option.hide) continue;
      _writeOption(option);
    }

    return _buffer.toString();
  }

  void _writeSeparator(String separator) {
    // Ensure that there's always a blank line before a separator.
    if (_buffer.isNotEmpty) _buffer.write('\n\n');
    _buffer.write(separator);
    _newlinesNeeded = 1;
  }

  void _writeOption(Option option) {
    _write(0, _abbreviation(option));
    _write(1, '${_longOption(option)}${_mandatoryOption(option)}');

    if (option.help != null) _write(2, option.help!);

    if (option.allowedHelp != null) {
      var allowedNames = option.allowedHelp!.keys.toList();
      allowedNames.sort();
      _newline();
      for (var name in allowedNames) {
        _write(1, _allowedTitle(option, name));
        _write(2, option.allowedHelp![name]!);
      }
      _newline();
    } else if (option.allowed != null) {
      _write(2, _buildAllowedList(option));
    } else if (option.isFlag) {
      if (option.defaultsTo == true) {
        _write(2, '(defaults to on)');
      }
    } else if (option.isMultiple) {
      if (option.defaultsTo != null && option.defaultsTo.isNotEmpty) {
        var defaults =
            (option.defaultsTo as List).map((value) => '"$value"').join(', ');
        _write(2, '(defaults to $defaults)');
      }
    } else if (option.defaultsTo != null) {
      _write(2, '(defaults to "${option.defaultsTo}")');
    }
  }

  String _abbreviation(Option option) =>
      option.abbr == null ? '' : '-${option.abbr}, ';

  String _longOption(Option option) {
    String result;
    if (option.negatable!) {
      result = '--[no-]${option.name}';
    } else {
      result = '--${option.name}';
    }

    if (option.valueHelp != null) result += '=<${option.valueHelp}>';

    return result;
  }

  String _mandatoryOption(Option option) {
    return option.mandatory ? ' (mandatory)' : '';
  }

  String _allowedTitle(Option option, String allowed) {
    var isDefault = option.defaultsTo is List
        ? option.defaultsTo.contains(allowed)
        : option.defaultsTo == allowed;
    return '      [$allowed]' + (isDefault ? ' (default)' : '');
  }

  List<int> _calculateColumnWidths() {
    var abbr = 0;
    var title = 0;
    for (var option in _optionsAndSeparators) {
      if (option is! Option) continue;
      if (option.hide) continue;

      // Make room in the first column if there are abbreviations.
      abbr = math.max(abbr, _abbreviation(option).length);

      // Make room for the option.
      title = math.max(
          title, _longOption(option).length + _mandatoryOption(option).length);

      // Make room for the allowed help.
      if (option.allowedHelp != null) {
        for (var allowed in option.allowedHelp!.keys) {
          title = math.max(title, _allowedTitle(option, allowed).length);
        }
      }
    }

    // Leave a gutter between the columns.
    title += 4;
    return [abbr, title];
  }

  void _newline() {
    _newlinesNeeded++;
    _currentColumn = 0;
  }

  void _write(int column, String text) {
    var lines = text.split('\n');
    // If we are writing the last column, word wrap it to fit.
    if (column == _columnWidths.length && lineLength != null) {
      var start =
          _columnWidths.take(column).reduce((start, width) => start + width);
      lines = [
        for (var line in lines)
          ...wrapTextAsLines(line, start: start, length: lineLength),
      ];
    }

    // Strip leading and trailing empty lines.
    while (lines.isNotEmpty && lines.first.trim() == '') {
      lines.removeAt(0);
    }
    while (lines.isNotEmpty && lines.last.trim() == '') {
      lines.removeLast();
    }

    for (var line in lines) {
      _writeLine(column, line);
    }
  }

  void _writeLine(int column, String text) {
    // Write any pending newlines.
    while (_newlinesNeeded > 0) {
      _buffer.write('\n');
      _newlinesNeeded--;
    }

    // Advance until we are at the right column (which may mean wrapping around
    // to the next line.
    while (_currentColumn != column) {
      if (_currentColumn < _columnCount - 1) {
        _buffer.write(' ' * _columnWidths[_currentColumn]);
      } else {
        _buffer.write('\n');
      }
      _currentColumn = (_currentColumn + 1) % _columnCount;
    }

    if (column < _columnWidths.length) {
      // Fixed-size column, so pad it.
      _buffer.write(text.padRight(_columnWidths[column]));
    } else {
      // The last column, so just write it.
      _buffer.write(text);
    }

    // Advance to the next column.
    _currentColumn = (_currentColumn + 1) % _columnCount;

    // If we reached the last column, we need to wrap to the next line.
    if (column == _columnCount - 1) _newlinesNeeded++;
  }

  String _buildAllowedList(Option option) {
    var isDefault = option.defaultsTo is List
        ? option.defaultsTo.contains
        : (value) => value == option.defaultsTo;

    var allowedBuffer = StringBuffer();
    allowedBuffer.write('[');
    var first = true;
    for (var allowed in option.allowed!) {
      if (!first) allowedBuffer.write(', ');
      allowedBuffer.write(allowed);
      if (isDefault(allowed)) {
        allowedBuffer.write(' (default)');
      }
      first = false;
    }
    allowedBuffer.write(']');
    return allowedBuffer.toString();
  }
}

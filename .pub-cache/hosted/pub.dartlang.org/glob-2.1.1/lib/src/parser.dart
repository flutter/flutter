// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:string_scanner/string_scanner.dart';

import 'ast.dart';
import 'utils.dart';

const _hyphen = 0x2D;
const _slash = 0x2F;

/// A parser for globs.
class Parser {
  /// The scanner used to scan the source.
  final StringScanner _scanner;

  /// The path context for the glob.
  final p.Context _context;

  /// Whether this glob is case-sensitive.
  final bool _caseSensitive;

  Parser(String component, this._context, {bool caseSensitive = true})
      : _scanner = StringScanner(component),
        _caseSensitive = caseSensitive;

  /// Parses an entire glob.
  SequenceNode parse() => _parseSequence();

  /// Parses a [SequenceNode].
  ///
  /// If [inOptions] is true, this is parsing within an [OptionsNode].
  SequenceNode _parseSequence({bool inOptions = false}) {
    var nodes = <AstNode>[];

    if (_scanner.isDone) {
      _scanner.error('expected a glob.', position: 0, length: 0);
    }

    while (!_scanner.isDone) {
      if (inOptions && (_scanner.matches(',') || _scanner.matches('}'))) break;
      nodes.add(_parseNode(inOptions: inOptions));
    }

    return SequenceNode(nodes, caseSensitive: _caseSensitive);
  }

  /// Parses an [AstNode].
  ///
  /// If [inOptions] is true, this is parsing within an [OptionsNode].
  AstNode _parseNode({bool inOptions = false}) {
    var star = _parseStar();
    if (star != null) return star;

    var anyChar = _parseAnyChar();
    if (anyChar != null) return anyChar;

    var range = _parseRange();
    if (range != null) return range;

    var options = _parseOptions();
    if (options != null) return options;

    return _parseLiteral(inOptions: inOptions);
  }

  /// Tries to parse a [StarNode] or a [DoubleStarNode].
  ///
  /// Returns `null` if there's not one to parse.
  AstNode? _parseStar() {
    if (!_scanner.scan('*')) return null;
    return _scanner.scan('*')
        ? DoubleStarNode(_context, caseSensitive: _caseSensitive)
        : StarNode(caseSensitive: _caseSensitive);
  }

  /// Tries to parse an [AnyCharNode].
  ///
  /// Returns `null` if there's not one to parse.
  AstNode? _parseAnyChar() {
    if (!_scanner.scan('?')) return null;
    return AnyCharNode(caseSensitive: _caseSensitive);
  }

  /// Tries to parse an [RangeNode].
  ///
  /// Returns `null` if there's not one to parse.
  AstNode? _parseRange() {
    if (!_scanner.scan('[')) return null;
    if (_scanner.matches(']')) _scanner.error('unexpected "]".');
    var negated = _scanner.scan('!') || _scanner.scan('^');

    int readRangeChar() {
      var char = _scanner.readChar();
      if (negated || char != _slash) return char;
      _scanner.error('"/" may not be used in a range.',
          position: _scanner.position - 1);
    }

    var ranges = <Range>[];
    while (!_scanner.scan(']')) {
      var start = _scanner.position;
      // Allow a backslash to escape a character.
      _scanner.scan('\\');
      var char = readRangeChar();

      if (_scanner.scan('-')) {
        if (_scanner.matches(']')) {
          ranges.add(Range.singleton(char));
          ranges.add(Range.singleton(_hyphen));
          continue;
        }

        // Allow a backslash to escape a character.
        _scanner.scan('\\');

        var end = readRangeChar();

        if (end < char) {
          _scanner.error('Range out of order.',
              position: start, length: _scanner.position - start);
        }
        ranges.add(Range(char, end));
      } else {
        ranges.add(Range.singleton(char));
      }
    }

    return RangeNode(ranges, negated: negated, caseSensitive: _caseSensitive);
  }

  /// Tries to parse an [OptionsNode].
  ///
  /// Returns `null` if there's not one to parse.
  AstNode? _parseOptions() {
    if (!_scanner.scan('{')) return null;
    if (_scanner.matches('}')) _scanner.error('unexpected "}".');

    var options = <SequenceNode>[];
    do {
      options.add(_parseSequence(inOptions: true));
    } while (_scanner.scan(','));

    // Don't allow single-option blocks.
    if (options.length == 1) _scanner.expect(',');
    _scanner.expect('}');

    return OptionsNode(options, caseSensitive: _caseSensitive);
  }

  /// Parses a [LiteralNode].
  AstNode _parseLiteral({bool inOptions = false}) {
    // If we're in an options block, we want to stop parsing as soon as we hit a
    // comma. Otherwise, commas are fair game for literals.
    var regExp = RegExp(inOptions ? r'[^*{[?\\}\],()]*' : r'[^*{[?\\}\]()]*');

    _scanner.scan(regExp);
    var buffer = StringBuffer()..write(_scanner.lastMatch![0]);

    while (_scanner.scan('\\')) {
      buffer.writeCharCode(_scanner.readChar());
      _scanner.scan(regExp);
      buffer.write(_scanner.lastMatch![0]);
    }

    for (var char in const [']', '(', ')']) {
      if (_scanner.matches(char)) _scanner.error('unexpected "$char"');
    }
    if (!inOptions && _scanner.matches('}')) _scanner.error('unexpected "}"');

    return LiteralNode(buffer.toString(),
        context: _context, caseSensitive: _caseSensitive);
  }
}

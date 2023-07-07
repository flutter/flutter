import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../matcher/matches.dart';
import '../parser/action/token.dart';
import '../parser/misc/newline.dart';
import 'parser.dart';

/// A token represents a parsed part of the input stream.
///
/// The token holds the resulting value of the input, the input buffer,
/// and the start and stop position in the input buffer. It provides many
/// convenience methods to access the state of the token.
@immutable
class Token<T> {
  /// Constructs a token from the parsed value, the input buffer, and the
  /// start and stop position in the input buffer.
  const Token(this.value, this.buffer, this.start, this.stop);

  /// The parsed value of the token.
  final T value;

  /// The parsed buffer of the token.
  final String buffer;

  /// The start position of the token in the buffer.
  final int start;

  /// The stop position of the token in the buffer.
  final int stop;

  /// The consumed input of the token.
  String get input => buffer.substring(start, stop);

  /// The length of the token.
  int get length => stop - start;

  /// The line number of the token.
  int get line => Token.lineAndColumnOf(buffer, start)[0];

  /// The column number of this token.
  int get column => Token.lineAndColumnOf(buffer, start)[1];

  /// Converts the value of the token.
  Token<R> map<R>(R Function(T value) mapper) =>
      Token(mapper(value), buffer, start, stop);

  @override
  String toString() => 'Token[${positionString(buffer, start)}]: $value';

  @override
  bool operator ==(Object other) =>
      other is Token &&
      value == other.value &&
      start == other.start &&
      stop == other.stop;

  @override
  int get hashCode => value.hashCode + start.hashCode + stop.hashCode;

  /// Combines multiple token into a single token with the list of its values.
  static Token<List<T>> join<T>(Iterable<Token<T>> token) {
    final iterator = token.iterator;
    if (!iterator.moveNext()) {
      throw ArgumentError.value(token, 'token', 'Require at least one token');
    }
    final value = <T>[iterator.current.value];
    final buffer = iterator.current.buffer;
    var start = iterator.current.start;
    var stop = iterator.current.stop;
    while (iterator.moveNext()) {
      if (buffer != iterator.current.buffer) {
        throw ArgumentError.value(
            token, 'token', 'Token do not use same buffer');
      }
      value.add(iterator.current.value);
      start = math.min(start, iterator.current.start);
      stop = math.max(stop, iterator.current.stop);
    }
    return Token(value, buffer, start, stop);
  }

  /// Returns a parser that detects newlines platform independently.
  static Parser<String> newlineParser() => _newlineParser;
  static final Parser<String> _newlineParser = newline();

  /// Converts the [position] index in a [buffer] to a line and column tuple.
  static List<int> lineAndColumnOf(String buffer, int position) {
    var line = 1, offset = 0;
    for (final token in newlineParser().token().allMatches(buffer)) {
      if (position < token.stop) {
        return [line, position - offset + 1];
      }
      line++;
      offset = token.stop;
    }
    return [line, position - offset + 1];
  }

  /// Returns a human readable string representing the [position] index in a
  /// [buffer].
  static String positionString(String buffer, int position) {
    final lineAndColumn = lineAndColumnOf(buffer, position);
    return '${lineAndColumn[0]}:${lineAndColumn[1]}';
  }
}

import 'package:meta/meta.dart';

import '../core/parser.dart';
import '../parser/action/map.dart';
import '../parser/combinator/choice.dart';
import '../parser/combinator/sequence.dart';
import '../parser/repeater/possessive.dart';
import '../parser/repeater/separated.dart';
import 'result.dart';

/// Models a group of operators of the same precedence.
class ExpressionGroup<T> {
  @internal
  ExpressionGroup(this._loopback);

  /// Loopback parser used to establish the recursive expressions.
  final Parser<T> _loopback;

  /// Defines a new primitive or literal [parser].
  void primitive(Parser<T> parser) => _primitive.add(parser);

  Parser<T> _buildPrimitive(Parser<T> inner) => _buildChoice(_primitive, inner);

  final List<Parser<T>> _primitive = [];

  /// Defines a new wrapper using [left] and [right] parsers, that are typically
  /// used for parenthesis. Evaluates the [callback] with the parsed `left`
  /// delimiter, the `value` and `right` delimiter.
  void wrapper<L, R>(Parser<L> left, Parser<R> right,
          T Function(L left, T value, R right) callback) =>
      _wrapper.add(seq3(left, _loopback, right).map3(callback));

  Parser<T> _buildWrapper(Parser<T> inner) =>
      _buildChoice([..._wrapper, inner]);

  final List<Parser<T>> _wrapper = [];

  /// Adds a prefix operator [parser]. Evaluates the [callback] with the parsed
  /// `operator` and `value`.
  void prefix<O>(Parser<O> parser, T Function(O operator, T value) callback) =>
      _prefix.add(parser
          .map((operator) => ExpressionResultPrefix<T, O>(operator, callback)));

  Parser<T> _buildPrefix(Parser<T> inner) {
    if (_prefix.isEmpty) {
      return inner;
    } else {
      return seq2(_buildChoice(_prefix).star(), inner).map2((prefix, value) =>
          prefix.reversed.fold(value, (each, result) => result(each)));
    }
  }

  final List<Parser<ExpressionResultPrefix<T, void>>> _prefix = [];

  /// Adds a postfix operator [parser]. Evaluates the [callback] with the parsed
  /// `value` and `operator`.
  void postfix<O>(Parser<O> parser, T Function(T value, O operator) callback) =>
      _postfix.add(parser.map(
          (operator) => ExpressionResultPostfix<T, O>(operator, callback)));

  Parser<T> _buildPostfix(Parser<T> inner) {
    if (_postfix.isEmpty) {
      return inner;
    } else {
      return seq2(inner, _buildChoice(_postfix).star()).map2((value, postfix) =>
          postfix.fold(value, (each, result) => result(each)));
    }
  }

  final List<Parser<ExpressionResultPostfix<T, void>>> _postfix = [];

  /// Adds a right-associative operator [parser]. Evaluates the [callback] with
  /// the parsed `left` term, `operator`, and `right` term.
  void right<O>(
          Parser<O> parser, T Function(T left, O operator, T right) callback) =>
      _right.add(parser
          .map((operator) => ExpressionResultInfix<T, O>(operator, callback)));

  Parser<T> _buildRight(Parser<T> inner) {
    if (_right.isEmpty) {
      return inner;
    } else {
      return inner
          .plusSeparated(_buildChoice(_right))
          .map((sequence) => sequence.foldRight((a, b, c) => b(a, c)));
    }
  }

  final List<Parser<ExpressionResultInfix<T, void>>> _right = [];

  /// Adds a left-associative operator [parser]. Evaluates the [callback] with
  /// the parsed `left` term, `operator`, and `right` term.
  void left<O>(
          Parser<O> parser, T Function(T left, O operator, T right) callback) =>
      _left.add(parser
          .map((operator) => ExpressionResultInfix<T, O>(operator, callback)));

  Parser<T> _buildLeft(Parser<T> inner) {
    if (_left.isEmpty) {
      return inner;
    } else {
      return inner
          .plusSeparated(_buildChoice(_left))
          .map((sequence) => sequence.foldLeft((a, b, c) => b(a, c)));
    }
  }

  final List<Parser<ExpressionResultInfix<T, void>>> _left = [];

  // Internal helper to build the group of parsers.
  @internal
  Parser<T> build(Parser<T> inner) => _buildLeft(_buildRight(
      _buildPostfix(_buildPrefix(_buildWrapper(_buildPrimitive(inner))))));
}

// Internal helper to build an optimal choice parser.
Parser<T> _buildChoice<T>(List<Parser<T>> parsers, [Parser<T>? otherwise]) {
  if (parsers.isEmpty) {
    return otherwise!;
  } else if (parsers.length == 1) {
    return parsers.first;
  } else {
    return parsers.toChoiceParser();
  }
}

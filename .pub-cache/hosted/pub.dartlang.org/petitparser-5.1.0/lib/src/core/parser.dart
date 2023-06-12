import 'package:meta/meta.dart';

import '../context/context.dart';
import '../context/failure.dart';
import '../context/result.dart';
import '../context/success.dart';

/// Abstract base class of all parsers that produce a parse result of type [R].
@optionalTypeArgs
abstract class Parser<R> {
  Parser();

  /// Primitive method doing the actual parsing.
  ///
  /// The method is overridden in concrete subclasses to implement the
  /// parser specific logic. The methods takes a parse [context] and
  /// returns the resulting context, which is either a [Success] or
  /// [Failure] context.
  Result<R> parseOn(Context context);

  /// Primitive method doing the actual parsing.
  ///
  /// This method is an optimized version of [Parser.parseOn] that is getting
  /// its speed advantage by avoiding any unnecessary memory allocations.
  ///
  /// The method is overridden in most concrete subclasses to implement the
  /// optimized logic. As an input the method takes a [buffer] and the current
  /// [position] in that buffer. It returns a new (positive) position in case
  /// of a successful parse, or `-1` in case of a failure.
  ///
  /// Subclasses don't necessarily have to override this method, since it is
  /// emulated using its slower brother.
  int fastParseOn(String buffer, int position) {
    final result = parseOn(Context(buffer, position));
    return result.isSuccess ? result.position : -1;
  }

  /// Returns the parse result of the [input].
  ///
  /// The implementation creates a default parse context on the input and calls
  /// the internal parsing logic of the receiving parser.
  ///
  /// For example, `letter().plus().parse('abc')` results in an instance of
  /// [Success], where [Context.position] is `3` and [Success.value] is
  /// `[a, b, c]`.
  ///
  /// Similarly, `letter().plus().parse('123')` results in an instance of
  /// [Failure], where [Context.position] is `0` and [Failure.message] is
  /// ['letter expected'].
  @nonVirtual
  Result<R> parse(String input) => parseOn(Context(input, 0));

  /// Returns a shallow copy of the receiver.
  ///
  /// Override this method in all subclasses, return its own type.
  Parser<R> copy();

  /// Recursively tests for structural equality of two parsers.
  ///
  /// The code automatically deals with recursive parsers and parsers that
  /// refer to other parsers. Do not override this method, instead customize
  /// [Parser.hasEqualProperties] and [Parser.children].
  @nonVirtual
  bool isEqualTo(Parser other, [Set<Parser>? seen]) {
    if (this == other) {
      return true;
    }
    if (runtimeType != other.runtimeType || !hasEqualProperties(other)) {
      return false;
    }
    seen ??= {};
    return !seen.add(this) || hasEqualChildren(other, seen);
  }

  /// Compare the properties of two parsers.
  ///
  /// Override this method in all subclasses that add new state.
  @protected
  @mustCallSuper
  bool hasEqualProperties(covariant Parser other) => true;

  /// Compare the children of two parsers.
  ///
  /// Normally this method does not need to be overridden, as this method works
  /// generically on the returned [Parser.children].
  @protected
  @nonVirtual
  bool hasEqualChildren(covariant Parser other, Set<Parser> seen) {
    final thisChildren = children, otherChildren = other.children;
    if (thisChildren.length != otherChildren.length) {
      return false;
    }
    for (var i = 0; i < thisChildren.length; i++) {
      if (!thisChildren[i].isEqualTo(otherChildren[i], seen)) {
        return false;
      }
    }
    return true;
  }

  /// Returns a list of directly referenced parsers.
  ///
  /// For example, `letter().children` returns the empty collection `[]`,
  /// because the letter parser is a primitive or leaf parser that does not
  /// depend or call any other parser.
  ///
  /// In contrast, `letter().or(digit()).children` returns a collection
  /// containing both the `letter()` and `digit()` parser.
  ///
  /// Override this method and [Parser.replace] in all subclasses that
  /// reference other parsers.
  List<Parser> get children => const [];

  /// Changes the receiver by replacing [source] with [target]. Does nothing
  /// if [source] does not exist in [Parser.children].
  ///
  /// The following example creates a letter parser and then defines a parser
  /// called `example` that accepts one or more letters. Eventually the parser
  /// `example` is modified by replacing the `letter` parser with a new
  /// parser that accepts a digit. The resulting `example` parser accepts one
  /// or more digits.
  ///
  ///     final letter = letter();
  ///     final example = letter.plus();
  ///     example.replace(letter, digit());
  ///
  /// Override this method and [Parser.children] in all subclasses that
  /// reference other parsers.
  @mustCallSuper
  void replace(Parser source, Parser target) {}

  /// Internal helper to capture the generic type [R] of the parse result from
  /// extension methods. This makes it possible to wrap the parser without
  /// loosing type information.
  @internal
  @nonVirtual
  T captureResultGeneric<T>(T Function<R>(Parser<R> self) callback) =>
      callback<R>(this);
}

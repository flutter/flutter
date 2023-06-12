import '../context/context.dart';
import '../context/result.dart';
import '../core/parser.dart';
import '../parser/action/continuation.dart';
import '../reflection/transform.dart';
import '../shared/types.dart';

/// Returns a transformed [Parser] that when being used to read input prints a
/// trace of all activated parsers and their respective parse results.
///
/// For example, the snippet
///
///     final parser = letter() & word().star();
///     trace(parser).parse('f1');
///
/// produces the following output:
///
///     Instance of 'SequenceParser<dynamic>'
///       Instance of 'CharacterParser'[letter expected]
///       Success[1:2]: f
///       Instance of 'PossessiveRepeatingParser<String>'[0..*]
///         Instance of 'CharacterParser'[letter or digit expected]
///         Success[1:3]: 1
///         Instance of 'CharacterParser'[letter or digit expected]
///         Failure[1:3]: letter or digit expected
///       Success[1:3]: [1]
///     Success[1:3]: [f, [1]]
///
/// Indentation signifies the activation of a parser object. Reverse indentation
/// signifies the returning of a parse result either with a success or failure
/// context.
///
/// The optional [output] callback can be used to continuously receive
/// [TraceEvent] objects with current enter and exit data.
Parser<T> trace<T>(Parser<T> root,
    {VoidCallback<TraceEvent> output = print, Predicate<Parser>? predicate}) {
  TraceEvent? parent;
  return transformParser(root, <T>(parser) {
    if (predicate == null || predicate(parser)) {
      return parser.callCC((continuation, context) {
        final currentParent = parent;
        output(parent = _TraceEvent(currentParent, parser, context));
        final result = continuation(context);
        output(_TraceEvent(currentParent, parser, context, result));
        parent = currentParent;
        return result;
      });
    } else {
      return parser;
    }
  });
}

/// Encapsulates the entry and exit data around a parser trace.
abstract class TraceEvent {
  /// Returns the parent trace event.
  TraceEvent? get parent;

  /// Returns the parser of this event.
  Parser get parser;

  /// Returns the activation context of this event.
  Context get context;

  /// Returns the result if this is a exit event, otherwise `null`.
  Result? get result;

  /// Returns the nesting level of this event.
  int get level => parent != null ? parent!.level + 1 : 0;
}

class _TraceEvent extends TraceEvent {
  _TraceEvent(this.parent, this.parser, this.context, [this.result]);

  @override
  final TraceEvent? parent;

  @override
  final Parser parser;

  @override
  final Context context;

  @override
  final Result? result;

  @override
  String toString() => '${'  ' * level}${result ?? parser}';
}

import '../core/parser.dart';
import '../parser/action/continuation.dart';
import '../reflection/transform.dart';
import '../shared/types.dart';

/// Returns a transformed [Parser] that when being used measures
/// the activation count and total time of each parser.
///
/// For example, the snippet
///
///     final parser = letter() & word().star();
///     profile(parser).parse('f1234567890');
///
/// prints the following output:
///
///      1  2006  Instance of 'SequenceParser'
///      1   697  Instance of 'PossessiveRepeatingParser'[0..*]
///     11   406  Instance of 'CharacterParser'[letter or digit expected]
///      1   947  Instance of 'CharacterParser'[letter expected]
///
/// The first number refers to the number of activations of each parser, and
/// the second number is the microseconds spent in this parser and all its
/// children.
///
/// The optional [output] callback can be used to receive [ProfileFrame]
/// objects with the full profiling information at the end of the parse.
Parser<T> profile<T>(Parser<T> root,
    {VoidCallback<ProfileFrame> output = print, Predicate<Parser>? predicate}) {
  final frames = <ProfileFrame>[];
  return transformParser(root, <T>(parser) {
    if (predicate == null || predicate(parser)) {
      final frame = _ProfileFrame(parser);
      frames.add(frame);
      return parser.callCC((continuation, context) {
        frame.count++;
        frame.stopwatch.start();
        final result = continuation(context);
        frame.stopwatch.stop();
        return result;
      });
    } else {
      return parser;
    }
  }).callCC((continuation, context) {
    final result = continuation(context);
    frames.forEach(output);
    return result;
  });
}

/// Encapsulates the data around a parser profile.
abstract class ProfileFrame {
  /// Return the parser of this frame.
  Parser get parser;

  /// Return the number of times this parser was activated.
  int get count;

  /// Return the total elapsed time in this parser and its children.
  Duration get elapsed;
}

class _ProfileFrame extends ProfileFrame {
  _ProfileFrame(this.parser);

  final stopwatch = Stopwatch();

  @override
  final Parser parser;

  @override
  int count = 0;

  @override
  Duration get elapsed => stopwatch.elapsed;

  @override
  String toString() => '$count\t${elapsed.inMicroseconds}\t$parser';
}

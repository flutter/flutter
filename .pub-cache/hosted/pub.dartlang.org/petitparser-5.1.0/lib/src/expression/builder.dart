import '../core/parser.dart';
import '../definition/resolve.dart';
import '../parser/combinator/settable.dart';
import '../parser/misc/failure.dart';
import 'group.dart';

/// A builder that allows the simple definition of expression grammars with
/// prefix, postfix, and left- and right-associative infix operators.
///
/// The following code creates the empty expression builder that produces
/// values of type [num]:
///
///     final builder = new ExpressionBuilder<num>();
///
/// Then we define the operator-groups in descending precedence. The highest
/// precedence have the literal numbers themselves:
///
///     builder.group()
///       ..primitive(digit().plus()
///         .seq(char('.').seq(digit().plus()).optional())
///         .flatten().trim().map(num.parse));
///
/// If we want to support parenthesis we can add a wrapper. The callback
/// specifies how the value is extracted from the parse result:
///
///     build.group()
///       ..wrapper(char('(').trim(), char(')').trim(),
///           (left, value, right) => value);
///
/// Then come the normal arithmetic operators. Note, that the callback blocks
/// receive both, the values as well as the parsed operator in the order they
/// appear in the parse input.
///
///     // negation is a prefix operator
///     builder.group()
///       ..prefix(char('-').trim(), (op, a) => -a);
///
///     // power is right-associative
///     builder.group()
///       ..right(char('^').trim(), (a, op, b) => math.pow(a, b));
///
///     // multiplication and addition is left-associative
///     builder.group()
///       ..left(char('*').trim(), (a, op, b) => a * b)
///       ..left(char('/').trim(), (a, op, b) => a / b);
///     builder.group()
///       ..left(char('+').trim(), (a, op, b) => a + b)
///       ..left(char('-').trim(), (a, op, b) => a - b);
///
/// Finally we can build the parser:
///
///     final parser = builder.build();
///
/// After executing the above code we get an efficient parser that correctly
/// evaluates expressions like:
///
///     parser.parse('-8');      // -8
///     parser.parse('1+2*3');   // 7
///     parser.parse('1*2+3');   // 5
///     parser.parse('8/4/2');   // 2
///     parser.parse('2^2^3');   // 256
///
class ExpressionBuilder<T> {
  final List<ExpressionGroup<T>> _groups = [];
  final SettableParser<T> _loopback = undefined();

  /// Creates a new group of operators that share the same priority.
  ExpressionGroup<T> group() {
    final group = ExpressionGroup<T>(_loopback);
    _groups.add(group);
    return group;
  }

  /// Builds the expression parser.
  Parser<T> build() {
    final parser = _groups.fold<Parser<T>>(
      failure('Highest priority group should define a primitive parser.'),
      (a, b) => b.build(a),
    );
    _loopback.set(parser);
    return resolve(parser);
  }
}

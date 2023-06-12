import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../../parser/utils/labeled.dart';
import '../combinator/delegate.dart';

extension LabelParserExtension<R> on Parser<R> {
  /// Returns a parser that simply defers to its delegate, but that
  /// has a [label] for debugging purposes.
  LabeledParser<R> labeled(String label) => LabelParser<R>(this, label);
}

/// A parser that always defers to its delegate, but that also holds a label
/// for debugging purposes.
class LabelParser<R> extends DelegateParser<R, R> implements LabeledParser<R> {
  LabelParser(super.delegate, this.label);

  /// Label of this parser.
  @override
  final String label;

  @override
  Result<R> parseOn(Context context) => delegate.parseOn(context);

  @override
  int fastParseOn(String buffer, int position) =>
      delegate.fastParseOn(buffer, position);

  @override
  LabelParser<R> copy() => LabelParser<R>(delegate, label);

  @override
  bool hasEqualProperties(LabelParser<R> other) =>
      super.hasEqualProperties(other) && label == other.label;

  @override
  String toString() => '${super.toString()}[$label]';
}

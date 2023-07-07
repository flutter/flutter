import '../../core/parser.dart';
import 'repeating.dart';

/// An abstract parser that repeatedly parses between 'min' and 'max' instances
/// of its delegate and that requires the input to be completed with a specified
/// parser 'limit'. Subclasses provide repeating behavior as typically seen in
/// regular expression implementations (non-blind).
abstract class LimitedRepeatingParser<R> extends RepeatingParser<R, List<R>> {
  LimitedRepeatingParser(Parser<R> delegate, this.limit, int min, int max)
      : super(delegate, min, max);

  /// Parser restraining further consumption of the delegate parser.
  Parser<void> limit;

  @override
  List<Parser> get children => [delegate, limit];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (limit == source) {
      limit = target;
    }
  }
}

import '../../core/parser.dart';

/// Interface of a parser that has a debug label.
abstract class LabeledParser<R> implements Parser<R> {
  /// Debug label of the parser object.
  String get label;
}

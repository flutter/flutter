import '../core/parser.dart';
import '../parser/combinator/settable.dart';
import 'transform.dart';

/// Returns a copy of [parser] with all settable parsers removed.
@Deprecated('Use `resolve(Parser)` instead.')
Parser<T> removeSettables<T>(Parser<T> parser) {
  return transformParser(parser, <R>(each) {
    while (each is SettableParser) {
      each = each.children.first as Parser<R>;
    }
    return each;
  });
}

/// Returns a copy of [parser] with all duplicates parsers collapsed.
Parser<T> removeDuplicates<T>(Parser<T> parser) {
  final uniques = <Parser>{};
  return transformParser(parser, <R>(source) {
    return uniques.firstWhere((each) {
      return source != each && source.isEqualTo(each);
    }, orElse: () {
      uniques.add(source);
      return source;
    }) as Parser<R>;
  });
}

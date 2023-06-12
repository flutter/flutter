import 'dart:collection';

import 'package:meta/meta.dart';

import 'parser_match.dart';
import 'parser_pattern.dart';
import 'pattern_iterator.dart';

@immutable
class PatternIterable extends IterableBase<ParserMatch> {
  const PatternIterable(this.pattern, this.input, this.start);

  final ParserPattern pattern;
  final String input;
  final int start;

  @override
  Iterator<ParserMatch> get iterator =>
      PatternIterator(pattern, pattern.parser, input, start);
}

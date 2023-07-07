import 'dart:collection';

import 'package:meta/meta.dart';

import '../../core/parser.dart';
import 'matches_iterator.dart';

@immutable
class MatchesIterable<T> extends IterableBase<T> {
  const MatchesIterable(this.parser, this.input, this.start, this.overlapping);

  final Parser<T> parser;
  final String input;
  final int start;
  final bool overlapping;

  @override
  Iterator<T> get iterator =>
      MatchesIterator(parser, input, start, overlapping);
}

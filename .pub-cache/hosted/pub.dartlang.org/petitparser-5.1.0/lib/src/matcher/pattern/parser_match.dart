import 'package:meta/meta.dart';

import 'parser_pattern.dart';

@immutable
class ParserMatch implements Match {
  const ParserMatch(this.pattern, this.input, this.start, this.end);

  @override
  final ParserPattern pattern;

  @override
  final String input;

  @override
  final int start;

  @override
  final int end;

  @override
  String? group(int group) => this[group];

  @override
  String? operator [](int group) =>
      group == 0 ? input.substring(start, end) : null;

  @override
  List<String?> groups(List<int> groupIndices) =>
      groupIndices.map(group).toList(growable: false);

  @override
  int get groupCount => 0;
}

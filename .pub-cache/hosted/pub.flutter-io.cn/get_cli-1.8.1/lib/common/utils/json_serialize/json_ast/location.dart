import 'package:meta/meta.dart';

@immutable
class Loc {
  final int? line;
  final int? column;

  const Loc({this.line, this.column});
}

class Segment extends Loc {
  final int? offset;

  Segment(int? line, int? column, this.offset)
      : super(line: line, column: column);

  @override
  bool operator ==(dynamic other) =>
      other is Segment &&
      line == other.line &&
      column == other.column &&
      offset == other.offset;

  @override
  int get hashCode => line.hashCode ^ column.hashCode ^ offset.hashCode;
}

@immutable
class Location {
  final Segment start;
  final Segment end;
  final String? source;

  const Location(this.start, this.end, [this.source]);

  @override
  bool operator ==(dynamic other) =>
      other is Location &&
      start == other.start &&
      end == other.end &&
      source == other.source;

  static Location create(int? startLine, int? startColumn, int? startOffset,
      int? endLine, int? endColumn, int? endOffset,
      [String? source]) {
    final startSegment = Segment(startLine, startColumn, startOffset);
    final endSegment = Segment(endLine, endColumn, endOffset);
    return Location(startSegment, endSegment, source);
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ source.hashCode;
}

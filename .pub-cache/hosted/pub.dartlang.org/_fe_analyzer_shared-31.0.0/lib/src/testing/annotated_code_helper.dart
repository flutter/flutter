// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int _LF = 0x0A;
const int _CR = 0x0D;

const Pattern atBraceStart = '@{';
const Pattern braceEnd = '}';

final Pattern commentStart = new RegExp(r'/\*');
final Pattern commentEnd = new RegExp(r'\*/\s*');

class Annotation {
  /// The index of the (corresponding) annotation in the annotated code test, or
  /// `null` if the annotation doesn't correspond to an annotation in the
  /// annotated code.
  final int? index;

  /// 1-based line number of the annotation.
  final int lineNo;

  /// 1-based column number of the annotation.
  final int columnNo;

  /// 0-based character offset  of the annotation within the source text.
  final int offset;

  /// The annotation start text.
  final String prefix;

  /// The text in the annotation.
  final String text;

  /// The annotation end text.
  final String suffix;

  Annotation(this.index, this.lineNo, this.columnNo, this.offset, this.prefix,
      this.text, this.suffix)
      // ignore: unnecessary_null_comparison
      : assert(offset != null),
        assert(offset >= 0);

  String toString() =>
      'Annotation(index=$index,lineNo=$lineNo,columnNo=$columnNo,'
      'offset=$offset,prefix=$prefix,text=$text,suffix=$suffix)';
}

/// A source code text with annotated positions.
///
/// An [AnnotatedCode] can be created from a [String] of source code where
/// annotated positions are embedded, by default using the syntax `@{text}`.
/// For instance
///
///     main() {
///       @{foo-call}foo();
///       bar@{bar-args}();
///     }
///
///  the position of `foo` call will hold an annotation with text 'foo-call' and
///  the position of `bar` arguments will hold an annotation with text
///  'bar-args'.
///
///  Annotation text cannot span multiple lines and cannot contain '}'.
class AnnotatedCode {
  /// The original code with annotations.
  final String annotatedCode;

  /// The source code without annotations.
  final String sourceCode;

  /// The annotations for the source code.
  final List<Annotation> annotations;

  List<int>? _lineStarts;

  AnnotatedCode(this.annotatedCode, this.sourceCode, this.annotations);

  AnnotatedCode.internal(
      this.annotatedCode, this.sourceCode, this.annotations, this._lineStarts);

  /// Creates an [AnnotatedCode] by processing [annotatedCode]. Annotation
  /// delimited by [start] and [end] are converted into [Annotation]s and
  /// removed from the [annotatedCode] to produce the source code.
  factory AnnotatedCode.fromText(String annotatedCode,
      [Pattern start = atBraceStart, Pattern end = braceEnd]) {
    StringBuffer codeBuffer = new StringBuffer();
    List<Annotation> annotations = <Annotation>[];
    int index = 0;
    int offset = 0;
    int lineNo = 1;
    int columnNo = 1;
    List<int> lineStarts = <int>[];
    lineStarts.add(offset);
    while (index < annotatedCode.length) {
      Match? startMatch = start.matchAsPrefix(annotatedCode, index);
      if (startMatch != null) {
        int startIndex = startMatch.end;
        Iterable<Match> endMatches =
            end.allMatches(annotatedCode, startMatch.end);
        if (!endMatches.isEmpty) {
          Match endMatch = endMatches.first;
          annotatedCode.indexOf(end, startIndex);
          String prefix =
              annotatedCode.substring(startMatch.start, startMatch.end);
          String text = annotatedCode.substring(startMatch.end, endMatch.start);
          String suffix = annotatedCode.substring(endMatch.start, endMatch.end);
          annotations.add(new Annotation(annotations.length, lineNo, columnNo,
              offset, prefix, text, suffix));
          index = endMatch.end;
          continue;
        }
      }

      int charCode = annotatedCode.codeUnitAt(index);
      switch (charCode) {
        case _LF:
          codeBuffer.write('\n');
          offset++;
          lineStarts.add(offset);
          lineNo++;
          columnNo = 1;
          break;
        case _CR:
          if (index + 1 < annotatedCode.length &&
              annotatedCode.codeUnitAt(index + 1) == _LF) {
            index++;
          }
          codeBuffer.write('\n');
          offset++;
          lineStarts.add(offset);
          lineNo++;
          columnNo = 1;
          break;
        default:
          codeBuffer.writeCharCode(charCode);
          offset++;
          columnNo++;
      }
      index++;
    }
    lineStarts.add(offset);
    return new AnnotatedCode.internal(
        annotatedCode, codeBuffer.toString(), annotations, lineStarts);
  }

  void _ensureLineStarts() {
    if (_lineStarts == null) {
      List<int> lineStarts = <int>[];
      _lineStarts = lineStarts;
      int index = 0;
      int offset = 0;
      lineStarts.add(offset);
      while (index < sourceCode.length) {
        int charCode = sourceCode.codeUnitAt(index);
        switch (charCode) {
          case _LF:
            offset++;
            lineStarts.add(offset);
            break;
          case _CR:
            if (index + 1 < sourceCode.length &&
                sourceCode.codeUnitAt(index + 1) == _LF) {
              index++;
            }
            offset++;
            lineStarts.add(offset);
            break;
          default:
            offset++;
        }
        index++;
      }
      lineStarts.add(offset);
    }
  }

  void addAnnotation(
      int lineNo, int columnNo, String prefix, String text, String suffix) {
    _ensureLineStarts();
    int offset = _lineStarts![lineNo - 1] + (columnNo - 1);
    annotations.add(new Annotation(
        annotations.length, lineNo, columnNo, offset, prefix, text, suffix));
  }

  int get lineCount {
    _ensureLineStarts();
    return _lineStarts!.length;
  }

  int getLineIndex(int offset) {
    _ensureLineStarts();
    int index = 0;
    while (index + 1 < _lineStarts!.length) {
      if (_lineStarts![index + 1] <= offset) {
        index++;
      } else {
        break;
      }
    }
    return index;
  }

  int getLineStart(int lineIndex) {
    _ensureLineStarts();
    if (lineIndex < 0) {
      return 0;
    } else if (lineIndex < _lineStarts!.length) {
      return _lineStarts![lineIndex];
    } else {
      return sourceCode.length;
    }
  }

  String getLine(int lineIndex) {
    int startIndex = getLineStart(lineIndex);
    int endIndex = getLineStart(lineIndex + 1);
    return sourceCode.substring(startIndex, endIndex);
  }

  String toText() {
    StringBuffer sb = new StringBuffer();
    List<Annotation> list = annotations.toList()
      ..sort((a, b) {
        int result = a.offset.compareTo(b.offset);
        if (result == 0) {
          if (a.index != null && b.index != null) {
            result = a.index!.compareTo(b.index!);
          } else if (a.index != null) {
            result = -1;
          } else if (b.index != null) {
            result = 1;
          }
        }
        if (result == 0) {
          result = annotations.indexOf(a).compareTo(annotations.indexOf(b));
        }
        return result;
      });
    int offset = 0;
    for (Annotation annotation in list) {
      sb.write(sourceCode.substring(offset, annotation.offset));
      sb.write(annotation.prefix);
      sb.write(annotation.text);
      sb.write(annotation.suffix);
      offset = annotation.offset;
    }
    sb.write(sourceCode.substring(offset));
    return sb.toString();
  }

  @override
  String toString() {
    return 'AnnotatedCode(sourceCode=$sourceCode,annotations=$annotations)';
  }
}

/// Split the annotations in [annotatedCode] by [prefixes].
///
/// Returns a map containing an [AnnotatedCode] object for each prefix,
/// containing only the annotations whose text started with the given prefix.
/// If no prefix match the annotation text, the annotation is added to all
/// [AnnotatedCode] objects.
///
/// The prefixes are removed from the annotation texts in the returned
/// [AnnotatedCode] objects.
Map<String, AnnotatedCode> splitByPrefixes(
    AnnotatedCode annotatedCode, Iterable<String> prefixes) {
  Set<String> prefixSet = prefixes.toSet();
  Map<String, List<Annotation>> map = <String, List<Annotation>>{};
  for (String prefix in prefixSet) {
    map[prefix] = <Annotation>[];
  }
  outer:
  for (Annotation annotation in annotatedCode.annotations) {
    int dotPos = annotation.text.indexOf('.');
    if (dotPos != -1) {
      String annotationPrefix = annotation.text.substring(0, dotPos);
      String annotationText = annotation.text.substring(dotPos + 1);
      List<String> markers = annotationPrefix.split('|').toList();
      if (prefixSet.containsAll(markers)) {
        for (String part in markers) {
          Annotation subAnnotation = new Annotation(
              annotation.index,
              annotation.lineNo,
              annotation.columnNo,
              annotation.offset,
              annotation.prefix,
              annotationText,
              annotation.suffix);
          map[part]!.add(subAnnotation);
        }
        continue outer;
      }
    }
    for (String prefix in prefixSet) {
      map[prefix]!.add(annotation);
    }
  }
  Map<String, AnnotatedCode> split = <String, AnnotatedCode>{};
  map.forEach((String prefix, List<Annotation> annotations) {
    split[prefix] = new AnnotatedCode(
        annotatedCode.annotatedCode, annotatedCode.sourceCode, annotations);
  });
  return split;
}

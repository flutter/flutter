// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Information about the directives found in Dartdoc comments.
class DartdocDirectiveInfo {
  // TODO(brianwilkerson) Consider moving the method
  //  DartUnitHoverComputer.computeDocumentation to this class.

  /// A regular expression used to match a macro directive. There is one group
  /// that contains the name of the template.
  static final macroRegExp = RegExp(r'{@macro\s+([^}]+)}');

  /// A regular expression used to match a template directive. There are two
  /// groups. The first contains the name of the template, the second contains
  /// the body of the template.
  static final templateRegExp = RegExp(
      r'[ ]*{@template\s+(.+?)}([\s\S]+?){@endtemplate}[ ]*\n?',
      multiLine: true);

  /// A regular expression used to match a youtube or animation directive.
  ///
  /// These are in the form:
  /// `{@youtube 560 315 https://www.youtube.com/watch?v=2uaoEDOgk_I}`.
  static final videoRegExp =
      RegExp(r'{@(youtube|animation)\s+[^}]+\s+[^}]+\s+([^}]+)}');

  /// A table mapping the names of templates to the unprocessed bodies of the
  /// templates.
  final Map<String, String> templateMap = {};

  /// Initialize a newly created set of information about Dartdoc directives.
  DartdocDirectiveInfo();

  /// Add corresponding pairs from the [names] and [values] to the set of
  /// defined templates.
  void addTemplateNamesAndValues(List<String> names, List<String> values) {
    int length = names.length;
    assert(length == values.length);
    for (int i = 0; i < length; i++) {
      templateMap[names[i]] = values[i];
    }
  }

  /// Process the given Dartdoc [comment], extracting the template directive if
  /// there is one.
  void extractTemplate(String? comment) {
    if (comment == null) return;

    for (Match match in templateRegExp.allMatches(comment)) {
      String name = match.group(1)!.trim();
      String body = match.group(2)!.trim();
      templateMap[name] = _stripDelimiters(body).join('\n');
    }
  }

  /// Process the given Dartdoc [comment], replacing any known dartdoc
  /// directives with the associated content.
  ///
  /// Macro directives are replaced with the body of the corresponding template.
  ///
  /// Youtube and animation directives are replaced with markdown hyperlinks.
  Documentation processDartdoc(String comment, {bool includeSummary = false}) {
    List<String> lines = _stripDelimiters(comment);
    var firstBlankLine = lines.length;
    for (int i = lines.length - 1; i >= 0; i--) {
      String line = lines[i];
      if (line.isEmpty) {
        // Because we're iterating from the last line to the first, the last
        // blank line we find is the first.
        firstBlankLine = i;
      } else {
        var match = macroRegExp.firstMatch(line);
        if (match != null) {
          var name = match.group(1)!;
          var value = templateMap[name];
          if (value != null) {
            lines[i] = value;
          }
          continue;
        }

        match = videoRegExp.firstMatch(line);
        if (match != null) {
          var uri = match.group(2);
          if (uri != null && uri.isNotEmpty) {
            String label = uri;
            if (label.startsWith('https://')) {
              label = label.substring('https://'.length);
            }
            lines[i] = '[$label]($uri)';
          }
          continue;
        }
      }
    }
    if (includeSummary) {
      var full = lines.join('\n');
      var summary = firstBlankLine == lines.length
          ? full
          : lines.getRange(0, firstBlankLine).join('\n').trim();
      return DocumentationWithSummary(full: full, summary: summary);
    }
    return Documentation(full: lines.join('\n'));
  }

  bool _isWhitespace(String comment, int index, bool includeEol) {
    if (comment.startsWith(' ', index) ||
        comment.startsWith('\t', index) ||
        (includeEol && comment.startsWith('\n', index))) {
      return true;
    }
    return false;
  }

  int _skipWhitespaceBackward(String comment, int start, int end,
      [bool skipEol = false]) {
    while (start < end && _isWhitespace(comment, end, skipEol)) {
      end--;
    }
    return end;
  }

  int _skipWhitespaceForward(String comment, int start, int end,
      [bool skipEol = false]) {
    while (start < end && _isWhitespace(comment, start, skipEol)) {
      start++;
    }
    return start;
  }

  /// Remove the delimiters from the given [comment].
  List<String> _stripDelimiters(String comment) {
    var start = 0;
    var end = comment.length;
    if (comment.startsWith('/**')) {
      start = _skipWhitespaceForward(comment, 3, end, true);
      if (comment.endsWith('*/')) {
        end = _skipWhitespaceBackward(comment, start, end - 2, true);
      }
    }
    var line = -1;
    var firstNonEmpty = -1;
    var lastNonEmpty = -1;
    var lines = <String>[];
    while (start < end) {
      line++;
      var eolIndex = comment.indexOf('\n', start);
      if (eolIndex < 0) {
        eolIndex = end;
      }
      var lineStart = _skipWhitespaceForward(comment, start, eolIndex);
      if (comment.startsWith('///', lineStart)) {
        lineStart += 3;
        if (_isWhitespace(comment, lineStart, false)) {
          lineStart++;
        }
      } else if (comment.startsWith('*', lineStart)) {
        lineStart += 1;
        if (_isWhitespace(comment, lineStart, false)) {
          lineStart++;
        }
      }
      var lineEnd =
          _skipWhitespaceBackward(comment, lineStart, eolIndex - 1) + 1;
      if (lineStart < lineEnd) {
        // If the line is not empty, update the line range.
        if (firstNonEmpty < 0) {
          firstNonEmpty = line;
        }
        if (line > lastNonEmpty) {
          lastNonEmpty = line;
        }
        lines.add(comment.substring(lineStart, lineEnd));
      } else {
        lines.add('');
      }
      start = eolIndex + 1;
    }
    if (firstNonEmpty < 0 || lastNonEmpty < firstNonEmpty) {
      // All of the lines are empty.
      return const <String>[];
    }
    return lines.sublist(firstNonEmpty, lastNonEmpty + 1);
  }
}

/// A representation of the documentation for an element.
class Documentation {
  String full;

  Documentation({required this.full});
}

/// A representation of the documentation for an element that includes a
/// summary.
class DocumentationWithSummary extends Documentation {
  final String summary;

  DocumentationWithSummary({required super.full, required this.summary});
}

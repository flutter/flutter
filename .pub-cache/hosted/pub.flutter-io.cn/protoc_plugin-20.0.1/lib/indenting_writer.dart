// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'src/generated/descriptor.pb.dart';

/// Specifies code locations where metadata annotations should be attached and
/// where they should point to in the original proto.
class NamedLocation {
  final String name;
  final List<int> fieldPathSegment;
  final int start;
  NamedLocation(
      {required this.name,
      required this.fieldPathSegment,
      required this.start});
}

/// A buffer for writing indented source code.
class IndentingWriter {
  final StringBuffer _buffer = StringBuffer();
  final GeneratedCodeInfo sourceLocationInfo = GeneratedCodeInfo();
  String _indent = '';
  bool _needIndent = true;
  // After writing any chunk, _previousOffset is the size of everything that was
  // written to the buffer before the latest call to print or addBlock.
  int _previousOffset = 0;
  final String? _sourceFile;

  IndentingWriter({String? filename}) : _sourceFile = filename;

  /// Appends a string indented to the current level.
  /// (Indentation will be added after newline characters where needed.)
  void print(String text) {
    _previousOffset = _buffer.length;
    var lastNewline = text.lastIndexOf('\n');
    if (lastNewline == -1) {
      _writeChunk(text);
      return;
    }

    for (var line in text.substring(0, lastNewline).split('\n')) {
      _writeChunk(line);
      _newline();
    }
    _writeChunk(text.substring(lastNewline + 1));
  }

  /// Same as print, but with a newline at the end.
  void println([String text = '']) {
    print(text);
    _newline();
  }

  void printAnnotated(String text, List<NamedLocation> namedLocations) {
    final indentOffset = _needIndent ? _indent.length : 0;
    print(text);
    for (final location in namedLocations) {
      _addAnnotation(location.fieldPathSegment, location.name,
          location.start + indentOffset);
    }
  }

  void printlnAnnotated(String text, List<NamedLocation> namedLocations) {
    printAnnotated(text, namedLocations);
    _newline();
  }

  /// Prints a block of text with the body indented one more level.
  void addBlock(String start, String end, void Function() body,
      {bool endWithNewline = true}) {
    println(start);
    _addBlockBodyAndEnd(end, body, endWithNewline, _indent + '  ');
  }

  /// Prints a block of text with an unindented body.
  /// (For example, for triple quotes.)
  void addUnindentedBlock(String start, String end, void Function() body,
      {bool endWithNewline = true}) {
    println(start);
    _addBlockBodyAndEnd(end, body, endWithNewline, '');
  }

  void addAnnotatedBlock(String start, String end,
      List<NamedLocation> namedLocations, void Function() body,
      {bool endWithNewline = true}) {
    printlnAnnotated(start, namedLocations);
    _addBlockBodyAndEnd(end, body, endWithNewline, _indent + '  ');
  }

  void _addBlockBodyAndEnd(
      String end, void Function() body, bool endWithNewline, String newIndent) {
    var oldIndent = _indent;
    _indent = newIndent;
    body();
    _indent = oldIndent;
    if (endWithNewline) {
      println(end);
    } else {
      print(end);
    }
  }

  @override
  String toString() => _buffer.toString();

  /// Writes part of a line of text.
  /// Adds indentation if we're at the start of a line.
  void _writeChunk(String chunk) {
    assert(!chunk.contains('\n'));

    if (chunk.isEmpty) return;
    if (_needIndent) {
      _buffer.write(_indent);
      _needIndent = false;
    }
    _buffer.write(chunk);
  }

  void _newline() {
    _buffer.writeln();
    _needIndent = true;
  }

  /// Creates an annotation, given the starting offset and ending offset.
  /// [start] should be the location of the identifier as it appears in the
  /// string that was passed to the previous [print]. Name should be the string
  /// that was written to file.
  void _addAnnotation(List<int> fieldPath, String name, int start) {
    if (_sourceFile == null) {
      return;
    }
    var annotation = GeneratedCodeInfo_Annotation()
      ..path.addAll(fieldPath)
      ..sourceFile = _sourceFile!
      ..begin = _previousOffset + start
      ..end = _previousOffset + start + name.length;
    sourceLocationInfo.annotation.add(annotation);
  }
}

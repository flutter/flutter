// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains a code printer that generates code by recording the source maps.
library source_maps.printer;

import 'package:source_span/source_span.dart';

import 'builder.dart';
import 'src/source_map_span.dart';

const int _LF = 10;
const int _CR = 13;

/// A simple printer that keeps track of offset locations and records source
/// maps locations.
class Printer {
  final String filename;
  final StringBuffer _buff = StringBuffer();
  final SourceMapBuilder _maps = SourceMapBuilder();
  String get text => _buff.toString();
  String get map => _maps.toJson(filename);

  /// Current source location mapping.
  SourceLocation? _loc;

  /// Current line in the buffer;
  int _line = 0;

  /// Current column in the buffer.
  int _column = 0;

  Printer(this.filename);

  /// Add [str] contents to the output, tracking new lines to track correct
  /// positions for span locations. When [projectMarks] is true, this method
  /// adds a source map location on each new line, projecting that every new
  /// line in the target file (printed here) corresponds to a new line in the
  /// source file.
  void add(String str, {projectMarks = false}) {
    var chars = str.runes.toList();
    var length = chars.length;
    for (var i = 0; i < length; i++) {
      var c = chars[i];
      if (c == _LF || (c == _CR && (i + 1 == length || chars[i + 1] != _LF))) {
        // Return not followed by line-feed is treated as a new line.
        _line++;
        _column = 0;
        {
          // **Warning**: Any calls to `mark` will change the value of `_loc`,
          // so this local variable is no longer up to date after that point.
          //
          // This is why it has been put inside its own block to limit the
          // scope in which it is available.
          var loc = _loc;
          if (projectMarks && loc != null) {
            if (loc is FileLocation) {
              var file = loc.file;
              mark(file.location(file.getOffset(loc.line + 1)));
            } else {
              mark(SourceLocation(0,
                  sourceUrl: loc.sourceUrl, line: loc.line + 1, column: 0));
            }
          }
        }
      } else {
        _column++;
      }
    }
    _buff.write(str);
  }

  /// Append a [total] number of spaces in the target file. Typically used for
  /// formatting indentation.
  void addSpaces(int total) {
    for (var i = 0; i < total; i++) {
      _buff.write(' ');
    }
    _column += total;
  }

  /// Marks that the current point in the target file corresponds to the [mark]
  /// in the source file, which can be either a [SourceLocation] or a
  /// [SourceSpan]. When the mark is a [SourceMapSpan] with `isIdentifier` set,
  /// this also records the name of the identifier in the source map
  /// information.
  void mark(mark) {
    late final SourceLocation loc;
    String? identifier;
    if (mark is SourceLocation) {
      loc = mark;
    } else if (mark is SourceSpan) {
      loc = mark.start;
      if (mark is SourceMapSpan && mark.isIdentifier) identifier = mark.text;
    }
    _maps.addLocation(loc,
        SourceLocation(_buff.length, line: _line, column: _column), identifier);
    _loc = loc;
  }
}

/// A more advanced printer that keeps track of offset locations to record
/// source maps, but additionally allows nesting of different kind of items,
/// including [NestedPrinter]s, and it let's you automatically indent text.
///
/// This class is especially useful when doing code generation, where different
/// peices of the code are generated independently on separate printers, and are
/// finally put together in the end.
class NestedPrinter implements NestedItem {
  /// Items recoded by this printer, which can be [String] literals,
  /// [NestedItem]s, and source map information like [SourceLocation] and
  /// [SourceSpan].
  final _items = <dynamic>[];

  /// Internal buffer to merge consecutive strings added to this printer.
  StringBuffer? _buff;

  /// Current indentation, which can be updated from outside this class.
  int indent;

  /// [Printer] used during the last call to [build], if any.
  Printer? printer;

  /// Returns the text produced after calling [build].
  String? get text => printer?.text;

  /// Returns the source-map information produced after calling [build].
  String? get map => printer?.map;

  /// Item used to indicate that the following item is copied from the original
  /// source code, and hence we should preserve source-maps on every new line.
  static final _ORIGINAL = Object();

  NestedPrinter([this.indent = 0]);

  /// Adds [object] to this printer. [object] can be a [String],
  /// [NestedPrinter], or anything implementing [NestedItem]. If [object] is a
  /// [String], the value is appended directly, without doing any formatting
  /// changes. If you wish to add a line of code with automatic indentation, use
  /// [addLine] instead.  [NestedPrinter]s and [NestedItem]s are not processed
  /// until [build] gets called later on. We ensure that [build] emits every
  /// object in the order that they were added to this printer.
  ///
  /// The [location] and [span] parameters indicate the corresponding source map
  /// location of [object] in the original input. Only one, [location] or
  /// [span], should be provided at a time.
  ///
  /// Indicate [isOriginal] when [object] is copied directly from the user code.
  /// Setting [isOriginal] will make this printer propagate source map locations
  /// on every line-break.
  void add(object,
      {SourceLocation? location, SourceSpan? span, bool isOriginal = false}) {
    if (object is! String || location != null || span != null || isOriginal) {
      _flush();
      assert(location == null || span == null);
      if (location != null) _items.add(location);
      if (span != null) _items.add(span);
      if (isOriginal) _items.add(_ORIGINAL);
    }

    if (object is String) {
      _appendString(object);
    } else {
      _items.add(object);
    }
  }

  /// Append `2 * indent` spaces to this printer.
  void insertIndent() => _indent(indent);

  /// Add a [line], autoindenting to the current value of [indent]. Note,
  /// indentation is not inferred from the contents added to this printer. If a
  /// line starts or ends an indentation block, you need to also update [indent]
  /// accordingly. Also, indentation is not adapted for nested printers. If
  /// you add a [NestedPrinter] to this printer, its indentation is set
  /// separately and will not include any the indentation set here.
  ///
  /// The [location] and [span] parameters indicate the corresponding source map
  /// location of [line] in the original input. Only one, [location] or
  /// [span], should be provided at a time.
  void addLine(String? line, {SourceLocation? location, SourceSpan? span}) {
    if (location != null || span != null) {
      _flush();
      assert(location == null || span == null);
      if (location != null) _items.add(location);
      if (span != null) _items.add(span);
    }
    if (line == null) return;
    if (line != '') {
      // We don't indent empty lines.
      _indent(indent);
      _appendString(line);
    }
    _appendString('\n');
  }

  /// Appends a string merging it with any previous strings, if possible.
  void _appendString(String s) {
    var buf = _buff ??= StringBuffer();
    buf.write(s);
  }

  /// Adds all of the current [_buff] contents as a string item.
  void _flush() {
    if (_buff != null) {
      _items.add(_buff.toString());
      _buff = null;
    }
  }

  void _indent(int indent) {
    for (var i = 0; i < indent; i++) {
      _appendString('  ');
    }
  }

  /// Returns a string representation of all the contents appended to this
  /// printer, including source map location tokens.
  @override
  String toString() {
    _flush();
    return (StringBuffer()..writeAll(_items)).toString();
  }

  /// Builds the output of this printer and source map information. After
  /// calling this function, you can use [text] and [map] to retrieve the
  /// geenrated code and source map information, respectively.
  void build(String filename) {
    writeTo(printer = Printer(filename));
  }

  /// Implements the [NestedItem] interface.
  @override
  void writeTo(Printer printer) {
    _flush();
    var propagate = false;
    for (var item in _items) {
      if (item is NestedItem) {
        item.writeTo(printer);
      } else if (item is String) {
        printer.add(item, projectMarks: propagate);
        propagate = false;
      } else if (item is SourceLocation || item is SourceSpan) {
        printer.mark(item);
      } else if (item == _ORIGINAL) {
        // we insert booleans when we are about to quote text that was copied
        // from the original source. In such case, we will propagate marks on
        // every new-line.
        propagate = true;
      } else {
        throw UnsupportedError('Unknown item type: $item');
      }
    }
  }
}

/// An item added to a [NestedPrinter].
abstract class NestedItem {
  /// Write the contents of this item into [printer].
  void writeTo(Printer printer);
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library validation_input_parser;

import 'dart:typed_data';

class ValidationParseResult {
  final Iterable<_Entry> _entries;
  final int numHandles;
  final ByteData data;

  ValidationParseResult(this._entries, this.data, this.numHandles);

  String toString() => _entries.map((e) => '$e').join('\n');
}

ValidationParseResult parse(String input) =>
    new _ValidationTestParser(input).parse();

class ValidationParseError {
  final String _message;
  ValidationParseError(this._message);
  String toString() => _message;
}

abstract class _Entry {
  final int size;
  void write(ByteData buffer, int offset, Map pointers);
}

class _UnsignedEntry implements _Entry {
  final int size;
  final int value;

  _UnsignedEntry(this.size, this.value) {
    if ((value >= (1 << (size * 8))) || (value < 0)) {
      throw new ValidationParseError('$value does not fit in a u$size');
    }
  }

  void write(ByteData buffer, int offset, Map pointers) {
    switch (size) {
      case 1: buffer.setUint8(offset, value); break;
      case 2: buffer.setUint16(offset, value, Endianness.LITTLE_ENDIAN); break;
      case 4: buffer.setUint32(offset, value, Endianness.LITTLE_ENDIAN); break;
      case 8: buffer.setUint64(offset, value, Endianness.LITTLE_ENDIAN); break;
      default: throw new ValidationParseError('Unexpected size: $size');
    }
  }

  String toString() => "[u$size]$value";
  bool operator==(_UnsignedEntry other) =>
      (size == other.size) && (value == other.value);
}

class _SignedEntry implements _Entry {
  final int size;
  final int value;

  _SignedEntry(this.size, this.value) {
    if ((value >= (1 << ((size * 8) - 1))) ||
        (value < -(1 << ((size * 8) - 1)))) {
      throw new ValidationParseError('$value does not fit in a s$size');
    }
  }

  void write(ByteData buffer, int offset, Map pointers) {
    switch (size) {
      case 1: buffer.setInt8(offset, value); break;
      case 2: buffer.setInt16(offset, value, Endianness.LITTLE_ENDIAN); break;
      case 4: buffer.setInt32(offset, value, Endianness.LITTLE_ENDIAN); break;
      case 8: buffer.setInt64(offset, value, Endianness.LITTLE_ENDIAN); break;
      default: throw new ValidationParseError('Unexpected size: $size');
    }
  }

  String toString() => "[s$size]$value";
  bool operator==(_SignedEntry other) =>
      (size == other.size) && (value == other.value);
}

class _FloatEntry implements _Entry {
  final int size;
  final double value;

  _FloatEntry(this.size, this.value);

  void write(ByteData buffer, int offset, Map pointers) {
    switch (size) {
      case 4: buffer.setFloat32(offset, value, Endianness.LITTLE_ENDIAN); break;
      case 8: buffer.setFloat64(offset, value, Endianness.LITTLE_ENDIAN); break;
      default: throw new ValidationParseError('Unexpected size: $size');
    }
  }

  String toString() => "[f$size]$value";
  bool operator==(_FloatEntry other) =>
      (size == other.size) && (value == other.value);
}

class _DistEntry implements _Entry {
  final int size;
  final String id;
  int offset;
  bool matched = false;

  _DistEntry(this.size, this.id);

  void write(ByteData buffer, int off, Map pointers) {
    offset = off;
    if (pointers[id] != null) {
      throw new ValidationParseError(
          'Pointer of same name already exists: $id');
    }
    pointers[id] = this;
  }

  String toString() => "[dist$size]$id matched = $matched";
  bool operator==(_DistEntry other) =>
      (size == other.size) && (id == other.id);
}

class _AnchrEntry implements _Entry {
  final int size = 0;
  final String id;

  _AnchrEntry(this.id);

  void write(ByteData buffer, int off, Map pointers) {
    _DistEntry dist = pointers[id];
    if (dist == null) {
      throw new ValidationParseError('Did not find "$id" in pointers map.');
    }
    int value = off - dist.offset;
    if (value < 0) {
      throw new ValidationParseError('Found a backwards pointer: $id');
    }
    int offset = dist.offset;
    switch (dist.size) {
      case 4: buffer.setUint32(offset, value, Endianness.LITTLE_ENDIAN); break;
      case 8: buffer.setUint64(offset, value, Endianness.LITTLE_ENDIAN); break;
      default: throw new ValidationParseError('Unexpected size: $size');
    }
    dist.matched = true;
  }

  String toString() => "[anchr]$id";
  bool operator==(_AnchrEntry other) => (id == other.id);
}

class _HandlesEntry implements _Entry {
  final int size = 0;
  final int value;

  _HandlesEntry(this.value);

  void write(ByteData buffer, int offset, Map pointers) {}

  String toString() => "[handles]$value";
  bool operator==(_HandlesEntry other) => (value == other.value);
}

class _CommentEntry implements _Entry {
  final int size = 0;
  final String value;

  _CommentEntry(this.value);

  void write(ByteData buffer, int offset, Map pointers) {}

  String toString() => "// $value";
  bool operator==(_CommentEntry other) => (value == other.value);
}

class _ValidationTestParser {
  static final RegExp newline = new RegExp(r'[\r\n]+');
  static final RegExp whitespace = new RegExp(r'[ \t\n\r]+');
  static final RegExp nakedUintRegExp =
    new RegExp(r'^0$|^[1-9][0-9]*$|^0[xX][0-9a-fA-F]+$');
  static final RegExp unsignedRegExp =
    new RegExp(r'^\[u([1248])\](0$|[1-9][0-9]*$|0[xX][0-9a-fA-F]+$)');
  static final RegExp signedRegExp = new RegExp(
      r'^\[s([1248])\]([-+]?0$|[-+]?[1-9][0-9]*$|[-+]?0[xX][0-9a-fA-F]+$)');
  static final RegExp binaryRegExp =
    new RegExp(r'^\[(b)\]([01]{8}$)');
  static final RegExp floatRegExp =
    new RegExp(r'^\[([fd])\]([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$)');
  static final RegExp distRegExp =
    new RegExp(r'^\[dist([48])\]([0-9a-zA-Z_]+$)');
  static final RegExp anchrRegExp =
    new RegExp(r'^\[(anchr)\]([0-9a-zA-Z_]+$)');
  static final RegExp handlesRegExp =
    new RegExp(r'^\[(handles)\](0$|([1-9][0-9]*$)|(0[xX][0-9a-fA-F]+$))');
  static final RegExp commentRegExp =
    new RegExp(r'//(.*)');

  String _input;
  Map<String, _DistEntry> _pointers;

  _ValidationTestParser(this._input) : _pointers = {};

  String _stripComment(String line) => line.replaceFirst(commentRegExp, "");

  ValidationParseResult parse() {
    var entries = _input.split(newline)
                        .map(_stripComment)
                        .expand((s) => s.split(whitespace))
                        .where((s) => s != "")
                        .map(_parseLine);
    int size = _calculateSize(entries);
    var data = (size > 0) ? new ByteData(size) : null;
    int numHandles = 0;
    int offset = 0;
    bool first = true;

    for (var entry in entries) {
      entry.write(data, offset, _pointers);
      offset += entry.size;

      if (entry is _HandlesEntry) {
        if (!first) {
          throw new ValidationParseError('Handles entry was not first');
        }
        numHandles = entry.value;
      }
      first = false;
    }

    for (var entry in entries) {
      if (entry is _DistEntry) {
        if (!_pointers[entry.id].matched) {
          throw new ValidationParseError('Unmatched dist: $entry');
        }
      }
    }

    return new ValidationParseResult(entries, data, numHandles);
  }

  _Entry _parseLine(String line) {
    if (unsignedRegExp.hasMatch(line)) {
      var match = unsignedRegExp.firstMatch(line);
      return new _UnsignedEntry(
          int.parse(match.group(1)), int.parse(match.group(2)));
    } else if (signedRegExp.hasMatch(line)) {
      var match = signedRegExp.firstMatch(line);
      return new _SignedEntry(
          int.parse(match.group(1)), int.parse(match.group(2)));
    } else if (binaryRegExp.hasMatch(line)) {
      var match = binaryRegExp.firstMatch(line);
      return new _UnsignedEntry(1, int.parse(match.group(2), radix: 2));
    } else if (floatRegExp.hasMatch(line)) {
      var match = floatRegExp.firstMatch(line);
      int size = match.group(1) == 'f' ? 4 : 8;
      return new _FloatEntry(size, double.parse(match.group(2)));
    } else if (distRegExp.hasMatch(line)) {
      var match = distRegExp.firstMatch(line);
      return new _DistEntry(int.parse(match.group(1)), match.group(2));
    } else if (anchrRegExp.hasMatch(line)) {
      var match = anchrRegExp.firstMatch(line);
      return new _AnchrEntry(match.group(2));
    } else if (handlesRegExp.hasMatch(line)) {
      var match = handlesRegExp.firstMatch(line);
      return new _HandlesEntry(int.parse(match.group(2)));
    } else if (nakedUintRegExp.hasMatch(line)) {
      var match = nakedUintRegExp.firstMatch(line);
      return new _UnsignedEntry(1, int.parse(match.group(0)));
    } else if (commentRegExp.hasMatch(line)) {
      var match = commentRegExp.firstMatch(line);
      return new _CommentEntry(match.group(1));
    } else if (line == "") {
      return new _CommentEntry("");
    } else {
      throw new ValidationParseError('Unkown entry: "$line" in \n$_input');
    }
  }

  int _calculateSize(Iterable<_Entry> entries) =>
      entries.fold(0, (value, entry) => value + entry.size);
}

bool _listEquals(Iterable i1, Iterable i2) {
  var l1 = i1.toList();
  var l2 = i2.toList();
  if (l1.length != l2.length) return false;
  for (int i = 0; i < l1.length; i++) {
    if (l1[i] != l2[i]) return false;
  }
  return true;
}

parserTests() {
  {
    var input = "    \t  // hello world \n\r \t// the answer is 42   ";
    var result = parse(input);
    assert(result.data == null);
    assert(result.numHandles == 0);
  }
  {
    var input = "[u1]0x10// hello world !! \n\r  \t [u2]65535 \n"
                "[u4]65536 [u8]0xFFFFFFFFFFFFFFFF 0 0Xff";
    var result = parse(input);

    // Check the parse results.
    var expected = [new _UnsignedEntry(1, 0x10),
                    new _UnsignedEntry(2, 65535),
                    new _UnsignedEntry(4, 65536),
                    new _UnsignedEntry(8, 0xFFFFFFFFFFFFFFFF),
                    new _UnsignedEntry(1, 0),
                    new _UnsignedEntry(1, 0xff)];
    assert(_listEquals(result._entries, expected));

    //Check the bits.
    var buffer = new ByteData(17);
    var offset = 0;
    buffer.setUint8(offset, 0x10); offset++;
    buffer.setUint16(offset, 65535, Endianness.LITTLE_ENDIAN); offset += 2;
    buffer.setUint32(offset, 65536, Endianness.LITTLE_ENDIAN); offset += 4;
    buffer.setUint64(offset, 0xFFFFFFFFFFFFFFFF, Endianness.LITTLE_ENDIAN); offset += 8;
    buffer.setUint8(offset, 0); offset++;
    buffer.setUint8(offset, 0xff); offset++;
    assert(_listEquals(buffer.buffer.asUint8List(),
                       result.data.buffer.asUint8List()));
  }
  {
    var input = "[s8]-0x800 [s1]-128\t[s2]+0 [s4]-40";
    var result = parse(input);

    // Check the parse results.
    var expected = [new _SignedEntry(8, -0x800),
                    new _SignedEntry(1, -128),
                    new _SignedEntry(2, 0),
                    new _SignedEntry(4, -40)];
    assert(_listEquals(result._entries, expected));

    // Check the bits.
    var buffer = new ByteData(15);
    var offset = 0;
    buffer.setInt64(offset, -0x800, Endianness.LITTLE_ENDIAN); offset += 8;
    buffer.setInt8(offset, -128); offset += 1;
    buffer.setInt16(offset, 0, Endianness.LITTLE_ENDIAN); offset += 2;
    buffer.setInt32(offset, -40, Endianness.LITTLE_ENDIAN); offset += 4;
    assert(_listEquals(buffer.buffer.asUint8List(),
                       result.data.buffer.asUint8List()));
  }
  {
    var input = "[b]00001011 [b]10000000  // hello world\r [b]00000000";
    var result = parse(input);

    // Check the parse results;
    var expected = [new _UnsignedEntry(1, 11),
                    new _UnsignedEntry(1, 128),
                    new _UnsignedEntry(1, 0)];
    assert(_listEquals(result._entries, expected));

    // Check the bits.
    var buffer = new ByteData(3);
    var offset = 0;
    buffer.setUint8(offset, 11); offset += 1;
    buffer.setUint8(offset, 128); offset += 1;
    buffer.setUint8(offset, 0); offset += 1;
    assert(_listEquals(buffer.buffer.asUint8List(),
                       result.data.buffer.asUint8List()));
  }
  {
    var input = "[f]+.3e9 [d]-10.03";
    var result = parse(input);

    // Check the parse results.
    var expected = [new _FloatEntry(4, 0.3e9),
                    new _FloatEntry(8,-10.03)];
    assert(_listEquals(result._entries, expected));

    // Check the bits.
    var buffer = new ByteData(12);
    var offset = 0;
    buffer.setFloat32(offset, 0.3e9, Endianness.LITTLE_ENDIAN); offset += 4;
    buffer.setFloat64(offset, -10.03, Endianness.LITTLE_ENDIAN); offset += 8;
    assert(_listEquals(buffer.buffer.asUint8List(),
                       result.data.buffer.asUint8List()));
  }
  {
    var input = "[dist4]foo 0 [dist8]bar 0 [anchr]foo [anchr]bar";
    var result = parse(input);

    // Check the parse results.
    var expected = [new _DistEntry(4, "foo"),
                    new _UnsignedEntry(1, 0),
                    new _DistEntry(8, "bar"),
                    new _UnsignedEntry(1, 0),
                    new _AnchrEntry("foo"),
                    new _AnchrEntry("bar")];
    assert(_listEquals(result._entries, expected));

    // Check the bits.
    var buffer = new ByteData(14);
    var offset = 0;
    buffer.setUint32(offset, 14, Endianness.LITTLE_ENDIAN); offset += 4;
    buffer.setUint8(offset, 0); offset += 1;
    buffer.setUint64(offset, 9, Endianness.LITTLE_ENDIAN); offset += 8;
    buffer.setUint8(offset, 0); offset += 1;
    assert(_listEquals(buffer.buffer.asUint8List(),
                       result.data.buffer.asUint8List()));
  }
  {
    var input = "// This message has handles! \n[handles]50 [u8]2";
    var result = parse(input);
    var expected = [new _HandlesEntry(50),
                    new _UnsignedEntry(8, 2)];
    assert(_listEquals(result._entries, expected));
  }
  {
    var errorInputs = ["/ hello world",
                       "[u1]x",
                       "[u2]-1000",
                       "[u1]0x100",
                       "[s2]-0x8001",
                       "[b]1",
                       "[b]1111111k",
                       "[dist4]unmatched",
                       "[anchr]hello [dist8]hello",
                       "[dist4]a [dist4]a [anchr]a",
                       "[dist4]a [anchr]a [dist4]a [anchr]a",
                       "0 [handles]50"];
    for (var input in errorInputs) {
      try {
        var result = parse(input);
        assert(false);
      } on ValidationParseError catch(e) {
        // Pass.
      }
    }
  }
}


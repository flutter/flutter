// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner.string_canonicalizer;

import 'dart:convert';

final _StringCanonicalizer _canonicalizer = new _StringCanonicalizer();

/// Returns [string] or a canonicalized version of it if our heuristics indicate
/// it may be a good idea to canonicalize it.
String considerCanonicalizeString(String string) {
  // It is very unlikely that large strings will appear repeatedly (mostly those
  // are long comments or literal strings).
  // To avoid putting those into the cache and requiring pruning again, we
  // simply return them.
  if (string.length > 250) return string;
  return _canonicalizer.canonicalizeString(string);
}

/// Returns a sub-string of [string] or a canonicalized version of it if our
/// heuristics indicate it may be a good idea to canonicalize it.
///
/// The sub-string is starting at [start] (inclusive) and ends at [end]
/// (exclusive).
String considerCanonicalizeSubString(String string, int start, int end) {
  // It is very unlikely that large strings will appear repeatedly (mostly those
  // are long comments or literal strings).
  // To avoid putting those into the cache and requiring pruning again, we
  // simply return them.
  if ((end - start) > 250) return string.substring(start, end);
  return _canonicalizer.canonicalizeSubString(string, start, end);
}

/// Returns a canonicalized version of [string].
String canonicalizeString(String string) {
  return _canonicalizer.canonicalizeString(string);
}

/// Returns a canonicalized version of a sub-string of [string].
///
/// The sub-string is starting at [start] (inclusive) and ends at [end]
/// (exclusive).
String canonicalizeSubString(String string, int start, int end) {
  return _canonicalizer.canonicalizeSubString(string, start, end);
}

/// Returns a canonicalized version of the UTF-8 decoded string from [bytes].
///
/// The string is UTF-8 decoded from [bytes], starting at [start] (inclusive)
/// and ending at [end] (exclusive).
///
/// It may avoid the overhead of UTF-8 decoding if the string is already in the
/// cache.
String canonicalizeUtf8SubString(
    List<int> bytes, int start, int end, bool isAscii) {
  return _canonicalizer.canonicalizeBytes(bytes, start, end, isAscii);
}

/// Will clear the string canonicalization cache.
void clearStringCanonicalizationCache() {
  _canonicalizer.clear();
}

/// Will prune the string canonicalization if it's current memory consumption
/// is estimated to be larger than [allowGrowthTo].
///
/// An attempt is made to keep most frequently used strings in the cache while
/// maintaining the memory limit.
void pruneStringCanonicalizationCache([int allowGrowthTo = 5 * 1024 * 1024]) {
  _canonicalizer.pruneTo(allowGrowthTo);
}

/// Decode UTF-8 without canonicalizing it.
String decodeString(List<int> bytes, int start, int end, bool isAscii) {
  return isAscii
      ? new String.fromCharCodes(bytes, start, end)
      : const Utf8Decoder(allowMalformed: true).convert(bytes, start, end);
}

abstract class _Node {
  final String payload;
  _Node? next;

  _Node(this.payload, this.next);

  int get hash;
}

class _StringNode extends _Node {
  int usageCount = 1;

  _StringNode(super.payload, super.next);

  @override
  int get hash =>
      _StringCanonicalizer.hashString(payload, /* start = */ 0, payload.length);

  // On a 64-bit Dart VM the size of
  //  * [_StringNode] itself is 32 bytes
  //  * [String] is 16 bytes plus the actual string data.
  //
  // It's an estimation that may overestimate (e.g. on 32-bit architectures) or
  // underestimate (if payload is unicode) - but is reasonably precise for our
  // purpose.
  int get estimatedMemoryConsumption => 32 + (16 + payload.length);
}

class _Utf8Node extends _Node {
  final List<int> data;
  final int start;
  final int end;

  _Utf8Node(this.data, this.start, this.end, String payload, _Node? next)
      : super(payload, next);

  @override
  int get hash => _StringCanonicalizer.hashBytes(data, start, end);
}

/// A hash table for triples:
/// (list of bytes, start, end) --> canonicalized string
/// Using triples avoids allocating string slices before checking if they
/// are canonical.
///
/// Gives about 3% speedup on dart2js.
class _StringCanonicalizer {
  /// Mask away top bits to keep hash calculation within 32-bit SMI range.
  static const int MASK = 16 * 1024 * 1024 - 1;

  static const int INITIAL_SIZE = 8 * 1024;

  /// Linear size of a hash table.
  int _size = INITIAL_SIZE;

  /// Items in a hash table.
  int _count = 0;

  /// Number of [_StringNode]s in the cache.
  int _stringCount = 0;

  /// Number of []s in the cache.
  int _utf8StringCount = 0;

  /// Memory consumption of [_StringNode]s.
  int _estimatedStringMemoryConsumption = 0;

  /// The table itself.
  List<_Node?> _nodes =
      new List<_Node?>.filled(INITIAL_SIZE, /* fill = */ null);

  static int hashBytes(List<int> data, int start, int end) {
    int h = 5381;
    for (int i = start; i < end; i++) {
      h = ((h << 5) + h + data[i]) & MASK;
    }
    return h;
  }

  static int hashString(String data, int start, int end) {
    int h = 5381;
    for (int i = start; i < end; i++) {
      h = ((h << 5) + h + data.codeUnitAt(i)) & MASK;
    }
    return h;
  }

  void rehash() {
    int newSize = _size * 2;
    List<_Node?> newNodes = new List<_Node?>.filled(newSize, /* fill = */ null);
    for (int i = 0; i < _size; i++) {
      _Node? t = _nodes[i];
      while (t != null) {
        _Node? n = t.next;
        int newIndex = t.hash & (newSize - 1);
        _Node? s = newNodes[newIndex];
        t.next = s;
        newNodes[newIndex] = t;
        t = n;
      }
    }
    _size = newSize;
    _nodes = newNodes;
  }

  String canonicalizeBytes(List<int> data, int start, int end, bool asciiOnly) {
    if (_count > _size) rehash();
    final int index = hashBytes(data, start, end) & (_size - 1);
    _Node? s = _nodes[index];
    _Node? t = s;
    int len = end - start;
    while (t != null) {
      if (t is _Utf8Node) {
        final List<int> tData = t.data;
        if (t.end - t.start == len) {
          int i = start, j = t.start;
          while (i < end && data[i] == tData[j]) {
            i++;
            j++;
          }
          if (i == end) {
            return t.payload;
          }
        }
      }
      t = t.next;
    }
    return insertUtf8Node(
        index, s, data, start, end, decodeString(data, start, end, asciiOnly));
  }

  String canonicalizeSubString(String data, int start, int end) {
    final int len = end - start;
    if (start == 0 && data.length == len) {
      return canonicalizeString(data);
    }
    if (_count > _size) rehash();
    final int index = hashString(data, start, end) & (_size - 1);
    final _Node? s = _nodes[index];
    _Node? t = s;
    while (t != null) {
      if (t is _StringNode) {
        final String tData = t.payload;
        if (tData.length == len && data.startsWith(tData, start)) {
          t.usageCount++;
          return tData;
        }
      }
      t = t.next;
    }
    return insertStringNode(index, s, data.substring(start, end));
  }

  String canonicalizeString(String data) {
    if (_count > _size) rehash();
    final int index =
        hashString(data, /* start = */ 0, data.length) & (_size - 1);
    final _Node? s = _nodes[index];
    _Node? t = s;
    while (t != null) {
      if (t is _StringNode) {
        final String tData = t.payload;
        if (identical(data, tData) || data == tData) {
          t.usageCount++;
          return tData;
        }
      }
      t = t.next;
    }
    return insertStringNode(index, s, data);
  }

  String insertStringNode(int index, _Node? next, String value) {
    final _StringNode newNode = new _StringNode(value, next);
    _nodes[index] = newNode;
    _count++;
    _stringCount++;
    _estimatedStringMemoryConsumption += newNode.estimatedMemoryConsumption;
    return value;
  }

  String insertUtf8Node(int index, _Node? next, List<int> buffer, int start,
      int end, String value) {
    final _Utf8Node newNode = new _Utf8Node(buffer, start, end, value, next);
    _nodes[index] = newNode;
    _count++;
    _utf8StringCount++;
    return value;
  }

  void clear() {
    initializeWithSize(INITIAL_SIZE);
  }

  void initializeWithSize(int size) {
    _size = size;
    _nodes = new List<_Node?>.filled(_size, /* fill = */ null);
    _count = 0;
    _utf8StringCount = 0;
    _stringCount = 0;
    _estimatedStringMemoryConsumption = 0;
  }

  void pruneTo(int allowGrowthTo) {
    // If we're already within the limit and there's no [_Utf8Node]s around
    // (which may hold on to very large Uint8List buffers) we have nothing to
    // do.
    if (_estimatedStringMemoryConsumption < allowGrowthTo &&
        _utf8StringCount == 0) {
      return;
    }

    // If there's only [_Utf8Node]s around we'll clear the entire cache.
    if (_stringCount == 0) {
      clear();
      return;
    }

    // Find all [_StringNode]s, sort them by usage and insert remaining nodes
    // into a new cache until we've reached half of the [allowGrowthTo] -
    // leaving some space before we'll have to prune again next time.

    final List<_StringNode> stringNodes = new List<_StringNode>.filled(
        _stringCount, new _StringNode('dummy', /* next = */ null));
    int writeIndex = 0;
    for (int i = 0; i < _nodes.length; ++i) {
      _Node? node = _nodes[i];
      while (node != null) {
        final _Node? nextNode = node.next;
        if (node is _StringNode) {
          stringNodes[writeIndex++] = node;
          node.next = null;
        }
        node = nextNode;
      }
    }
    stringNodes.sort((_StringNode a, _StringNode b) {
      return b.usageCount - a.usageCount;
    });

    int sum = 0;
    int lastIndex = 0;
    for (int i = 0; i < stringNodes.length; ++i) {
      final _StringNode node = stringNodes[i];
      sum += node.estimatedMemoryConsumption;
      if (sum >= (allowGrowthTo ~/ 2) || node.usageCount < 2) {
        lastIndex = i;
        break;
      }
    }

    final int newSize = (1 << lastIndex.bitLength);
    initializeWithSize(newSize);
    for (int i = lastIndex; i >= 0; --i) {
      final _StringNode newNode = stringNodes[i];
      final int index = newNode.hash & (_size - 1);
      newNode.next = _nodes[index];
      _nodes[index] = newNode;
      _count++;
      _stringCount++;
      _estimatedStringMemoryConsumption += newNode.estimatedMemoryConsumption;
    }
  }
}

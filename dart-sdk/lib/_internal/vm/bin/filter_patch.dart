// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

base class _FilterImpl extends NativeFieldWrapperClass1
    implements RawZLibFilter {
  @pragma("vm:external-name", "Filter_Process")
  external void process(List<int> data, int start, int end);

  @pragma("vm:external-name", "Filter_Processed")
  external List<int>? processed({bool flush = true, bool end = false});
}

base class _ZLibInflateFilter extends _FilterImpl {
  _ZLibInflateFilter(int windowBits, List<int>? dictionary, bool raw) {
    _init(windowBits, dictionary, raw);
  }
  @pragma("vm:external-name", "Filter_CreateZLibInflate")
  external void _init(int windowBits, List<int>? dictionary, bool raw);
}

base class _ZLibDeflateFilter extends _FilterImpl {
  _ZLibDeflateFilter(bool gzip, int level, int windowBits, int memLevel,
      int strategy, List<int>? dictionary, bool raw) {
    _init(gzip, level, windowBits, memLevel, strategy, dictionary, raw);
  }
  @pragma("vm:external-name", "Filter_CreateZLibDeflate")
  external void _init(bool gzip, int level, int windowBits, int memLevel,
      int strategy, List<int>? dictionary, bool raw);
}

@patch
class RawZLibFilter {
  @patch
  static RawZLibFilter _makeZLibDeflateFilter(
          bool gzip,
          int level,
          int windowBits,
          int memLevel,
          int strategy,
          List<int>? dictionary,
          bool raw) =>
      new _ZLibDeflateFilter(
          gzip, level, windowBits, memLevel, strategy, dictionary, raw);
  @patch
  static RawZLibFilter _makeZLibInflateFilter(
          int windowBits, List<int>? dictionary, bool raw) =>
      new _ZLibInflateFilter(windowBits, dictionary, raw);
}

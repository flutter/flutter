// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../canvaskit/canvaskit_api.dart';
import '../text_fragmenter.dart';

class AllCodeUnitFlags {
  AllCodeUnitFlags(this._text) : _allFlags = Uint8List(_text.length + 1) {
    _extract();
  }

  final String _text;
  final Uint8List _allFlags;

  int get length => _allFlags.length;

  bool hasFlag(int index, CodeUnitFlag flag) {
    assert(index >= 0);
    assert(index < _allFlags.length);

    return (_allFlags[index] & flag._bitmask) != 0;
  }

  void _extract() {
    // TODO(jlavrova): 1. This call to CanvasKit is not going to work with Skwasm.
    //                 2. We are only using `whitespace` flags from CanvasKit. Can we hardcode them
    //                    here to avoid calling CanvasKit?
    //                 3. Do we need other flags like `control` and `space`?
    final List<CodeUnitInfo> ckFlags = canvasKit.CodeUnits.compute(_text);
    assert(ckFlags.length == _allFlags.length);

    for (int i = 0; i < _allFlags.length; i++) {
      _allFlags[i] = ckFlags[i].flags;
    }

    // TODO(mdebbar): OPTIMIZATION: can we make `segmentText` update `codeUnitFlags` in-place?
    // Get text segmentation resuls using browser APIs.
    final SegmentationResult result = segmentText(_text);

    // Fill out grapheme flags
    for (final index in result.graphemes) {
      _allFlags[index] |= CodeUnitFlag.grapheme._bitmask;
    }
    // Fill out word flags
    for (final index in result.words) {
      _allFlags[index] |= CodeUnitFlag.wordBreak._bitmask;
    }
    // Fill out line break flags
    for (int i = 0; i < result.breaks.length; i += 2) {
      final int index = result.breaks[i];
      final int type = result.breaks[i + 1];

      if (type == kSoftLineBreak) {
        _allFlags[index] |= CodeUnitFlag.softLineBreak._bitmask;
      } else {
        _allFlags[index] |= CodeUnitFlag.hardLineBreak._bitmask;
      }
    }
  }
}

enum CodeUnitFlag {
  whitespace(0x01), // 1 << 0
  grapheme(0x02), // 1 << 1
  softLineBreak(0x04), // 1 << 2
  hardLineBreak(0x08), // 1 << 3
  wordBreak(0x10); // 1 << 4

  const CodeUnitFlag(this._bitmask);

  final int _bitmask;
}

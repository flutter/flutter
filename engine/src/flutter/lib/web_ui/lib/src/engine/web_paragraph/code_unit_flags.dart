// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../canvaskit/canvaskit_api.dart';
import '../text_fragmenter.dart';
import 'paragraph.dart';

class CodeUnitFlags {
  CodeUnitFlags(this._value);

  static List<CodeUnitFlags> extractForParagraph(WebParagraph paragraph) {
    // TODO(mdebbar=>jlavrova): If these are mostly hardcoded, let's move them to Dart instead of
    //                          calling to CanvasKit.
    final List<CodeUnitInfo> ckFlags = canvasKit.CodeUnits.compute(paragraph.text);
    assert(ckFlags.length == (paragraph.text.length + 1));

    final codeUnitFlags = ckFlags.map((info) => CodeUnitFlags(info.flags)).toList();

    // Get text segmentation resuls using browser APIs.
    final SegmentationResult result = segmentText(paragraph.text);

    // Fill out grapheme flags
    for (final index in result.graphemes) {
      codeUnitFlags[index].graphemeStart = true;
    }
    // Fill out word flags
    for (final index in result.words) {
      codeUnitFlags[index].wordBreak = true;
    }
    // Fill out line break flags
    for (int i = 0; i < result.breaks.length; i += 2) {
      final int index = result.breaks[i];
      final int type = result.breaks[i + 1];

      if (type == kSoftLineBreak) {
        codeUnitFlags[index].softLineBreak = true;
      } else {
        codeUnitFlags[index].hardLineBreak = true;
      }
    }
    return codeUnitFlags;
  }

  bool get isWhitespace => hasFlag(kWhitespaceFlag);
  set whitespace(bool enable) => _setFlag(kWhitespaceFlag, enable);

  bool get isGraphemeStart => hasFlag(kGraphemeFlag);
  set graphemeStart(bool enable) => _setFlag(kGraphemeFlag, enable);

  bool get isSoftLineBreak => hasFlag(kSoftLineBreakFlag);
  set softLineBreak(bool enable) => _setFlag(kSoftLineBreakFlag, enable);

  bool get isHardLineBreak => hasFlag(kHardLineBreakFlag);
  set hardLineBreak(bool enable) => _setFlag(kHardLineBreakFlag, enable);

  bool get isWordBreak => hasFlag(kWordBreakFlag);
  set wordBreak(bool enable) => _setFlag(kWordBreakFlag, enable);

  bool hasFlag(int flag) {
    return (_value & flag) != 0;
  }

  void _setFlag(int flag, bool enable) {
    _value = enable ? (_value | flag) : (_value & ~flag);
  }

  int _value;

  @override
  String toString() {
    return [
      if (isWhitespace) 'whitespace',
      if (isGraphemeStart) 'grapheme',
      if (isSoftLineBreak) 'softBreak',
      if (isHardLineBreak) 'hardBreak',
      if (isWordBreak) 'word',
    ].join(' ');
  }

  static const int kWhitespaceFlag = 1 << 0;
  static const int kGraphemeFlag = 1 << 1;
  static const int kSoftLineBreakFlag = 1 << 2;
  static const int kHardLineBreakFlag = 1 << 3;
  static const int kWordBreakFlag = 1 << 4;
}

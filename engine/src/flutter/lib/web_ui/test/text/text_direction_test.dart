// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

// Two RTL strings, 5 characters each, to match the length of "$rtl1" and "$rtl2".
const String rtl1 = 'واحدة';
const String rtl2 = 'ثنتان';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  group('$getDirectionalBlockEnd', () {

    test('basic cases', () {
      const String text = 'Lorem 12 $rtl1   ipsum34';
      const LineBreakResult start = LineBreakResult.sameIndex(0, LineBreakType.prohibited);
      const LineBreakResult end = LineBreakResult.sameIndex(text.length, LineBreakType.endOfText);
      const LineBreakResult loremMiddle = LineBreakResult.sameIndex(3, LineBreakType.prohibited);
      const LineBreakResult loremEnd = LineBreakResult.sameIndex(5, LineBreakType.prohibited);
      const LineBreakResult twelveStart = LineBreakResult(6, 6, 5, LineBreakType.opportunity);
      const LineBreakResult twelveEnd = LineBreakResult.sameIndex(8, LineBreakType.prohibited);
      const LineBreakResult rtl1Start = LineBreakResult(9, 9, 8, LineBreakType.opportunity);
      const LineBreakResult rtl1End = LineBreakResult.sameIndex(14, LineBreakType.prohibited);
      const LineBreakResult ipsumStart = LineBreakResult(17, 17, 15, LineBreakType.opportunity);
      const LineBreakResult ipsumEnd = LineBreakResult.sameIndex(22, LineBreakType.prohibited);

      DirectionalPosition blockEnd;

      blockEnd = getDirectionalBlockEnd(text, start, end);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, TextDirection.ltr);
      expect(blockEnd.lineBreak, loremEnd);

      blockEnd = getDirectionalBlockEnd(text, start, loremMiddle);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, TextDirection.ltr);
      expect(blockEnd.lineBreak, loremMiddle);

      blockEnd = getDirectionalBlockEnd(text, loremMiddle, loremEnd);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, TextDirection.ltr);
      expect(blockEnd.lineBreak, loremEnd);

      blockEnd = getDirectionalBlockEnd(text, loremEnd, twelveStart);
      expect(blockEnd.isSpaceOnly, isTrue);
      expect(blockEnd.textDirection, isNull);
      expect(blockEnd.lineBreak, twelveStart);

      blockEnd = getDirectionalBlockEnd(text, twelveStart, rtl1Start);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, isNull);
      expect(blockEnd.lineBreak, twelveEnd);

      blockEnd = getDirectionalBlockEnd(text, rtl1Start, end);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, TextDirection.rtl);
      expect(blockEnd.lineBreak, rtl1End);

      blockEnd = getDirectionalBlockEnd(text, ipsumStart, end);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, TextDirection.ltr);
      expect(blockEnd.lineBreak, ipsumEnd);

      blockEnd = getDirectionalBlockEnd(text, ipsumEnd, end);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, isNull);
      expect(blockEnd.lineBreak, end);
    });

    test('handles new lines', () {
      const String text = 'Lorem\n12\nipsum  \n';
      const LineBreakResult start = LineBreakResult.sameIndex(0, LineBreakType.prohibited);
      const LineBreakResult end = LineBreakResult(
        text.length,
        text.length - 1,
        text.length - 3,
        LineBreakType.mandatory,
      );
      const LineBreakResult loremEnd = LineBreakResult.sameIndex(5, LineBreakType.prohibited);
      const LineBreakResult twelveStart = LineBreakResult(6, 5, 5, LineBreakType.mandatory);
      const LineBreakResult twelveEnd = LineBreakResult.sameIndex(8, LineBreakType.prohibited);
      const LineBreakResult ipsumStart = LineBreakResult(9, 8, 8, LineBreakType.mandatory);
      const LineBreakResult ipsumEnd = LineBreakResult.sameIndex(14, LineBreakType.prohibited);

      DirectionalPosition blockEnd;

      blockEnd = getDirectionalBlockEnd(text, start, twelveStart);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, TextDirection.ltr);
      expect(blockEnd.lineBreak, twelveStart);

      blockEnd = getDirectionalBlockEnd(text, loremEnd, twelveStart);
      expect(blockEnd.isSpaceOnly, isTrue);
      expect(blockEnd.textDirection, isNull);
      expect(blockEnd.lineBreak, twelveStart);

      blockEnd = getDirectionalBlockEnd(text, twelveStart, ipsumStart);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, isNull);
      expect(blockEnd.lineBreak, ipsumStart);

      blockEnd = getDirectionalBlockEnd(text, twelveEnd, ipsumStart);
      expect(blockEnd.isSpaceOnly, isTrue);
      expect(blockEnd.textDirection, isNull);
      expect(blockEnd.lineBreak, ipsumStart);

      blockEnd = getDirectionalBlockEnd(text, ipsumStart, end);
      expect(blockEnd.isSpaceOnly, isFalse);
      expect(blockEnd.textDirection, TextDirection.ltr);
      expect(blockEnd.lineBreak, ipsumEnd);

      blockEnd = getDirectionalBlockEnd(text, ipsumEnd, end);
      expect(blockEnd.isSpaceOnly, isTrue);
      expect(blockEnd.textDirection, isNull);
      expect(blockEnd.lineBreak, end);
    });
  });
}

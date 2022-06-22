// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/canvaskit/embedded_views_diff.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('diffViewList', () {
    setUpCanvasKitTest();

    test('works in the expected case', () {
      ViewListDiffResult? result = diffViewList(
        <int>[1, 2, 3, 4, 5],
        <int>[3, 4, 5, 6, 7],
      );
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[6, 7]);
      expect(result.viewsToRemove, <int>[1, 2]);
      expect(result.addToBeginning, isFalse);

      result = diffViewList(
        <int>[3, 4, 5, 6, 7],
        <int>[1, 2, 3, 4, 5],
      );
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[1, 2]);
      expect(result.viewsToRemove, <int>[6, 7]);
      expect(result.addToBeginning, isTrue);
      expect(result.viewToInsertBefore, 3);

      result = diffViewList(<int>[3, 4, 5], <int>[2, 3, 4, 5]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[2]);
      expect(result.viewsToRemove, <int>[]);
      expect(result.addToBeginning, isTrue);
      expect(result.viewToInsertBefore, 3);

      result = diffViewList(<int>[3, 4, 5], <int>[3, 4, 5, 6]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[6]);
      expect(result.viewsToRemove, <int>[]);
      expect(result.addToBeginning, isFalse);

      result = diffViewList(<int>[3, 4, 5, 6], <int>[3, 4, 5]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[]);
      expect(result.viewsToRemove, <int>[6]);

      result = diffViewList(<int>[3, 4, 5, 6], <int>[4, 5, 6]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[]);
      expect(result.viewsToRemove, <int>[3]);
      expect(result.addToBeginning, isFalse);

      result = diffViewList(<int>[3, 4, 5, 6, 7, 8], <int>[3, 4, 5]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[]);
      expect(result.viewsToRemove, <int>[6, 7, 8]);

      result = diffViewList(<int>[1, 2, 3, 4, 5, 6], <int>[4, 5, 6]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[]);
      expect(result.viewsToRemove, <int>[1, 2, 3]);
      expect(result.addToBeginning, isFalse);

      result = diffViewList(<int>[3, 4, 5, 6, 7, 8], <int>[2, 3, 4, 5]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[2]);
      expect(result.viewsToRemove, <int>[6, 7, 8]);
      expect(result.addToBeginning, isTrue);
      expect(result.viewToInsertBefore, 3);

      result = diffViewList(<int>[1, 2, 3, 4, 5, 6], <int>[4, 5, 6, 7]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[7]);
      expect(result.viewsToRemove, <int>[1, 2, 3]);
      expect(result.addToBeginning, isFalse);

      result = diffViewList(<int>[1, 2, 3], <int>[4, 5]);
      expect(result, isNull);

      result = diffViewList(<int>[1, 2, 3, 4], <int>[2, 3, 5, 4]);
      expect(result, isNull);

      result = diffViewList(<int>[3, 4], <int>[1, 2, 3, 4, 5, 6]);
      expect(result, isNull);

      result = diffViewList(<int>[1, 2, 3, 4, 5], <int>[2, 3, 4]);
      expect(result, isNull);
    });

    test('works for flutter/flutter#101580', () {
      ViewListDiffResult? result;

      // Reverse the list
      result = diffViewList(<int>[1, 2, 3, 4], <int>[4, 3, 2, 1]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[3, 2, 1]);
      expect(result.viewsToRemove, <int>[1, 2, 3]);
      expect(result.addToBeginning, isFalse);

      // Sort the list
      result = diffViewList(<int>[3, 4, 1, 2], <int>[1, 2, 3, 4]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[3, 4]);
      expect(result.viewsToRemove, <int>[3, 4]);
      expect(result.addToBeginning, isFalse);

      // Move last view to the beginning
      result = diffViewList(<int>[2, 3, 4, 1], <int>[1, 2, 3, 4]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[1]);
      expect(result.viewsToRemove, <int>[1]);
      expect(result.addToBeginning, isTrue);
      expect(result.viewToInsertBefore, 2);

      // Shuffle the list
      result = diffViewList(<int>[1, 2, 3, 4], <int>[2, 4, 1, 3]);
      expect(result, isNull);
    });
  });
}

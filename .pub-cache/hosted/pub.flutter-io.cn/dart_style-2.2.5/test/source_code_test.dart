// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

void main() {
  var selection = SourceCode('123456;', selectionStart: 3, selectionLength: 2);
  var noSelection = SourceCode('123456;');

  group('constructor', () {
    test('throws on negative start', () {
      expect(() {
        SourceCode('12345;', selectionStart: -1, selectionLength: 0);
      }, throwsArgumentError);
    });

    test('throws on out of bounds start', () {
      expect(() {
        SourceCode('12345;', selectionStart: 7, selectionLength: 0);
      }, throwsArgumentError);
    });

    test('throws on negative length', () {
      expect(() {
        SourceCode('12345;', selectionStart: 1, selectionLength: -1);
      }, throwsArgumentError);
    });

    test('throws on out of bounds length', () {
      expect(() {
        SourceCode('12345;', selectionStart: 2, selectionLength: 5);
      }, throwsArgumentError);
    });

    test('throws is start is null and length is not', () {
      expect(() {
        SourceCode('12345;', selectionStart: 0);
      }, throwsArgumentError);
    });

    test('throws is length is null and start is not', () {
      expect(() {
        SourceCode('12345;', selectionLength: 1);
      }, throwsArgumentError);
    });
  });

  group('textBeforeSelection', () {
    test('gets substring before selection', () {
      expect(selection.textBeforeSelection, equals('123'));
    });

    test('gets entire string if no selection', () {
      expect(noSelection.textBeforeSelection, equals('123456;'));
    });
  });

  group('selectedText', () {
    test('gets selection substring', () {
      expect(selection.selectedText, equals('45'));
    });

    test('gets empty string if no selection', () {
      expect(noSelection.selectedText, equals(''));
    });
  });

  group('textAfterSelection', () {
    test('gets substring after selection', () {
      expect(selection.textAfterSelection, equals('6;'));
    });

    test('gets empty string if no selection', () {
      expect(noSelection.textAfterSelection, equals(''));
    });
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/reporting/pii_regexp.dart';
import 'package:test/test.dart';

void main() {
  group('filterPiiFromErrorMessage', () {
    test('filters paths greedily', () {
      expect(filterPiiFromErrorMessage(r'a message: C:\My\Special Path'),
          equals('a message: <path>'));
      expect(
          filterPiiFromErrorMessage(
              r'a message: C:\My\Overly\..\Complicated\Special Path'),
          equals('a message: <path>'));
      expect(
          filterPiiFromErrorMessage(r'a message: ..\A\Relative\Windows Path'),
          equals('a message: <path>'));
      expect(
          filterPiiFromErrorMessage(
              r'a message: A\Relatively\..\Complicated\Windows Path'),
          equals('a message: <path>'));
      expect(
          filterPiiFromErrorMessage(r'a message: \\My\Windows\Network Share'),
          equals('a message: <path>'));
      expect(filterPiiFromErrorMessage(r'a message: Q:\I Have A Lot of Drives'),
          equals('a message: <path>'));
      expect(filterPiiFromErrorMessage(r'a message: R:\'),
          equals('a message: <path>'));
      expect(
          filterPiiFromErrorMessage(r'a message: /Users/macuser/Desktop/dart/'),
          equals('a message: <path>'));
      expect(
          filterPiiFromErrorMessage(
              r'a message: ../relative_path/to_some/dart'),
          equals('a message: <path>'));
      expect(
          filterPiiFromErrorMessage(
              r'a message: embedded_dots/./../to_some/dart'),
          equals('a message: <path>'));
    });
    test('filters some complex examples derived from real exceptions', () {
      // Real world examples may not actually be perfectly readable due to the
      // greediness of the matchers, but that's the tradeoff for making sure we
      // get everything.
      expect(
          filterPiiFromErrorMessage(
              r'Could not resolve "package:an_important_package/an_important_package.dart" in C:\Users\AUser\dart\files\foo.dart'),
          equals('Could not resolve "<path>'));
      // Some exceptions print their exception name and put the path in quotes.
      // Be sure we find it.
      expect(
          filterPiiFromErrorMessage(
              r"PathNotFoundException: Cannot open file, path = '/Users/xuser/Documents/SomeStuff/flutter/version' (OS Error: No such file or directory, errno = 2)'"),
          equals("PathNotFoundException: Cannot open file, path = '<path>"));
    });
    test('filters filenames without path separators without being greedy', () {
      expect(filterPiiFromErrorMessage(r'mine.dart: a special file'),
          equals('<filename>: a special file'));
      expect(filterPiiFromErrorMessage(r'foo.js: a special file'),
          equals('<filename>: a special file'));
      expect(filterPiiFromErrorMessage(r'something.exe: a special file'),
          equals('<filename>: a special file'));
    });
    test('does not filter things that should not match', () {
      expect(filterPiiFromErrorMessage('User ran a Commodore 64 executable'),
          equals('User ran a Commodore 64 executable'));
      expect(
          filterPiiFromErrorMessage(
              'franchiseError: somehow Palpatine returned'),
          equals('franchiseError: somehow Palpatine returned'));
    });
  });
}

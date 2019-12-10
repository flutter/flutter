// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String base64PlistXml =
    'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHBsaXN0I'
    'FBVQkxJQyAiLS8vQXBwbGUvL0RURCBQTElTVCAxLjAvL0VOIiAiaHR0cDovL3d3dy5hcHBsZS'
    '5jb20vRFREcy9Qcm9wZXJ0eUxpc3QtMS4wLmR0ZCI+CjxwbGlzdCB2ZXJzaW9uPSIxLjAiPgo'
    '8ZGljdD4KICA8a2V5PkNGQnVuZGxlRXhlY3V0YWJsZTwva2V5PgogIDxzdHJpbmc+QXBwPC9z'
    'dHJpbmc+CiAgPGtleT5DRkJ1bmRsZUlkZW50aWZpZXI8L2tleT4KICA8c3RyaW5nPmlvLmZsd'
    'XR0ZXIuZmx1dHRlci5hcHA8L3N0cmluZz4KPC9kaWN0Pgo8L3BsaXN0Pgo=';

const String base64PlistBinary =
    'YnBsaXN0MDDSAQIDBF8QEkNGQnVuZGxlRXhlY3V0YWJsZV8QEkNGQnVuZGxlSWRlbnRpZmllc'
    'lNBcHBfEBZpby5mbHV0dGVyLmZsdXR0ZXIuYXBwCA0iNzsAAAAAAAABAQAAAAAAAAAFAAAAAA'
    'AAAAAAAAAAAAAAVA==';

const String base64PlistJson =
    'eyJDRkJ1bmRsZUV4ZWN1dGFibGUiOiJBcHAiLCJDRkJ1bmRsZUlkZW50aWZpZXIiOiJpby5mb'
    'HV0dGVyLmZsdXR0ZXIuYXBwIn0=';

void main() {
  group('PlistUtils', () {
    // The tests herein explicitly don't use `MemoryFileSystem` or a mocked
    // `ProcessManager` because doing so wouldn't actually test what we want to
    // test, which is that the underlying tool we're using to parse Plist files
    // works with the way we're calling it.
    final Map<Type, Generator> overrides = <Type, Generator>{
      FileSystem: () => const LocalFileSystemBlockingSetCurrentDirectory(),
      ProcessManager: () => const LocalProcessManager(),
    };

    const PlistParser parser = PlistParser();

    if (Platform.isMacOS) {
      group('getValueFromFile', () {
        File file;

        setUp(() {
          file = fs.file('foo.plist')..createSync();
        });

        tearDown(() {
          file.deleteSync();
        });

        testUsingContext('works with xml file', () async {
          file.writeAsBytesSync(base64.decode(base64PlistXml));
          expect(parser.getValueFromFile(file.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
          expect(parser.getValueFromFile(file.absolute.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
          expect(testLogger.statusText, isEmpty);
          expect(testLogger.errorText, isEmpty);
        }, overrides: overrides);

        testUsingContext('works with binary file', () async {
          file.writeAsBytesSync(base64.decode(base64PlistBinary));
          expect(parser.getValueFromFile(file.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
          expect(parser.getValueFromFile(file.absolute.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
          expect(testLogger.statusText, isEmpty);
          expect(testLogger.errorText, isEmpty);
        }, overrides: overrides);

        testUsingContext('works with json file', () async {
          file.writeAsBytesSync(base64.decode(base64PlistJson));
          expect(parser.getValueFromFile(file.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
          expect(parser.getValueFromFile(file.absolute.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
          expect(testLogger.statusText, isEmpty);
          expect(testLogger.errorText, isEmpty);
        }, overrides: overrides);

        testUsingContext('returns null for non-existent plist file', () async {
          expect(parser.getValueFromFile('missing.plist', 'CFBundleIdentifier'), null);
          expect(testLogger.statusText, isEmpty);
          expect(testLogger.errorText, isEmpty);
        }, overrides: overrides);

        testUsingContext('returns null for non-existent key within plist', () async {
          file.writeAsBytesSync(base64.decode(base64PlistXml));
          expect(parser.getValueFromFile(file.path, 'BadKey'), null);
          expect(parser.getValueFromFile(file.absolute.path, 'BadKey'), null);
          expect(testLogger.statusText, isEmpty);
          expect(testLogger.errorText, isEmpty);
        }, overrides: overrides);

        testUsingContext('returns null for malformed plist file', () async {
          file.writeAsBytesSync(const <int>[1, 2, 3, 4, 5, 6]);
          expect(parser.getValueFromFile(file.path, 'CFBundleIdentifier'), null);
          expect(testLogger.statusText, isNotEmpty);
          expect(testLogger.errorText, isEmpty);
        }, overrides: overrides);
      });
    } else {
      testUsingContext('throws when /usr/bin/plutil is not found', () async {
        expect(
          () => parser.getValueFromFile('irrelevant.plist', 'ununsed'),
          throwsA(isA<FileNotFoundException>()),
        );
        expect(testLogger.statusText, isEmpty);
        expect(testLogger.errorText, isEmpty);
      }, overrides: overrides);
    }
  });
}

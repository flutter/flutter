// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';

import '../src/common.dart';
import '../src/fakes.dart';
import 'test_utils.dart';

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

const String base64PlistXmlWithComplexDatatypes =
    'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHBsaXN0I'
    'FBVQkxJQyAiLS8vQXBwbGUvL0RURCBQTElTVCAxLjAvL0VOIiAiaHR0cDovL3d3dy5hcHBsZS'
    '5jb20vRFREcy9Qcm9wZXJ0eUxpc3QtMS4wLmR0ZCI+CjxwbGlzdCB2ZXJzaW9uPSIxLjAiPgo'
    '8ZGljdD4KICA8a2V5PkNGQnVuZGxlRXhlY3V0YWJsZTwva2V5PgogIDxzdHJpbmc+QXBwPC9z'
    'dHJpbmc+CiAgPGtleT5DRkJ1bmRsZUlkZW50aWZpZXI8L2tleT4KICA8c3RyaW5nPmlvLmZsd'
    'XR0ZXIuZmx1dHRlci5hcHA8L3N0cmluZz4KICA8a2V5PmludFZhbHVlPC9rZXk+CiAgPGludG'
    'VnZXI+MjwvaW50ZWdlcj4KICA8a2V5PmRvdWJsZVZhbHVlPC9rZXk+CiAgPHJlYWw+MS41PC9'
    'yZWFsPgogIDxrZXk+YmluYXJ5VmFsdWU8L2tleT4KICA8ZGF0YT5ZV0pqWkE9PTwvZGF0YT4K'
    'ICA8a2V5PmFycmF5VmFsdWU8L2tleT4KICA8YXJyYXk+CiAgICA8dHJ1ZSAvPgogICAgPGZhb'
    'HNlIC8+CiAgICA8aW50ZWdlcj4zPC9pbnRlZ2VyPgogIDwvYXJyYXk+CiAgPGtleT5kYXRlVm'
    'FsdWU8L2tleT4KICA8ZGF0ZT4yMDIxLTEyLTAxVDEyOjM0OjU2WjwvZGF0ZT4KPC9kaWN0Pgo'
    '8L3BsaXN0Pg==';

void main() {
  // The tests herein explicitly don't use `MemoryFileSystem` or a mocked
  // `ProcessManager` because doing so wouldn't actually test what we want to
  // test, which is that the underlying tool we're using to parse Plist files
  // works with the way we're calling it.
  File file;
  PlistParser parser;
  BufferLogger logger;

  setUp(() {
    logger = BufferLogger(
      outputPreferences: OutputPreferences.test(),
      terminal: AnsiTerminal(
        platform: const LocalPlatform(),
        stdio: FakeStdio(),
      ),
    );
    parser = PlistParser(
      fileSystem: fileSystem,
      processManager: processManager,
      logger: logger,
    );
    file = fileSystem.file('foo.plist')..createSync();
  });

  tearDown(() {
    file.deleteSync();
  });

  testWithoutContext('PlistParser.getStringValueFromFile works with xml file', () {
    file.writeAsBytesSync(base64.decode(base64PlistXml));

    expect(parser.getStringValueFromFile(file.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
    expect(parser.getStringValueFromFile(file.absolute.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
    expect(logger.statusText, isEmpty);
    expect(logger.errorText, isEmpty);
  }, skip: !platform.isMacOS); // [intended] requires macos tool chain.

  testWithoutContext('PlistParser.getStringValueFromFile works with binary file', () {
    file.writeAsBytesSync(base64.decode(base64PlistBinary));

    expect(parser.getStringValueFromFile(file.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
    expect(parser.getStringValueFromFile(file.absolute.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
    expect(logger.statusText, isEmpty);
    expect(logger.errorText, isEmpty);
  }, skip: !platform.isMacOS); // [intended] requires macos tool chain.

  testWithoutContext('PlistParser.getStringValueFromFile works with json file', () {
    file.writeAsBytesSync(base64.decode(base64PlistJson));

    expect(parser.getStringValueFromFile(file.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
    expect(parser.getStringValueFromFile(file.absolute.path, 'CFBundleIdentifier'), 'io.flutter.flutter.app');
    expect(logger.statusText, isEmpty);
    expect(logger.errorText, isEmpty);
  }, skip: !platform.isMacOS); // [intended] requires macos tool chain.

  testWithoutContext('PlistParser.getStringValueFromFile returns null for non-existent plist file', () {
    expect(parser.getStringValueFromFile('missing.plist', 'CFBundleIdentifier'), null);
    expect(logger.statusText, isEmpty);
    expect(logger.errorText, isEmpty);
  }, skip: !platform.isMacOS); // [intended] requires macos tool chain.

  testWithoutContext('PlistParser.getStringValueFromFile returns null for non-existent key within plist', () {
    file.writeAsBytesSync(base64.decode(base64PlistXml));

    expect(parser.getStringValueFromFile(file.path, 'BadKey'), null);
    expect(parser.getStringValueFromFile(file.absolute.path, 'BadKey'), null);
    expect(logger.statusText, isEmpty);
    expect(logger.errorText, isEmpty);
  }, skip: !platform.isMacOS); // [intended] requires macos tool chain.

  testWithoutContext('PlistParser.getStringValueFromFile returns null for malformed plist file', () {
    file.writeAsBytesSync(const <int>[1, 2, 3, 4, 5, 6]);

    expect(parser.getStringValueFromFile(file.path, 'CFBundleIdentifier'), null);
    expect(logger.statusText, isNotEmpty);
    expect(logger.errorText, isEmpty);
  }, skip: !platform.isMacOS); // [intended] requires macos tool chain.

  testWithoutContext('PlistParser.getStringValueFromFile throws when /usr/bin/plutil is not found', () async {
    file.writeAsBytesSync(base64.decode(base64PlistXml));

    expect(
      () => parser.getStringValueFromFile(file.path, 'unused'),
      throwsA(isA<FileNotFoundException>()),
    );
    expect(logger.statusText, isEmpty);
    expect(logger.errorText, isEmpty);
  }, skip: platform.isMacOS); // [intended] requires macos tool chain.

  testWithoutContext('PlistParser.parseFile can handle different datatypes', () async {
    file.writeAsBytesSync(base64.decode(base64PlistXmlWithComplexDatatypes));
    final Map<String, Object> values = parser.parseFile(file.path);

    expect(values['CFBundleIdentifier'], 'io.flutter.flutter.app');
    expect(values['CFBundleIdentifier'], 'io.flutter.flutter.app');
    expect(values['intValue'], 2);
    expect(values['doubleValue'], 1.5);
    expect(values['binaryValue'], base64.decode('YWJjZA=='));
    expect(values['arrayValue'], <dynamic>[true, false, 3]);
    expect(values['dateValue'], DateTime.utc(2021, 12, 1, 12, 34, 56));
    expect(logger.statusText, isEmpty);
    expect(logger.errorText, isEmpty);
  }, skip: !platform.isMacOS); // [intended] requires macos tool chain.
}

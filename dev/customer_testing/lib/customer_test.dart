// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';

@immutable
class CustomerTest {
  factory CustomerTest(File testFile) {
    final String errorPrefix = 'Could not parse: ${testFile.path}\n';
    final List<String> contacts = <String>[];
    final List<String> fetch = <String>[];
    final List<Directory> update = <Directory>[];
    final List<String> test = <String>[];
    bool hasTests = false;
    for (final String line in testFile.readAsLinesSync().map((String line) => line.trim())) {
      if (line.isEmpty) {
        // blank line
      } else if (line.startsWith('#')) {
        // comment
      } else if (line.startsWith('contact=')) {
        contacts.add(line.substring(8));
      } else if (line.startsWith('fetch=')) {
        fetch.add(line.substring(6));
      } else if (line.startsWith('update=')) {
        update.add(Directory(line.substring(7)));
      } else if (line.startsWith('test=')) {
        hasTests = true;
        test.add(line.substring(5));
      } else if (line.startsWith('test.windows=')) {
        hasTests = true;
        if (Platform.isWindows) {
          test.add(line.substring(13));
        }
      } else if (line.startsWith('test.macos=')) {
        hasTests = true;
        if (Platform.isMacOS) {
          test.add(line.substring(11));
        }
      } else if (line.startsWith('test.linux=')) {
        hasTests = true;
        if (Platform.isLinux) {
          test.add(line.substring(11));
        }
      } else if (line.startsWith('test.posix=')) {
        hasTests = true;
        if (Platform.isLinux || Platform.isMacOS) {
          test.add(line.substring(11));
        }
      } else {
        throw FormatException('${errorPrefix}Unexpected directive:\n$line');
      }
    }
    if (contacts.isEmpty) {
      throw FormatException('${errorPrefix}No contacts specified. At least one contact e-mail address must be specified.');
    }
    for (final String email in contacts) {
      if (!email.contains(_email) || email.endsWith('@example.com')) {
        throw FormatException('${errorPrefix}The following e-mail address appears to be an invalid e-mail address: $email');
      }
    }
    if (fetch.isEmpty) {
      throw FormatException('${errorPrefix}No "fetch" directives specified. Two lines are expected: "git clone https://github.com/USERNAME/REPOSITORY.git tests" and "git -C tests checkout HASH".');
    }
    if (fetch.length < 2) {
      throw FormatException('${errorPrefix}Only one "fetch" directive specified. Two lines are expected: "git clone https://github.com/USERNAME/REPOSITORY.git tests" and "git -C tests checkout HASH".');
    }
    if (!fetch[0].contains(_fetch1)) {
      throw FormatException('${errorPrefix}First "fetch" directive does not match expected pattern (expected "git clone https://github.com/USERNAME/REPOSITORY.git tests").');
    }
    if (!fetch[1].contains(_fetch2)) {
      throw FormatException('${errorPrefix}Second "fetch" directive does not match expected pattern (expected "git -C tests checkout HASH").');
    }
    if (update.isEmpty) {
      throw FormatException('${errorPrefix}No "update" directives specified. At least one directory must be specified. (It can be "." to just upgrade the root of the repository.)');
    }
    if (!hasTests) {
      throw FormatException('${errorPrefix}No "test" directives specified. At least one command must be specified to run tests.');
    }
    return CustomerTest._(
      List<String>.unmodifiable(contacts),
      List<String>.unmodifiable(fetch),
      List<Directory>.unmodifiable(update),
      List<String>.unmodifiable(test),
    );
  }

  const CustomerTest._(this.contacts, this.fetch, this.update, this.tests);

  // (e-mail regexp from HTML standard)
  static final RegExp _email = RegExp(r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
  static final RegExp _fetch1 = RegExp(r'^git(?: -c core.longPaths=true)? clone https://github.com/[-a-zA-Z0-9]+/[-_a-zA-Z0-9]+.git tests$');
  static final RegExp _fetch2 = RegExp(r'^git(?: -c core.longPaths=true)? -C tests checkout [0-9a-f]+$');

  final List<String> contacts;
  final List<String> fetch;
  final List<Directory> update;
  final List<String> tests;
}

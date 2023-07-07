// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'common.dart';

// This will be used in many of our unit tests.
void expectSetMatch<T>(Iterable<T> actual, Iterable<T> expected) {
  expect(Set<T>.from(actual), equals(Set<T>.from(expected)));
}

// May return null if the credentials file doesn't exist.
Map<String, dynamic>? getTestGcpCredentialsJson() {
  final File f = File('secret/test_gcp_credentials.json');
  if (!f.existsSync()) {
    return null;
  }
  return jsonDecode(File('secret/test_gcp_credentials.json').readAsStringSync())
      as Map<String, dynamic>?;
}

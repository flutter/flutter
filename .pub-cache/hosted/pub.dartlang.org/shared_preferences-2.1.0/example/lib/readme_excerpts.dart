// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs, unused_local_variable, invalid_use_of_visible_for_testing_member
import 'package:shared_preferences/shared_preferences.dart';

Future<void> readmeSnippets() async {
  // #docregion Write
  // Obtain shared preferences.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Save an integer value to 'counter' key.
  await prefs.setInt('counter', 10);
  // Save an boolean value to 'repeat' key.
  await prefs.setBool('repeat', true);
  // Save an double value to 'decimal' key.
  await prefs.setDouble('decimal', 1.5);
  // Save an String value to 'action' key.
  await prefs.setString('action', 'Start');
  // Save an list of strings to 'items' key.
  await prefs.setStringList('items', <String>['Earth', 'Moon', 'Sun']);
  // #enddocregion Write

  // #docregion Read
  // Try reading data from the 'counter' key. If it doesn't exist, returns null.
  final int? counter = prefs.getInt('counter');
  // Try reading data from the 'repeat' key. If it doesn't exist, returns null.
  final bool? repeat = prefs.getBool('repeat');
  // Try reading data from the 'decimal' key. If it doesn't exist, returns null.
  final double? decimal = prefs.getDouble('decimal');
  // Try reading data from the 'action' key. If it doesn't exist, returns null.
  final String? action = prefs.getString('action');
  // Try reading data from the 'items' key. If it doesn't exist, returns null.
  final List<String>? items = prefs.getStringList('items');
  // #enddocregion Read

  // #docregion Clear
  // Remove data for the 'counter' key.
  await prefs.remove('counter');
  // #enddocregion Clear
}

// Uses test-only code. invalid_use_of_visible_for_testing_member is suppressed
// for the whole file since otherwise there's no way to avoid it showing up in
// the excerpt, and that is definitely not something people should be copying
// from examples.
Future<void> readmeTestSnippets() async {
  // #docregion Tests
  final Map<String, Object> values = <String, Object>{'counter': 1};
  SharedPreferences.setMockInitialValues(values);
  // #enddocregion Tests
}

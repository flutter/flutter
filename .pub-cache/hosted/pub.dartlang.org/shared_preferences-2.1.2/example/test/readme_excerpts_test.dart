// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_example/readme_excerpts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sanity check readmeSnippets', () async {
    // This key is set and cleared in the snippets.
    const String clearedKey = 'counter';

    // Set a mock store so that there's a platform implementation.
    SharedPreferences.setMockInitialValues(<String, Object>{clearedKey: 2});

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Ensure that the snippet code runs successfully.
    await readmeSnippets();
    // Spot-check some functionality to ensure that it's showing working calls.
    // It should also set some preferences.
    expect(prefs.getBool('repeat'), isNotNull);
    expect(prefs.getDouble('decimal'), isNotNull);
    // It should clear this preference.
    expect(prefs.getInt(clearedKey), isNull);
  });

  test('readmeTestSnippets', () async {
    await readmeTestSnippets();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // The snippet sets a single initial pref.
    expect(prefs.getKeys().length, 1);
  });
}

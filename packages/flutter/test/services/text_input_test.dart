// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:test/test.dart';

void main() {
  group('TextInputConfiguration', () {
    test('sets expected defaults', () {
      const TextInputConfiguration configuration = const TextInputConfiguration();
      expect(configuration.inputType, TextInputType.text);
      expect(configuration.obscureText, false);
      expect(configuration.autocorrect, true);
      expect(configuration.actionLabel, null);
    });

    test('serializes to JSON', () async {
      const TextInputConfiguration configuration = const TextInputConfiguration(
        inputType: TextInputType.number,
        obscureText: true,
        autocorrect: false,
        actionLabel: 'xyzzy'
      );
      final Map<String, dynamic> json = configuration.toJSON();
      expect(json['inputType'], 'TextInputType.number');
      expect(json['obscureText'], true);
      expect(json['autocorrect'], false);
      expect(json['actionLabel'], 'xyzzy');
    });
  });
}

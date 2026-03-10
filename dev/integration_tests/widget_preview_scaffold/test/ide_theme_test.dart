// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE: these tests are originally from package:devtools_app_shared.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/theme/ide_theme.dart';

void main() {
  group('$IdeThemeQueryParams', () {
    test('successfully creates params', () {
      final params = IdeThemeQueryParams({
        'backgroundColor': '#112233',
        'foregroundColor': '#112244',
        'theme': 'dark',
      });

      expect(params.params, isNotEmpty);
      expect(params.backgroundColor, const Color(0xFF112233));
      expect(params.foregroundColor, const Color(0xFF112244));
      expect(params.darkMode, true);
    });

    test('handles bad input', () {
      final params = IdeThemeQueryParams({
        'backgroundColor': 'badcolor',
        'foregroundColor': 'badcolor',
        'theme': 'dark',
      });

      expect(params.params, isNotEmpty);
      expect(params.backgroundColor, isNull);
      expect(params.foregroundColor, isNull);
      expect(params.darkMode, true);
    });

    test('ignores unsupported query params', () {
      final params = IdeThemeQueryParams({
        'fontSize': '50', // Font size is not supported.
        'theme': 'dark',
      });

      expect(params.darkMode, true);
    });

    test('creates empty params', () {
      final params = IdeThemeQueryParams({});
      expect(params.params, isEmpty);
      expect(params.backgroundColor, isNull);
      expect(params.foregroundColor, isNull);
      expect(params.darkMode, true);
    });
  });
}

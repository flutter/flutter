// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:test/test.dart';

void main() {

  group('dart-defines and web-renderer options', () {
    late List<String> dartDefines;

    setUp(() {
      dartDefines = <String>[];
    });

    test('auto web-renderer with no dart-defines', () {
      dartDefines = updateDartDefines(dartDefines, WebRendererMode.auto);
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=true']);
    });

    test('canvaskit web-renderer with no dart-defines', () {
      dartDefines = updateDartDefines(dartDefines, WebRendererMode.canvaskit);
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=false','FLUTTER_WEB_USE_SKIA=true']);
    });

    test('html web-renderer with no dart-defines', () {
      dartDefines = updateDartDefines(dartDefines, WebRendererMode.html);
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=false','FLUTTER_WEB_USE_SKIA=false']);
    });

    test('auto web-renderer with existing dart-defines', () {
      dartDefines = <String>['FLUTTER_WEB_USE_SKIA=false'];
      dartDefines = updateDartDefines(dartDefines, WebRendererMode.auto);
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=true']);
    });

    test('canvaskit web-renderer with no dart-defines', () {
      dartDefines = <String>['FLUTTER_WEB_USE_SKIA=false'];
      dartDefines = updateDartDefines(dartDefines, WebRendererMode.canvaskit);
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=false','FLUTTER_WEB_USE_SKIA=true']);
    });

    test('html web-renderer with no dart-defines', () {
      dartDefines = <String>['FLUTTER_WEB_USE_SKIA=true'];
      dartDefines = updateDartDefines(dartDefines, WebRendererMode.html);
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=false','FLUTTER_WEB_USE_SKIA=false']);
    });
  });
}

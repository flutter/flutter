// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<MethodCall> recordPlatformCalls({bool? showResult}) {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return call.method == 'Magnifier.showSystemMagnifier' ? showResult : null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    return calls;
  }

  test('show sends the gesture position and caret rect', () async {
    final List<MethodCall> calls = recordPlatformCalls(showResult: true);

    await SystemMagnifier.show(
      gesturePosition: const Offset(10, 20),
      caretRect: const Rect.fromLTWH(8, 12, 2, 18),
    );

    expect(calls, <Matcher>[
      isMethodCall(
        'Magnifier.showSystemMagnifier',
        arguments: <String, Object>{
          'position': <String, double>{'x': 10, 'y': 20},
          'caretRect': <String, double>{'x': 8, 'y': 12, 'width': 2, 'height': 18},
        },
      ),
    ]);
  });

  test('show maps the platform result', () async {
    Future<SystemMagnifierShowResult> show() {
      return SystemMagnifier.show(
        gesturePosition: const Offset(10, 20),
        caretRect: const Rect.fromLTWH(8, 12, 2, 18),
      );
    }

    recordPlatformCalls(showResult: true);
    expect(await show(), SystemMagnifierShowResult.shown);

    recordPlatformCalls(showResult: false);
    expect(await show(), SystemMagnifierShowResult.notShown);

    recordPlatformCalls();
    expect(await show(), SystemMagnifierShowResult.unsupported);
  });

  test('hide sends the hide call', () async {
    final List<MethodCall> calls = recordPlatformCalls();

    await SystemMagnifier.hide();

    expect(calls, <Matcher>[isMethodCall('Magnifier.hideSystemMagnifier', arguments: null)]);
  });
}

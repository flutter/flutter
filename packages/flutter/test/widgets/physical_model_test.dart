// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

const Color _debugBlack = Color(0xFF000000);
const Color _debugCanvas = Color(0xFFFAFAFA);
const Color _debugText = Color(0xDD000000);

void main() {
  testWidgets('PhysicalModel updates clipBehavior in updateRenderObject', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TestWidgetsApp(home: PhysicalModel(color: _debugBlack)));

    final RenderPhysicalModel renderPhysicalModel = tester.allRenderObjects
        .whereType<RenderPhysicalModel>()
        .first;

    expect(renderPhysicalModel.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(
      const TestWidgetsApp(
        home: PhysicalModel(clipBehavior: Clip.antiAlias, color: _debugBlack),
      ),
    );

    expect(renderPhysicalModel.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('PhysicalShape updates clipBehavior in updateRenderObject', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: PhysicalShape(
          color: _debugBlack,
          clipper: ShapeBorderClipper(shape: CircleBorder()),
        ),
      ),
    );

    final RenderPhysicalShape renderPhysicalShape = tester.allRenderObjects
        .whereType<RenderPhysicalShape>()
        .first;

    expect(renderPhysicalShape.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(
      const TestWidgetsApp(
        home: PhysicalShape(
          clipBehavior: Clip.antiAlias,
          color: _debugBlack,
          clipper: ShapeBorderClipper(shape: CircleBorder()),
        ),
      ),
    );

    expect(renderPhysicalShape.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('PhysicalModel - clips when overflows and elevation is 0', (
    WidgetTester tester,
  ) async {
    const key = Key('test');
    await tester.pumpWidget(
      const MediaQuery(
        key: key,
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: TextStyle(color: _debugText, fontFamily: 'Roboto'),
            child: Padding(
              padding: EdgeInsets.all(50),
              child: Row(
                children: <Widget>[
                  PhysicalModel(
                    color: _debugCanvas,
                    child: Text('A long long long long long long long string'),
                  ),
                  PhysicalModel(
                    color: _debugCanvas,
                    child: Text('A long long long long long long long string'),
                  ),
                  PhysicalModel(
                    color: _debugCanvas,
                    child: Text('A long long long long long long long string'),
                  ),
                  PhysicalModel(
                    color: _debugCanvas,
                    child: Text('A long long long long long long long string'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    // ignore: avoid_dynamic_calls
    expect(exception.diagnostics.first.level, DiagnosticLevel.summary);
    // ignore: avoid_dynamic_calls
    expect(exception.diagnostics.first.toString(), startsWith('A RenderFlex overflowed by '));
    await expectLater(find.byKey(key), matchesGoldenFile('physical_model_overflow.png'));
  });
}

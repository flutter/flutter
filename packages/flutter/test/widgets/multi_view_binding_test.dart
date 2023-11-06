// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgetsWithLeakTracking('runApp uses deprecated pipelineOwner and renderView', (WidgetTester tester) async {
    runApp(const SizedBox());
    final RenderObject renderObject = tester.renderObject(find.byType(SizedBox));

    RenderObject parent = renderObject;
    while (parent.parent != null) {
      parent = parent.parent!;
    }
    expect(parent, isA<RenderView>());
    expect(parent, equals(tester.binding.renderView));

    expect(renderObject.owner, equals(tester.binding.pipelineOwner));
  });

  testWidgetsWithLeakTracking('can manually attach RootWidget to build owner', (WidgetTester tester) async {
    expect(find.byType(ColoredBox), findsNothing);

    final RootWidget rootWidget = RootWidget(
      child: View(
        view: tester.view,
        child: const ColoredBox(color: Colors.orange),
      ),
    );
    tester.binding.attachToBuildOwner(rootWidget);
    await tester.pump();
    expect(find.byType(ColoredBox), findsOneWidget);
    expect(tester.binding.rootElement!.widget, equals(rootWidget));
    expect(tester.element(find.byType(ColoredBox)).owner, equals(tester.binding.buildOwner));
  });
}

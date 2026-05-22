// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _grey500 = Color(0xFF9E9E9E);
const Color _black = Color(0xFF000000);
const Color _red500 = Color(0xFFF44336);

void main() {
  final TestWidgetsFlutterBinding binding = _GestureBindingSpy();

  testWidgets('attach and detach correctly handle gesture', (_) async {
    expect(TestWidgetsFlutterBinding.instance, binding);
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final offset = ViewportOffset.zero();
    addTearDown(offset.dispose);
    final editable = RenderEditable(
      backgroundCursorColor: _grey500,
      selectionColor: _black,
      textDirection: TextDirection.ltr,
      cursorColor: _red500,
      offset: offset,
      textSelectionDelegate: delegate,
      text: const TextSpan(text: 'test', style: TextStyle(height: 1.0, fontSize: 10.0)),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      selection: const TextSelection(
        baseOffset: 0,
        extentOffset: 3,
        affinity: TextAffinity.upstream,
      ),
    );
    addTearDown(editable.dispose);
    editable.layout(BoxConstraints.loose(const Size(1000.0, 1000.0)));

    final owner = PipelineOwner(onNeedVisualUpdate: () {});
    addTearDown(owner.dispose);
    final spy = GestureBinding.instance.pointerRouter as _PointerRouterSpy;
    editable.attach(owner);
    // This should register pointer into GestureBinding.instance.pointerRouter.
    editable.handleEvent(const PointerDownEvent(), BoxHitTestEntry(editable, const Offset(10, 10)));
    GestureBinding.instance.pointerRouter.route(const PointerDownEvent());
    expect(spy.routeCount, greaterThan(0));
    editable.detach();
    expect(spy.routeCount, 0);
  });
}

class _GestureBindingSpy extends AutomatedTestWidgetsFlutterBinding {
  final PointerRouter _testPointerRouter = _PointerRouterSpy();

  @override
  PointerRouter get pointerRouter => _testPointerRouter;
}

class FakeEditableTextState extends Fake implements TextSelectionDelegate {}

class _PointerRouterSpy extends PointerRouter {
  int routeCount = 0;
  @override
  void addRoute(int pointer, PointerRoute route, [Matrix4? transform]) {
    super.addRoute(pointer, route, transform);
    routeCount++;
  }

  @override
  void removeRoute(int pointer, PointerRoute route) {
    super.removeRoute(pointer, route);
    routeCount--;
  }
}

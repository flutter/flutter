// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_alternative.dart' show Fake;

void main() {
  setUp(() => _GestureBindingSpy());

  test('attach and detach correctly handle gesture', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      text: const TextSpan(
        text: 'test',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      selection: const TextSelection(
        baseOffset: 0,
        extentOffset: 3,
        affinity: TextAffinity.upstream,
      ),
      onSelectionChanged: (_, __, ___) { },
    );
    editable.layout(BoxConstraints.loose(const Size(1000.0, 1000.0)));

    final PipelineOwner owner = PipelineOwner(onNeedVisualUpdate: () { });
    final _PointerRouterSpy spy = GestureBinding.instance.pointerRouter as _PointerRouterSpy;
    editable.attach(owner);
    // This should register pointer into GestureBinding.instance.pointerRouter.
    editable.handleEvent(const PointerDownEvent(), BoxHitTestEntry(editable, const Offset(10,10)));
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

class FakeEditableTextState extends TextSelectionDelegate with Fake { }

class _PointerRouterSpy extends PointerRouter {
  int routeCount = 0;
  @override
  void addRoute(int pointer, PointerRoute route, [Matrix4 transform]) {
    super.addRoute(pointer, route, transform);
    routeCount++;
  }

  @override
  void removeRoute(int pointer, PointerRoute route) {
    super.removeRoute(pointer, route);
    routeCount--;
  }
}

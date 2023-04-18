// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final MemoryAllocations ma = MemoryAllocations.instance;

  setUp(() {
    assert(!ma.hasListeners);
  });

  testWidgets(
    '$MemoryAllocations is noop when kFlutterMemoryAllocationsEnabled is false.',
    (final WidgetTester tester) async {
      ObjectEvent? receivedEvent;
      ObjectEvent listener(final ObjectEvent event) => receivedEvent = event;

      ma.addListener(listener);
      expect(ma.hasListeners, isFalse);

      await _activateFlutterObjects(tester);
      expect(receivedEvent, isNull);
      expect(ma.hasListeners, isFalse);

      ma.removeListener(listener);
    },
  );
}

class _TestLeafRenderObjectWidget extends LeafRenderObjectWidget {
  @override
  RenderObject createRenderObject(final BuildContext context) {
    return _TestRenderObject();
  }
}

class _TestRenderObject extends RenderObject {
  @override
  void debugAssertDoesMeetConstraints() {}

  @override
  Rect get paintBounds => throw UnimplementedError();

  @override
  void performLayout() {}

  @override
  void performResize() {}

  @override
  Rect get semanticBounds => throw UnimplementedError();
}

class _TestElement extends RenderObjectElement with RootElementMixin {
  _TestElement(): super(_TestLeafRenderObjectWidget());

  void makeInactive() {
    assignOwner(BuildOwner(focusManager: FocusManager()));
    mount(null, null);
    deactivate();
  }

  @override
  void insertRenderObjectChild(covariant final RenderObject child, covariant final Object? slot) { }

  @override
  void moveRenderObjectChild(covariant final RenderObject child, covariant final Object? oldSlot, covariant final Object? newSlot) { }

  @override
  void removeRenderObjectChild(covariant final RenderObject child, covariant final Object? slot) { }
}

class _MyStatefulWidget extends StatefulWidget {
  const _MyStatefulWidget();

  @override
  State<_MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<_MyStatefulWidget> {
  @override
  Widget build(final BuildContext context) {
    return Container();
  }
}

/// Create and dispose Flutter objects to fire memory allocation events.
Future<void> _activateFlutterObjects(final WidgetTester tester) async {
  final _TestElement element = _TestElement();
  element.makeInactive(); element.unmount();

  // Create and dispose State:
  await tester.pumpWidget(const _MyStatefulWidget());
  await tester.pumpWidget(const SizedBox.shrink());
}

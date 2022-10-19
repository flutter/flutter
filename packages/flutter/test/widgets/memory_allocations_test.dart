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

  test('Publishers dispatch events in debug mode', () async {
    int eventCount = 0;
    void listener(ObjectEvent event) => eventCount++;
    ma.addListener(listener);

    final int expectedEventCount = await _activateFlutterObjectsAndReturnCountOfEvents();
    expect(eventCount, expectedEventCount);

    ma.removeListener(listener);
    expect(ma.hasListeners, isFalse);
  });

  testWidgets('State dispatches events in debug mode', (WidgetTester tester) async {
    bool stateCreated = false;
    bool stateDisposed = false;

    void listener(ObjectEvent event) {
      if (event is ObjectCreated && event.object is State) {
        stateCreated = true;
      }
      if (event is ObjectDisposed && event.object is State) {
        stateDisposed = true;
      }
    }
    ma.addListener(listener);

    await tester.pumpWidget(const _TestStatefulWidget());
    expect(stateCreated, isTrue);
    expect(stateDisposed, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());

    expect(stateCreated, isTrue);
    expect(stateDisposed, isTrue);
    ma.removeListener(listener);
    expect(ma.hasListeners, isFalse);
  });
}

class _TestLeafRenderObjectWidget extends LeafRenderObjectWidget {
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TestRenderObject();
  }
}

class _TestElement extends RootRenderObjectElement{
  _TestElement(): super(_TestLeafRenderObjectWidget());

  void makeInactive() {
    assignOwner(BuildOwner(focusManager: FocusManager()));
    mount(null, null);
    deactivate();
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


class _TestStatefulWidget extends StatefulWidget {
  const _TestStatefulWidget();

  @override
  State<_TestStatefulWidget> createState() => _TestStatefulWidgetState();
}

class _TestStatefulWidgetState extends State<_TestStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// Create and dispose Flutter objects to fire memory allocation events.
Future<int> _activateFlutterObjectsAndReturnCountOfEvents() async {
  int count = 0;

  final _TestElement element = _TestElement(); count++;
  final RenderObject renderObject = _TestRenderObject(); count++;

  element.makeInactive(); element.unmount(); count += 3;
  renderObject.dispose(); count++;

  return count;
}

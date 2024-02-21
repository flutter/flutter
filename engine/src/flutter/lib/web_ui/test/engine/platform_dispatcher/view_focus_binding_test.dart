// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group(ViewFocusBinding, () {
    late EnginePlatformDispatcher platformDispatcher;

    setUp(() {
      platformDispatcher = EnginePlatformDispatcher.instance;
      domDocument.activeElement?.blur();
    });

    test('fires a focus event - a view was focused', () async {
      final List<ui.ViewFocusEvent> viewFocusEvents = <ui.ViewFocusEvent>[];
      final DomElement div = createDomElement('div');
      final EngineFlutterView view = EngineFlutterView(platformDispatcher, div);
      final DomElement focusableViewElement = div
          .querySelector(DomManager.flutterViewTagName)!
        ..setAttribute('tabindex', 0);

      platformDispatcher.onViewFocusChange = viewFocusEvents.add;
      domDocument.body!.append(div);
      focusableViewElement.focus();

      expect(viewFocusEvents, hasLength(1));

      expect(viewFocusEvents[0].viewId, view.viewId);
      expect(viewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(viewFocusEvents[0].direction, ui.ViewFocusDirection.forward);
    });

    test('fires a focus event - a view was unfocused', () async {
      final List<ui.ViewFocusEvent> viewFocusEvents = <ui.ViewFocusEvent>[];
      final DomElement div = createDomElement('div');
      final EngineFlutterView view = EngineFlutterView(platformDispatcher, div);
      final DomElement focusableViewElement = div
          .querySelector(DomManager.flutterViewTagName)!
        ..setAttribute('tabindex', 0);

      platformDispatcher.onViewFocusChange = viewFocusEvents.add;
      domDocument.body!.append(div);
      focusableViewElement.focus();
      focusableViewElement.blur();

      expect(viewFocusEvents, hasLength(2));

      expect(viewFocusEvents[0].viewId, view.viewId);
      expect(viewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(viewFocusEvents[0].direction, ui.ViewFocusDirection.forward);

      expect(viewFocusEvents[1].viewId, view.viewId);
      expect(viewFocusEvents[1].state, ui.ViewFocusState.unfocused);
      expect(viewFocusEvents[1].direction, ui.ViewFocusDirection.undefined);
    });

    test('fires a focus event - focus transitions between views', () async {
      final List<ui.ViewFocusEvent> viewFocusEvents = <ui.ViewFocusEvent>[];
      final DomElement div1 = createDomElement('div');
      final DomElement div2 = createDomElement('div');
      final EngineFlutterView view1 =
          EngineFlutterView(platformDispatcher, div1);
      final EngineFlutterView view2 =
          EngineFlutterView(platformDispatcher, div2);
      final DomElement focusableViewElement1 = div1
          .querySelector(DomManager.flutterViewTagName)!
        ..setAttribute('tabindex', 0);
      final DomElement focusableViewElement2 = div2
          .querySelector(DomManager.flutterViewTagName)!
        ..setAttribute('tabindex', 0);

      domDocument.body!.append(div1);
      domDocument.body!.append(div2);

      platformDispatcher.onViewFocusChange = viewFocusEvents.add;

      focusableViewElement1.focus();
      focusableViewElement2.focus();

      expect(viewFocusEvents, hasLength(2));

      expect(viewFocusEvents[0].viewId, view1.viewId);
      expect(viewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(viewFocusEvents[0].direction, ui.ViewFocusDirection.forward);

      expect(viewFocusEvents[1].viewId, view2.viewId);
      expect(viewFocusEvents[1].state, ui.ViewFocusState.focused);
      expect(viewFocusEvents[1].direction, ui.ViewFocusDirection.forward);
    });

    test('fires a focus event - focus transitions on and off views', () async {
      final List<ui.ViewFocusEvent> viewFocusEvents = <ui.ViewFocusEvent>[];
      final DomElement div1 = createDomElement('div');
      final DomElement div2 = createDomElement('div');
      final EngineFlutterView view1 =
          EngineFlutterView(platformDispatcher, div1);
      final EngineFlutterView view2 =
          EngineFlutterView(platformDispatcher, div2);
      final DomElement focusableViewElement1 = div1
          .querySelector(DomManager.flutterViewTagName)!
        ..setAttribute('tabindex', 0);
      final DomElement focusableViewElement2 = div2
          .querySelector(DomManager.flutterViewTagName)!
        ..setAttribute('tabindex', 0);

      domDocument.body!.append(div1);
      domDocument.body!.append(div2);

      platformDispatcher.onViewFocusChange = viewFocusEvents.add;

      focusableViewElement1.focus();
      focusableViewElement2.focus();
      focusableViewElement2.blur();

      expect(viewFocusEvents, hasLength(3));

      expect(viewFocusEvents[0].viewId, view1.viewId);
      expect(viewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(viewFocusEvents[0].direction, ui.ViewFocusDirection.forward);

      expect(viewFocusEvents[1].viewId, view2.viewId);
      expect(viewFocusEvents[1].state, ui.ViewFocusState.focused);
      expect(viewFocusEvents[1].direction, ui.ViewFocusDirection.forward);

      expect(viewFocusEvents[2].viewId, view2.viewId);
      expect(viewFocusEvents[2].state, ui.ViewFocusState.unfocused);
      expect(viewFocusEvents[2].direction, ui.ViewFocusDirection.undefined);
    });
  });
}

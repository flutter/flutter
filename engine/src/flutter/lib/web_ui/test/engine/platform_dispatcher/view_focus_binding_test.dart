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
    late List<ui.ViewFocusEvent> dispatchedViewFocusEvents;
    late EnginePlatformDispatcher dispatcher;

    setUp(() {
      dispatcher = EnginePlatformDispatcher.instance;
      dispatchedViewFocusEvents = <ui.ViewFocusEvent>[];
      dispatcher.onViewFocusChange = dispatchedViewFocusEvents.add;
    });

    tearDown(() {
      EngineSemantics.instance.semanticsEnabled = false;
      endFakeTextEditing();
    });

    test('The view is focusable and reachable by keyboard when registered', () async {
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      // The root element should have a tabindex="0" to make the flutter view
      // focusable and reachable by the keyboard.
      expect(view.dom.rootElement.getAttribute('tabindex'), '0');
    });

    test('The view is focusable but not reachable by keyboard when focused', () async {
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      view.dom.rootElement.focusWithoutScroll();

      // The root element should have a tabindex="-1" to make the flutter view
      // focusable but not reachable by the keyboard.
      expect(view.dom.rootElement.getAttribute('tabindex'), '-1');
    });

    test('marks the focusable views as reachable by the keyboard or not', () async {
      final EngineFlutterView view1 = createAndRegisterView(dispatcher);
      final EngineFlutterView view2 = createAndRegisterView(dispatcher);

      expect(view1.dom.rootElement.getAttribute('tabindex'), '0');
      expect(view2.dom.rootElement.getAttribute('tabindex'), '0');

      view1.dom.rootElement.focusWithoutScroll();
      expect(view1.dom.rootElement.getAttribute('tabindex'), '-1');
      expect(view2.dom.rootElement.getAttribute('tabindex'), '0');

      view2.dom.rootElement.focusWithoutScroll();
      expect(view1.dom.rootElement.getAttribute('tabindex'), '0');
      expect(view2.dom.rootElement.getAttribute('tabindex'), '-1');

      view2.dom.rootElement.blur();
      expect(view1.dom.rootElement.getAttribute('tabindex'), '0');
      expect(view2.dom.rootElement.getAttribute('tabindex'), '0');
    });

    test('fires a focus event - a view was focused', () async {
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      view.dom.rootElement.focusWithoutScroll();

      expect(dispatchedViewFocusEvents, hasLength(1));

      expect(dispatchedViewFocusEvents[0].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);
    });

    test('fires a focus event - a view was unfocused', () async {
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      view.dom.rootElement.focusWithoutScroll();
      view.dom.rootElement.blur();

      expect(dispatchedViewFocusEvents, hasLength(2));

      expect(dispatchedViewFocusEvents[0].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);

      expect(dispatchedViewFocusEvents[1].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[1].state, ui.ViewFocusState.unfocused);
      expect(dispatchedViewFocusEvents[1].direction, ui.ViewFocusDirection.undefined);
    });

    test('fires a focus event - focus transitions between views', () async {
      final EngineFlutterView view1 = createAndRegisterView(dispatcher);
      final EngineFlutterView view2 = createAndRegisterView(dispatcher);

      view1.dom.rootElement.focusWithoutScroll();
      view2.dom.rootElement.focusWithoutScroll();
      // The statements simulate the user pressing shift + tab in the keyboard.
      // Synthetic keyboard events do not trigger focus changes.
      domDocument.body!.pressTabKey(shift: true);
      view1.dom.rootElement.focusWithoutScroll();
      domDocument.body!.releaseTabKey();

      expect(dispatchedViewFocusEvents, hasLength(3));

      expect(dispatchedViewFocusEvents[0].viewId, view1.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);

      expect(dispatchedViewFocusEvents[1].viewId, view2.viewId);
      expect(dispatchedViewFocusEvents[1].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[1].direction, ui.ViewFocusDirection.forward);

      expect(dispatchedViewFocusEvents[2].viewId, view1.viewId);
      expect(dispatchedViewFocusEvents[2].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[2].direction, ui.ViewFocusDirection.backward);
    });

    test('fires a focus event - focus transitions on and off views', () async {
      final EngineFlutterView view1 = createAndRegisterView(dispatcher);
      final EngineFlutterView view2 = createAndRegisterView(dispatcher);

      view1.dom.rootElement.focusWithoutScroll();
      view2.dom.rootElement.focusWithoutScroll();
      view2.dom.rootElement.blur();

      expect(dispatchedViewFocusEvents, hasLength(3));

      expect(dispatchedViewFocusEvents[0].viewId, view1.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);

      expect(dispatchedViewFocusEvents[1].viewId, view2.viewId);
      expect(dispatchedViewFocusEvents[1].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[1].direction, ui.ViewFocusDirection.forward);

      expect(dispatchedViewFocusEvents[2].viewId, view2.viewId);
      expect(dispatchedViewFocusEvents[2].state, ui.ViewFocusState.unfocused);
      expect(dispatchedViewFocusEvents[2].direction, ui.ViewFocusDirection.undefined);
    });

    test('requestViewFocusChange focuses the view', () {
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      dispatcher.requestViewFocusChange(
        viewId: view.viewId,
        state: ui.ViewFocusState.focused,
        direction: ui.ViewFocusDirection.forward,
      );

      expect(domDocument.activeElement, view.dom.rootElement);

      expect(dispatchedViewFocusEvents, hasLength(1));

      expect(dispatchedViewFocusEvents[0].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);
    });

    test('requestViewFocusChange blurs the view', () {
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      dispatcher.requestViewFocusChange(
        viewId: view.viewId,
        state: ui.ViewFocusState.focused,
        direction: ui.ViewFocusDirection.forward,
      );

      dispatcher.requestViewFocusChange(
        viewId: view.viewId,
        state: ui.ViewFocusState.unfocused,
        direction: ui.ViewFocusDirection.undefined,
      );

      expect(domDocument.activeElement, isNot(view.dom.rootElement));

      expect(dispatchedViewFocusEvents, hasLength(2));

      expect(dispatchedViewFocusEvents[0].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);

      expect(dispatchedViewFocusEvents[1].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[1].state, ui.ViewFocusState.unfocused);
      expect(dispatchedViewFocusEvents[1].direction, ui.ViewFocusDirection.undefined);
    });

    test('requestViewFocusChange does nothing if the view does not exist', () {
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      dispatcher.requestViewFocusChange(
        viewId: 5094555,
        state: ui.ViewFocusState.focused,
        direction: ui.ViewFocusDirection.forward,
      );

      expect(domDocument.activeElement, isNot(view.dom.rootElement));
      expect(dispatchedViewFocusEvents, isEmpty);
    });

    test('requestViewFocusChange does nothing if the view is already focused', () {
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      dispatcher.requestViewFocusChange(
        viewId: view.viewId,
        state: ui.ViewFocusState.focused,
        direction: ui.ViewFocusDirection.forward,
      );
      dispatcher.requestViewFocusChange(
        viewId: view.viewId,
        state: ui.ViewFocusState.focused,
        direction: ui.ViewFocusDirection.forward,
      );

      expect(dispatchedViewFocusEvents, hasLength(1));

      expect(dispatchedViewFocusEvents[0].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);
    });

    test('requestViewFocusChange does not move the focus to the view', () {
      final DomElement input = createDomElement('input');
      final EngineFlutterView view = createAndRegisterView(dispatcher);

      view.dom.rootElement.append(input);
      input.focusWithoutScroll();

      dispatcher.requestViewFocusChange(
        viewId: view.viewId,
        state: ui.ViewFocusState.focused,
        direction: ui.ViewFocusDirection.forward,
      );

      expect(domDocument.activeElement, input);

      expect(dispatchedViewFocusEvents, hasLength(1));

      expect(dispatchedViewFocusEvents[0].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);
    });

    test('works even if focus is changed in the middle of a blur call', () {
      final DomElement input1 = createDomElement('input');
      final DomElement input2 = createDomElement('input');
      final EngineFlutterView view = createAndRegisterView(dispatcher);
      final DomEventListener focusInput1Listener = createDomEventListener((DomEvent event) {
        input1.focusWithoutScroll();
      });

      view.dom.rootElement.append(input1);
      view.dom.rootElement.append(input2);

      input1.addEventListener('blur', focusInput1Listener);
      input1.focusWithoutScroll();
      // The event handler above should move the focus back to input1.
      input2.focusWithoutScroll();
      input1.removeEventListener('blur', focusInput1Listener);

      expect(dispatchedViewFocusEvents, hasLength(1));

      expect(dispatchedViewFocusEvents[0].viewId, view.viewId);
      expect(dispatchedViewFocusEvents[0].state, ui.ViewFocusState.focused);
      expect(dispatchedViewFocusEvents[0].direction, ui.ViewFocusDirection.forward);
    });

    // On iOS a native caret/selection drag transiently blurs Flutter's active
    // text-editing element to <body> (relatedTarget == null) while the document
    // still has focus, and WebKit refocuses it a frame later. The view-unfocused
    // report is deferred so that refocus cancels it.
    // Regression test for https://github.com/flutter/flutter/issues/189744
    test('drops the deferred view-unfocused report when the editing input '
        'refocuses on iOS', () async {
      final EngineFlutterView view = createAndRegisterView(dispatcher);
      final DomHTMLInputElement input = createDomHTMLInputElement();
      view.dom.rootElement.append(input);
      input.focusWithoutScroll();
      beginFakeTextEditing(input);
      dispatchedViewFocusEvents.clear();

      debugEmulateIosSafari = true;
      debugViewFocusDocumentHasFocusOverride = true;
      try {
        // The null-relatedTarget focusout schedules the deferred report; the
        // immediate refocus, as WebKit does mid-drag, cancels it.
        input.blur();
        input.focusWithoutScroll();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(dispatchedViewFocusEvents, isEmpty);
      } finally {
        debugEmulateIosSafari = false;
        debugViewFocusDocumentHasFocusOverride = null;
      }
    });

    // A genuine blur (Done button, tap-away) never refocuses, so the deferred
    // report must still fire, carrying the right view and direction.
    test('reports the view unfocused on iOS when the editing input does not '
        'refocus', () async {
      final EngineFlutterView view = createAndRegisterView(dispatcher);
      final DomHTMLInputElement input = createDomHTMLInputElement();
      view.dom.rootElement.append(input);
      input.focusWithoutScroll();
      beginFakeTextEditing(input);
      dispatchedViewFocusEvents.clear();

      debugEmulateIosSafari = true;
      debugViewFocusDocumentHasFocusOverride = true;
      try {
        input.blur();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final Iterable<ui.ViewFocusEvent> unfocused = dispatchedViewFocusEvents.where(
          (ui.ViewFocusEvent e) => e.state == ui.ViewFocusState.unfocused,
        );
        expect(unfocused, hasLength(1));
        expect(unfocused.single.viewId, view.viewId);
        expect(unfocused.single.direction, ui.ViewFocusDirection.undefined);
      } finally {
        debugEmulateIosSafari = false;
        debugViewFocusDocumentHasFocusOverride = null;
      }
    });

    // The deferral is scoped to Flutter's text-editing element. A null-target
    // focusout from any other element must report immediately, so a later
    // refocus cannot erase a real focus loss.
    test('reports immediately for a non-text-editing element on iOS', () {
      final EngineFlutterView view = createAndRegisterView(dispatcher);
      final DomElement other = createDomElement('input');
      view.dom.rootElement.append(other);
      other.focusWithoutScroll();
      dispatchedViewFocusEvents.clear();

      debugEmulateIosSafari = true;
      // Report the document as focused so the only condition failing is that
      // `other` is not the active editing element. Without this the test could
      // pass because the headless browser reported the document unfocused,
      // which is a different branch than the one under test.
      debugViewFocusDocumentHasFocusOverride = true;
      try {
        other.blur();
        // Not deferred: the unfocused event is present synchronously.
        expect(
          dispatchedViewFocusEvents.where(
            (ui.ViewFocusEvent e) => e.state == ui.ViewFocusState.unfocused,
          ),
          hasLength(1),
        );
      } finally {
        debugEmulateIosSafari = false;
        debugViewFocusDocumentHasFocusOverride = null;
      }
    });

    // The deferral requires the document to still have focus. When focus has
    // left the document, such as a window, iframe, or app switch, the
    // null-target focusout from the editing element must report immediately so
    // the framework is not left believing the view is still focused.
    // Regression test for https://github.com/flutter/flutter/issues/189744
    test('reports immediately when the document is not focused on iOS', () {
      final EngineFlutterView view = createAndRegisterView(dispatcher);
      final DomHTMLInputElement input = createDomHTMLInputElement();
      view.dom.rootElement.append(input);
      input.focusWithoutScroll();
      beginFakeTextEditing(input);
      dispatchedViewFocusEvents.clear();

      debugEmulateIosSafari = true;
      debugViewFocusDocumentHasFocusOverride = false;
      try {
        input.blur();
        // Not deferred: with the document unfocused the unfocused event is
        // present synchronously.
        expect(
          dispatchedViewFocusEvents.where(
            (ui.ViewFocusEvent e) => e.state == ui.ViewFocusState.unfocused,
          ),
          hasLength(1),
        );
      } finally {
        debugEmulateIosSafari = false;
        debugViewFocusDocumentHasFocusOverride = null;
      }
    });

    // The deferral must key off the engine's editing state, not the
    // `flt-text-editing` class, which is not guaranteed to be applied by all
    // text editing strategies. An earlier revision matched on the class, which
    // left the deferral dead for strategies that do not apply it.
    // Regression test for https://github.com/flutter/flutter/issues/189744
    test('defers on iOS for an editing element with no flt-text-editing class', () async {
      final EngineFlutterView view = createAndRegisterView(dispatcher);
      final DomHTMLInputElement input = createDomHTMLInputElement();
      view.dom.rootElement.append(input);
      input.focusWithoutScroll();
      beginFakeTextEditing(input);
      expect(
        input.classList.contains(HybridTextEditing.textEditingClass),
        isFalse,
        reason: 'the semantics path never applies this class',
      );
      dispatchedViewFocusEvents.clear();

      debugEmulateIosSafari = true;
      debugViewFocusDocumentHasFocusOverride = true;
      try {
        input.blur();
        input.focusWithoutScroll();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(dispatchedViewFocusEvents, isEmpty);
      } finally {
        debugEmulateIosSafari = false;
        debugViewFocusDocumentHasFocusOverride = null;
      }
    });
  });
}

/// Makes [element] the engine's active text-editing element, which is what
/// [HybridTextEditing.isActiveTextEditingElement] reports to [ViewFocusBinding].
///
/// Sets the real singleton state rather than applying
/// [HybridTextEditing.textEditingClass], so these tests exercise the same signal
/// production code reads. The class is not guaranteed to be applied by all text
/// editing strategies, so keying tests off it would not reflect the production
/// code.
void beginFakeTextEditing(DomHTMLElement element) {
  textEditing.isEditing = true;
  textEditing.strategy.domElement = element;
}

void endFakeTextEditing() {
  textEditing.isEditing = false;
  textEditing.strategy.domElement = null;
}

EngineFlutterView createAndRegisterView(EnginePlatformDispatcher dispatcher) {
  final DomElement div = createDomElement('div');
  final view = EngineFlutterView(dispatcher, div);
  domDocument.body!.append(div);
  dispatcher.viewManager.registerView(view);
  return view;
}

extension on DomElement {
  void pressTabKey({bool shift = false}) {
    dispatchKeyboardEvent(type: 'keydown', key: 'Tab', shiftKey: shift);
  }

  void releaseTabKey() {
    dispatchKeyboardEvent(type: 'keyup', key: 'Tab');
  }

  void dispatchKeyboardEvent({required String type, required String key, bool shiftKey = false}) {
    dispatchEvent(createDomKeyboardEvent(type, <String, Object>{'key': key, 'shiftKey': shiftKey}));
  }
}

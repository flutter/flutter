// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUp(() async {
    await bootstrapAndRunApp(withImplicitView: true);
    domDocument.activeElement?.blur();
  });

  test('Moves the focus across input elements', () async {
    final List<DomEvent> focusinEvents = <DomEvent>[];
    final DomEventListener handleFocusIn = createDomEventListener((DomEvent event) {
      print('GOT FOCUS IN EVENT!!');
      focusinEvents.add(event);
    });
    final DomHTMLDivElement divElement = createDomHTMLDivElement();
    divElement.addEventListener('focusin', handleFocusIn);
    domDocument.body!.append(divElement);
    divElement.focusWithoutScroll();
    await waitForAnimationFrame();
    expect(focusinEvents, hasLength(1));
    expect(focusinEvents[0].target, divElement);
  });
}

Future<void> waitForAnimationFrame() {
  print('WAITING FOR ANIMATION FRAME!');
  print('CURRENT ZONE: ${Zone.current} (${Zone.current.hashCode})');
  final Completer<void> animationFrameFired = Completer<void>();
  domWindow.requestAnimationFrame((JSNumber _) {
    print('GOT ANIMATION FRAME!!');
    print('CURRENT ZONE: ${Zone.current} (${Zone.current.hashCode})');
    animationFrameFired.complete();
  });
  return animationFrameFired.future;
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Platform view type of the same-origin `<iframe srcdoc>` that counts clicks
/// and mouse moves.
const String iframeViewType = 'webdriver-pointer-actions-iframe';

/// Key of the Flutter button that counts clicks.
const Key buttonKey = Key('webdriver-click-button');

/// Key of the Flutter pan area that records pan gestures.
const Key panAreaKey = Key('webdriver-pan-area');

/// Key of the Flutter hover box that counts pointer enter and exit events.
const Key hoverKey = Key('webdriver-hover-box');

/// Number of clicks the Flutter button received.
final ValueNotifier<int> buttonClicks = ValueNotifier<int>(0);

/// Number of `click` events the iframe document received.
int iframeClicks = 0;

/// Number of `mousemove` events the iframe document received.
int iframeMouseMoves = 0;

/// Number of `onPanStart` callbacks the pan area received.
int panStarts = 0;

/// Global positions recorded by the pan area's `onPanUpdate`.
final List<Offset> panUpdates = <Offset>[];

/// Number of `onPanEnd` callbacks the pan area received.
int panEnds = 0;

/// Number of `onEnter` callbacks the hover box received.
int hoverEnters = 0;

/// Number of `onExit` callbacks the hover box received.
int hoverExits = 0;

/// Completes once the current iframe document has loaded and registered its
/// listeners.
Completer<void> iframeLoaded = Completer<void>();

bool _factoryRegistered = false;

void main() {
  // Each test calls main, so reset the counters and register the view factory
  // only once.
  buttonClicks.value = 0;
  iframeClicks = 0;
  iframeMouseMoves = 0;
  panStarts = 0;
  panUpdates.clear();
  panEnds = 0;
  hoverEnters = 0;
  hoverExits = 0;
  iframeLoaded = Completer<void>();
  if (!_factoryRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(iframeViewType, _createIframe);
    _factoryRegistered = true;
  }
  runApp(const WebDriverPointerActionsApp());
}

web.HTMLIFrameElement _createIframe(int viewId) {
  final iframe = web.HTMLIFrameElement()
    ..srcdoc = '<body style="margin:0;height:100vh;background:#cde"></body>'.toJS
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%';
  iframe.addEventListener(
    'load',
    (web.Event _) {
      final web.Document doc = iframe.contentDocument!;
      doc.addEventListener(
        'click',
        (web.Event _) {
          iframeClicks += 1;
        }.toJS,
      );
      doc.addEventListener(
        'mousemove',
        (web.Event _) {
          iframeMouseMoves += 1;
        }.toJS,
      );
      if (!iframeLoaded.isCompleted) {
        iframeLoaded.complete();
      }
    }.toJS,
  );
  return iframe;
}

/// Flutter controls (button, pan area, hover box) in a header above a
/// full-width iframe platform view.
class WebDriverPointerActionsApp extends StatelessWidget {
  const WebDriverPointerActionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ValueListenableBuilder<int>(
                    valueListenable: buttonClicks,
                    builder: (BuildContext context, int clicks, Widget? child) {
                      return TextButton(
                        key: buttonKey,
                        onPressed: () {
                          buttonClicks.value += 1;
                        },
                        child: Text('Button clicks: $clicks'),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    key: panAreaKey,
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (DragStartDetails _) {
                      panStarts += 1;
                    },
                    onPanUpdate: (DragUpdateDetails details) {
                      panUpdates.add(details.globalPosition);
                    },
                    onPanEnd: (DragEndDetails _) {
                      panEnds += 1;
                    },
                    child: const SizedBox(
                      width: 300,
                      height: 60,
                      child: ColoredBox(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  MouseRegion(
                    key: hoverKey,
                    onEnter: (_) {
                      hoverEnters += 1;
                    },
                    onExit: (_) {
                      hoverExits += 1;
                    },
                    child: const SizedBox(
                      width: 100,
                      height: 60,
                      child: ColoredBox(color: Color(0xFFB0D0E0)),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: HtmlElementView(viewType: iframeViewType)),
          ],
        ),
      ),
    );
  }
}

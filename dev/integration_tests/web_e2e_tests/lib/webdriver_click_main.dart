// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Platform view type of the same-origin `<iframe srcdoc>` that counts clicks.
const String iframeViewType = 'webdriver-click-iframe';

/// Key of the Flutter button that counts clicks.
const Key buttonKey = Key('webdriver-click-button');

/// Number of clicks the Flutter button received.
final ValueNotifier<int> buttonClicks = ValueNotifier<int>(0);

/// Number of `click` events the iframe document received.
int iframeClicks = 0;

/// Completes once the current iframe document has loaded and is counting
/// clicks.
Completer<void> iframeLoaded = Completer<void>();

bool _factoryRegistered = false;

void main() {
  // Each test calls main, so reset the counters and register the view factory
  // only once.
  buttonClicks.value = 0;
  iframeClicks = 0;
  iframeLoaded = Completer<void>();
  if (!_factoryRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(iframeViewType, _createIframe);
    _factoryRegistered = true;
  }
  runApp(const WebDriverClickApp());
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
      iframe.contentDocument!.addEventListener(
        'click',
        (web.Event _) {
          iframeClicks += 1;
        }.toJS,
      );
      if (!iframeLoaded.isCompleted) {
        iframeLoaded.complete();
      }
    }.toJS,
  );
  return iframe;
}

/// A button above a full-width iframe platform view, each counting clicks.
class WebDriverClickApp extends StatelessWidget {
  const WebDriverClickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 100,
              child: Align(
                alignment: Alignment.topLeft,
                child: ValueListenableBuilder<int>(
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
              ),
            ),
            const Expanded(child: HtmlElementView(viewType: iframeViewType)),
          ],
        ),
      ),
    );
  }
}

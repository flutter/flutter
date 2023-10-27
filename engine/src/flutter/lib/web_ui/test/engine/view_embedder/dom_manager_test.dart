// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  group('DomManager', () {
    test('fromFlutterViewEmbedderDEPRECATED', () {
      final FlutterViewEmbedder embedder = FlutterViewEmbedder();
      final DomManager domManager =
          DomManager.fromFlutterViewEmbedderDEPRECATED(embedder);

      expect(domManager.rootElement, embedder.flutterViewElementDEPRECATED);
      expect(domManager.renderingHost, embedder.glassPaneShadowDEPRECATED);
      expect(domManager.platformViewsHost, embedder.glassPaneElementDEPRECATED);
      expect(domManager.textEditingHost, embedder.textEditingHostNodeDEPRECATED);
      expect(domManager.semanticsHost, embedder.semanticsHostElementDEPRECATED);
    });
  });
}

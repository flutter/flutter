// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_stub.dart' if (dart.library.ffi) 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart';

class FakeAssetManager implements AssetManager {
  FakeAssetManager(this._parent);

  @override
  String get assetsDir => 'assets';

  @override
  String getAssetUrl(String asset) => asset;

  @override
  Future<ByteData> load(String assetKey) async {
    final ByteData? data = _assetMap[assetKey];
    if (data == null) {
      return _parent.load(assetKey);
    }
    return data;
  }

  @override
  Future<HttpFetchResponse> loadAsset(String asset) {
    return _parent.loadAsset(asset);
  }

  void setAsset(String assetKey, ByteData assetData) {
    _assetMap[assetKey] = assetData;
  }

  final Map<String, ByteData> _assetMap = <String, ByteData>{};
  final AssetManager _parent;
}

FakeAssetManager fakeAssetManager = FakeAssetManager(WebOnlyMockAssetManager());

/// Initializes the renderer for this test.
void setUpUiTest() {
  setUpAll(() async {
    debugEmulateFlutterTesterEnvironment = true;
    await initializeEngine(assetManager: fakeAssetManager);
    await renderer.fontCollection.debugDownloadTestFonts();
    renderer.fontCollection.registerDownloadedFonts();
  });
}

Picture drawPicture(void Function(Canvas) drawCommands) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  drawCommands(canvas);
  return recorder.endRecording();
}

/// Draws the [Picture]. This is in preparation for a golden test.
Future<void> drawPictureUsingCurrentRenderer(Picture picture) async {
  final SceneBuilder sb = SceneBuilder();
  sb.pushOffset(0, 0);
  sb.addPicture(Offset.zero, picture);
  await renderer.renderScene(sb.build());
  await awaitNextFrame();
}

Future<void> awaitNextFrame() {
  final Completer<void> completer = Completer<void>();
  domWindow.requestAnimationFrame((JSNumber time) => completer.complete());
  return completer.future;
}

/// Returns [true] if this test is running in the CanvasKit renderer.
bool get isCanvasKit => renderer is CanvasKitRenderer;

/// Returns [true] if this test is running in the HTML renderer.
bool get isHtml => renderer is HtmlRenderer;

bool get isSkwasm => renderer is SkwasmRenderer;

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmSurface {
  factory SkwasmSurface(String canvasQuerySelector) {
    final SurfaceHandle surfaceHandle = withStackScope((StackScope scope) {
      final Pointer<Int8> pointer = scope.convertStringToNative(canvasQuerySelector);
      return surfaceCreateFromCanvas(pointer);
    });
    final SkwasmSurface surface = SkwasmSurface._fromHandle(surfaceHandle);
    surface._initialize();
    return surface;
  }

  SkwasmSurface._fromHandle(this.handle) : threadId = surfaceGetThreadId(handle);
  final SurfaceHandle handle;
  OnRenderCallbackHandle _callbackHandle = nullptr;
  final Map<int, Completer<int>> _pendingCallbacks = <int, Completer<int>>{};

  final int threadId;

  int _currentObjectId = 0;
  int acquireObjectId() => ++_currentObjectId;

  void _initialize() {
    _callbackHandle =
      OnRenderCallbackHandle.fromAddress(
        skwasmInstance.addFunction(
          _callbackHandler.toJS,
          'vii'.toJS
        ).toDartDouble.toInt()
      );
    surfaceSetCallbackHandler(handle, _callbackHandle);
  }

  void setSize(int width, int height) =>
    surfaceSetCanvasSize(handle, width, height);

  Future<void> renderPicture(SkwasmPicture picture) {
    final int callbackId = surfaceRenderPicture(handle, picture.handle);
    return _registerCallback(callbackId);
  }

  Future<ByteData> rasterizeImage(SkwasmImage image, ui.ImageByteFormat format) async {
    final int callbackId = surfaceRasterizeImage(
      handle,
      image.handle,
      format.index,
    );
    final int context = await _registerCallback(callbackId);
    final SkDataHandle dataHandle = SkDataHandle.fromAddress(context);
    final int byteCount = skDataGetSize(dataHandle);
    final Pointer<Uint8> dataPointer = skDataGetConstPointer(dataHandle).cast<Uint8>();
    final Uint8List output = Uint8List(byteCount);
    for (int i = 0; i < byteCount; i++) {
      output[i] = dataPointer[i];
    }
    skDataDispose(dataHandle);
    return ByteData.sublistView(output);
  }

  Future<int> _registerCallback(int callbackId) {
    final Completer<int> completer = Completer<int>();
    _pendingCallbacks[callbackId] = completer;
    return completer.future;
  }

  void _callbackHandler(JSNumber jsCallbackId, JSNumber jsPointer) {
    final int callbackId = jsCallbackId.toDartDouble.toInt();
    final Completer<int> completer = _pendingCallbacks.remove(callbackId)!;
    completer.complete(jsPointer.toDartDouble.toInt());
  }

  void dispose() {
    surfaceDestroy(handle);
    skwasmInstance.removeFunction(_callbackHandle.address.toJS);
  }
}

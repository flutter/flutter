// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;



class SkwasmSurface {
  factory SkwasmSurface() {
    final SurfaceHandle surfaceHandle = withStackScope((StackScope scope) {
      return surfaceCreate();
    });
    final SkwasmSurface surface = SkwasmSurface._fromHandle(surfaceHandle);
    surface._initialize();
    return surface;
  }

  SkwasmSurface._fromHandle(this.handle) : threadId = surfaceGetThreadId(handle);
  final SurfaceHandle handle;
  OnRenderCallbackHandle _callbackHandle = nullptr;
  final Map<CallbackId, Completer<JSAny>> _pendingCallbacks = <int, Completer<JSAny>>{};

  final int threadId;

  void _initialize() {
    final WebAssemblyFunction wasmFunction = WebAssemblyFunction(
      WebAssemblyFunctionType(
        parameters: <JSString>[
          'i32'.toJS,
          'i32'.toJS,
          'externref'.toJS
        ].toJS,
        results: <JSString>[].toJS
      ),
      _callbackHandler.toJS,
    );
    _callbackHandle = OnRenderCallbackHandle.fromAddress(
      skwasmInstance.addFunction(wasmFunction).toDartInt,
    );
    surfaceSetCallbackHandler(handle, _callbackHandle);
  }

  Future<DomImageBitmap> renderPicture(SkwasmPicture picture) async {
    final int callbackId = surfaceRenderPicture(handle, picture.handle);
    final DomImageBitmap bitmap = (await _registerCallback(callbackId)) as DomImageBitmap;
    return bitmap;
  }

  Future<ByteData> rasterizeImage(SkwasmImage image, ui.ImageByteFormat format) async {
    final int callbackId = surfaceRasterizeImage(
      handle,
      image.handle,
      format.index,
    );
    final int context = (await _registerCallback(callbackId) as JSNumber).toDartInt;
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

  Future<JSAny> _registerCallback(int callbackId) {
    final Completer<JSAny> completer = Completer<JSAny>();
    _pendingCallbacks[callbackId] = completer;
    return completer.future;
  }

  void _callbackHandler(JSNumber callbackId, JSNumber context, JSAny jsContext) {
    final Completer<JSAny> completer = _pendingCallbacks.remove(callbackId.toDartInt)!;
    if (jsContext.isUndefinedOrNull) {
      completer.complete(context);
    } else {
      completer.complete(jsContext);
    }
  }

  void dispose() {
    surfaceDestroy(handle);
    skwasmInstance.removeFunction(_callbackHandle.address.toJS);
  }
}

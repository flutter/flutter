// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmPicture implements LayerPicture, StackTraceDebugger {
  SkwasmPicture.fromHandle(PictureHandle handle) {
    box = CountedRef<SkwasmPicture, PictureHandle>(
      handle,
      this,
      'Picture',
      onDispose: (PictureHandle h) => pictureDispose(h),
      onDisposed: (SkwasmPicture picture) => ui.Picture.onDispose?.call(picture),
    );
    _init();
    ui.Picture.onCreate?.call(this);
  }

  SkwasmPicture.cloneOf(this.box) {
    box.ref(this);
    _init();
  }

  void _init() {
    assert(() {
      _debugStackTrace = StackTrace.current;
      return true;
    }());
  }

  @override
  StackTrace get debugStackTrace => _debugStackTrace;
  late StackTrace _debugStackTrace;

  late final CountedRef<SkwasmPicture, PictureHandle> box;

  PictureHandle get handle => box.nativeObject;

  @override
  Future<ui.Image> toImage(int width, int height) async => toImageSync(width, height);

  @override
  int get approximateBytesUsed => pictureApproximateBytesUsed(handle);

  @override
  void dispose() {
    box.unref(this);
  }

  @override
  ui.Image toImageSync(
    int width,
    int height, {
    ui.TargetPixelFormat targetFormat = ui.TargetPixelFormat.dontCare,
  }) => SkwasmImage(imageCreateFromPicture(handle, width, height));

  @override
  ui.Rect get cullRect {
    return withStackScope((StackScope s) {
      final RawRect rect = s.allocFloatArray(4);
      pictureGetCullRect(handle, rect);
      return s.convertRectFromNative(rect);
    });
  }

  @override
  LayerPicture clone() => SkwasmPicture.cloneOf(box);

  @override
  String toString() {
    return 'SkwasmPicture(${handle.address})';
  }

  @override
  bool get isDisposed => box.isDisposed;

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = box.isDisposed;
      return true;
    }());
    return result ?? box.isDisposed;
  }
}

class SkwasmPictureRecorder extends SkwasmObjectWrapper<RawPictureRecorder>
    implements LayerPictureRecorder {
  SkwasmPictureRecorder()
    : super(pictureRecorderCreate(), (PictureRecorderHandle h) => pictureRecorderDispose(h));

  @override
  SkwasmPicture endRecording() {
    isRecording = false;

    final picture = SkwasmPicture.fromHandle(pictureRecorderEndRecording(handle));
    dispose();
    return picture;
  }

  @override
  bool isRecording = true;
}

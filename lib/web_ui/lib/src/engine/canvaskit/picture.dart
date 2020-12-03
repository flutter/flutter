// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

class CkPicture extends ManagedSkiaObject<SkPicture> implements ui.Picture {
  final ui.Rect? cullRect;
  final CkPictureSnapshot? _snapshot;

  CkPicture(SkPicture picture, this.cullRect, this._snapshot) : super(picture) {
    assert(
      browserSupportsFinalizationRegistry && _snapshot == null || _snapshot != null,
      'If the browser does not support FinalizationRegistry (WeakRef), then we must have a picture snapshot to be able to resurrect it.',
    );
  }

  @override
  int get approximateBytesUsed => 0;

  @override
  void dispose() {
    _snapshot?.dispose();
    skiaObject.delete();
  }

  @override
  Future<ui.Image> toImage(int width, int height) async {
    final SkSurface skSurface = canvasKit.MakeSurface(width, height);
    final SkCanvas skCanvas = skSurface.getCanvas();
    skCanvas.drawPicture(skiaObject);
    final SkImage skImage = skSurface.makeImageSnapshot();
    skSurface.dispose();
    return CkImage(skImage);
  }

  @override
  bool get isResurrectionExpensive => true;

  @override
  SkPicture createDefault() {
    // The default object is supplied in the constructor.
    throw StateError('Unreachable code');
  }

  @override
  SkPicture resurrect() {
    return _snapshot!.toPicture();
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}

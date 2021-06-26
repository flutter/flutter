// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'canvas.dart';
import 'canvaskit_api.dart';
import 'image.dart';
import 'skia_object_cache.dart';

/// Implements [ui.Picture] on top of [SkPicture].
///
/// Unlike most other [ManagedSkiaObject] implementations, instances of this
/// class may have their Skia counterparts deleted before finalization registry
/// or [SkiaObjectCache] decide to delete it.
class CkPicture extends ManagedSkiaObject<SkPicture> implements ui.Picture {
  final ui.Rect? cullRect;
  final CkPictureSnapshot? _snapshot;

  CkPicture(SkPicture picture, this.cullRect, this._snapshot) : super(picture) {
    assert(
      browserSupportsFinalizationRegistry && _snapshot == null ||
          _snapshot != null,
      'If the browser does not support FinalizationRegistry (WeakRef), then we must have a picture snapshot to be able to resurrect it.',
    );
  }

  @override
  int get approximateBytesUsed => 0;

  /// Whether the picture has been disposed of.
  ///
  /// This is indended to be used in tests and assertions only.
  bool get debugIsDisposed => _isDisposed;

  /// This is set to true when [dispose] is called and is never reset back to
  /// false.
  ///
  /// This extra flag is necessary on top of [rawSkiaObject] because
  /// [rawSkiaObject] being null does not indicate permanent deletion. See
  /// similar flag [SkiaObjectBox.isDeletedPermanently].
  bool _isDisposed = false;

  @override
  void dispose() {
    assert(!_isDisposed, 'Object has been disposed.');
    if (Instrumentation.enabled) {
      Instrumentation.instance.incrementCounter('Picture disposed');
    }
    _isDisposed = true;
    _snapshot?.dispose();

    // Emulate what SkiaObjectCache does.
    rawSkiaObject?.delete();
    rawSkiaObject = null;
  }

  @override
  Future<ui.Image> toImage(int width, int height) async {
    assert(!_isDisposed);
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
    // If a picture has been explicitly disposed of, it can no longer be
    // resurrected. An attempt to resurrect after the framework told the
    // engine to dispose of the picture likely indicates a bug in the engine.
    assert(!_isDisposed);
    return _snapshot!.toPicture();
  }

  @override
  void delete() {
    // This method may be called after [dispose], in which case there's nothing
    // left to do. The Skia object is deleted permanently.
    if (!_isDisposed) {
      rawSkiaObject?.delete();
    }
  }
}

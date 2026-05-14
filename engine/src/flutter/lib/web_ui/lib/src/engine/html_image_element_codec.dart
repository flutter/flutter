// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

/// The lifecycle status of an [HtmlImageElementCodec].
enum _HtmlCodecStatus {
  /// The codec has been created but has not yet started loading.
  initial,

  /// The codec is waiting for the browser to load the image metadata (width/height).
  loadingMetadata,

  /// The codec has loaded metadata and is now waiting for an available slot in
  /// the [ImageDecodingManager] to begin the heavy decoding process.
  waitingForSlot,

  /// The codec has been granted a slot and is currently executing the
  /// [HTMLImageElement.decode] operation.
  decoding,

  /// The image has been successfully loaded and decoded.
  success,

  /// An error occurred during the loading or decoding process.
  failed,

  /// The codec has been disposed and should no longer be used.
  disposed,
}

/// Exception thrown when a codec is disposed while it is still decoding.
class _HtmlCodecDisposedException implements Exception {
  const _HtmlCodecDisposedException();

  @override
  String toString() => 'HtmlCodec was disposed.';
}

abstract class HtmlImageElementCodec implements ui.Codec {
  HtmlImageElementCodec(this.src, {this.chunkCallback, this.debugSource});

  final String src;
  final ui_web.ImageCodecChunkCallback? chunkCallback;
  final String? debugSource;

  @override
  int get frameCount => 1;

  @override
  int get repetitionCount => 0;

  /// The Image() element backing this codec.
  DomHTMLImageElement? imgElement;

  /// A Future which completes when the Image element backing this codec has
  /// been loaded and decoded.
  Future<void>? decodeFuture;

  ImageDecodingRequest? _decodingRequest;
  _HtmlCodecStatus _status = _HtmlCodecStatus.initial;
  Completer<void>? _loadCompleter;

  /// Whether a [ui.Image] has been created and returned by [getNextFrame].
  ///
  /// This is used during [dispose] to determine if it is safe to clear the
  /// `src` attribute of [imgElement]. If the image has been handed out, the
  /// [ui.Image] might still be using the element for rendering, and clearing
  /// the `src` could disrupt the browser's internal image state.
  bool _imageHandedOut = false;

  Future<void> decode() {
    decodeFuture ??= _performDecode();
    return decodeFuture!;
  }

  void _checkDisposed() {
    if (_status == _HtmlCodecStatus.disposed) {
      throw const _HtmlCodecDisposedException();
    }
  }

  Future<void> _performDecode() async {
    try {
      _checkDisposed();
      await _waitForMetadata();
      await _executeThrottledDecode();

      _status = _HtmlCodecStatus.success;
      chunkCallback?.call(100, 100);
    } on _HtmlCodecDisposedException {
      _status = _HtmlCodecStatus.disposed;
    } on ImageDecodingCancelledException {
      _status = _HtmlCodecStatus.disposed;
    } catch (e) {
      _status = _HtmlCodecStatus.failed;
      if (!_imageHandedOut) {
        imgElement?.src = '';
      }
      rethrow;
    } finally {
      _cleanupDecodingSlot();
    }
  }

  Future<void> _waitForMetadata() async {
    _status = _HtmlCodecStatus.loadingMetadata;
    // Currently there is no way to watch decode progress, so
    // we add 0/100 , 100/100 progress callbacks to enable loading progress
    // builders to create UI.
    chunkCallback?.call(0, 100);

    imgElement = createDomHTMLImageElement();

    // The 'anonymous' cross-origin setting is required for CanvasKit-based
    // rendering. Without it, the browser would "taint" the image when it's
    // drawn to a canvas, preventing us from reading the pixels back or
    // converting it into a texture.
    imgElement!.crossOrigin = 'anonymous';

    // We set decoding to 'async' to hint to the browser that it should perform
    // image decompression off the main thread. This helps prevent jank
    // during the loading process.
    imgElement!.decoding = 'async';

    _loadCompleter = Completer<void>();

    // We use a local listener to ensure we can properly remove it in the
    // finally block. This prevents potential memory leaks or multiple
    // resolutions of the completer.
    final DomEventListener loadListener = createDomEventListener((DomEvent event) {
      _loadCompleter?.complete();
    });
    final DomEventListener errorListener = createDomEventListener((DomEvent event) {
      _loadCompleter?.completeError(ImageCodecException('Failed to load image: $src'));
    });

    imgElement!.addEventListener('load', loadListener);
    imgElement!.addEventListener('error', errorListener);

    // Setting the src attribute triggers the browser's image loading process.
    imgElement!.src = src;

    try {
      await _loadCompleter!.future;
    } finally {
      // It's critical to remove the listeners to avoid leaks, as the
      // HTMLImageElement might persist if it's cached by the browser or
      // referenced elsewhere.
      imgElement!.removeEventListener('load', loadListener);
      imgElement!.removeEventListener('error', errorListener);
      _loadCompleter = null;
    }
    _checkDisposed();
  }

  Future<void> _executeThrottledDecode() async {
    _status = _HtmlCodecStatus.waitingForSlot;
    final int width = imgElement!.naturalWidth.toInt();
    final int height = imgElement!.naturalHeight.toInt();

    _decodingRequest = ImageDecodingManager.instance.requestDecodingSlot(width, height);
    await _decodingRequest!.future;
    _checkDisposed();

    _status = _HtmlCodecStatus.decoding;
    // We use a timeout to prevent the decoder from hanging indefinitely and
    // blocking the queue.
    try {
      await imgElement!.decode().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw ImageCodecException('Timed out decoding image: $src');
    } catch (e) {
      throw ImageCodecException('Failed to decode image: $src. Error: $e');
    }
    _checkDisposed();
  }

  void _cleanupDecodingSlot() {
    if (_decodingRequest != null) {
      ImageDecodingManager.instance.releaseDecodingSlot(_decodingRequest!);
      _decodingRequest = null;
    }
  }

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    await decode();
    if (_status == _HtmlCodecStatus.disposed) {
      throw StateError('Codec has been disposed');
    }
    int naturalWidth = imgElement!.naturalWidth.toInt();
    int naturalHeight = imgElement!.naturalHeight.toInt();

    // Workaround for https://bugzilla.mozilla.org/show_bug.cgi?id=700533.
    //
    // In some versions of Firefox, certain image formats (like SVG or
    // very large JPEGs) may report a natural size of 0x0 even after the
    // 'load' event has fired if the browser hasn't fully computed the
    // intrinsic dimensions.
    //
    // Since Flutter requires a non-zero size to create a [ui.Image], we fall
    // back to a default size (300x300) to allow the image to be processed
    // and rendered, albeit potentially at a scaled size.
    if (naturalWidth == 0 &&
        naturalHeight == 0 &&
        ui_web.browser.browserEngine == ui_web.BrowserEngine.firefox) {
      const kDefaultImageSizeFallback = 300;
      naturalWidth = kDefaultImageSizeFallback;
      naturalHeight = kDefaultImageSizeFallback;
    }
    final ui.Image image = await createImageFromHTMLImageElement(
      imgElement!,
      naturalWidth,
      naturalHeight,
    );
    _imageHandedOut = true;
    return SingleFrameInfo(image);
  }

  /// Creates a [ui.Image] from an [HTMLImageElement] that has been loaded.
  FutureOr<ui.Image> createImageFromHTMLImageElement(
    DomHTMLImageElement image,
    int naturalWidth,
    int naturalHeight,
  );

  @override
  void dispose() {
    if (_status == _HtmlCodecStatus.disposed) {
      return;
    }
    final _HtmlCodecStatus oldStatus = _status;
    _status = _HtmlCodecStatus.disposed;

    if (oldStatus == _HtmlCodecStatus.loadingMetadata) {
      _loadCompleter?.completeError(const _HtmlCodecDisposedException());
    } else if (oldStatus == _HtmlCodecStatus.waitingForSlot) {
      if (_decodingRequest != null) {
        ImageDecodingManager.instance.cancel(_decodingRequest!);
      }
    }
    if (!_imageHandedOut) {
      imgElement?.src = '';
    }
  }
}

abstract class HtmlBlobCodec extends HtmlImageElementCodec {
  HtmlBlobCodec(this.blob, {super.chunkCallback})
    : super(domWindow.URL.createObjectURL(blob), debugSource: 'encoded image bytes');

  final DomBlob blob;

  @override
  void dispose() {
    super.dispose();
    domWindow.URL.revokeObjectURL(src);
  }
}

class SingleFrameInfo implements ui.FrameInfo {
  SingleFrameInfo(this.image);

  @override
  Duration get duration => Duration.zero;

  @override
  final ui.Image image;
}

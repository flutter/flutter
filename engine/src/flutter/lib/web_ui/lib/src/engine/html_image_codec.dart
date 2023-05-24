// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import 'browser_detection.dart';
import 'dom.dart';
import 'safe_browser_api.dart';

Object? get _jsImageDecodeFunction => getJsProperty<Object?>(
  getJsProperty<Object>(
    getJsProperty<Object>(domWindow, 'Image'),
    'prototype',
  ),
  'decode',
);
final bool _supportsDecode = _jsImageDecodeFunction != null;

typedef WebOnlyImageCodecChunkCallback = void Function(
    int cumulativeBytesLoaded, int expectedTotalBytes);

class HtmlCodec implements ui.Codec {
  HtmlCodec(this.src, {this.chunkCallback});

  final String src;
  final WebOnlyImageCodecChunkCallback? chunkCallback;

  @override
  int get frameCount => 1;

  @override
  int get repetitionCount => 0;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    final Completer<ui.FrameInfo> completer = Completer<ui.FrameInfo>();
    // Currently there is no way to watch decode progress, so
    // we add 0/100 , 100/100 progress callbacks to enable loading progress
    // builders to create UI.
      chunkCallback?.call(0, 100);
    if (_supportsDecode) {
      final DomHTMLImageElement imgElement = createDomHTMLImageElement();
      imgElement.src = src;
      setJsProperty<String>(imgElement, 'decoding', 'async');

      // Ignoring the returned future on purpose because we're communicating
      // through the `completer`.
      // ignore: unawaited_futures
      imgElement.decode().then((dynamic _) {
        chunkCallback?.call(100, 100);
        int naturalWidth = imgElement.naturalWidth.toInt();
        int naturalHeight = imgElement.naturalHeight.toInt();
        // Workaround for https://bugzilla.mozilla.org/show_bug.cgi?id=700533.
        if (naturalWidth == 0 && naturalHeight == 0 && browserEngine == BrowserEngine.firefox) {
          const int kDefaultImageSizeFallback = 300;
          naturalWidth = kDefaultImageSizeFallback;
          naturalHeight = kDefaultImageSizeFallback;
        }
        final HtmlImage image = HtmlImage(
          imgElement,
          naturalWidth,
          naturalHeight,
        );
        completer.complete(SingleFrameInfo(image));
      }).catchError((dynamic e) {
        // This code path is hit on Chrome 80.0.3987.16 when too many
        // images are on the page (~1000).
        // Fallback here is to load using onLoad instead.
        _decodeUsingOnLoad(completer);
      });
    } else {
      _decodeUsingOnLoad(completer);
    }
    return completer.future;
  }

  void _decodeUsingOnLoad(Completer<ui.FrameInfo> completer) {
    final DomHTMLImageElement imgElement = createDomHTMLImageElement();
    // If the browser doesn't support asynchronous decoding of an image,
    // then use the `onload` event to decide when it's ready to paint to the
    // DOM. Unfortunately, this will cause the image to be decoded synchronously
    // on the main thread, and may cause dropped framed.
    late DomEventListener errorListener;
    DomEventListener? loadListener;
    errorListener = createDomEventListener((DomEvent event) {
      if (loadListener != null) {
        imgElement.removeEventListener('load', loadListener);
      }
      imgElement.removeEventListener('error', errorListener);
      completer.completeError(event);
    });
    imgElement.addEventListener('error', errorListener);
    loadListener = createDomEventListener((DomEvent event) {
      if (chunkCallback != null) {
        chunkCallback!(100, 100);
      }
      imgElement.removeEventListener('load', loadListener);
      imgElement.removeEventListener('error', errorListener);
      final HtmlImage image = HtmlImage(
        imgElement,
        imgElement.naturalWidth.toInt(),
        imgElement.naturalHeight.toInt(),
      );
      completer.complete(SingleFrameInfo(image));
    });
    imgElement.addEventListener('load', loadListener);
    imgElement.src = src;
  }

  @override
  void dispose() {}
}

class HtmlBlobCodec extends HtmlCodec {
  HtmlBlobCodec(this.blob) : super(domWindow.URL.createObjectURL(blob));

  final DomBlob blob;

  @override
  void dispose() {
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

class HtmlImage implements ui.Image {
  HtmlImage(this.imgElement, this.width, this.height) {
    ui.Image.onCreate?.call(this);
  }

  final DomHTMLImageElement imgElement;
  bool _didClone = false;

  bool _disposed = false;
  @override
  void dispose() {
    ui.Image.onDispose?.call(this);
    // Do nothing. The codec that owns this image should take care of
    // releasing the object url.
    assert(() {
      _disposed = true;
      return true;
    }());
  }

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _disposed;
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw StateError('Image.debugDisposed is only available when asserts are enabled.');
  }


  @override
  ui.Image clone() => this;

  @override
  bool isCloneOf(ui.Image other) => other == this;

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => null;

  @override
  final int width;

  @override
  final int height;

  @override
  Future<ByteData?> toByteData({ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    switch (format) {
      // TODO(ColdPaleLight): https://github.com/flutter/flutter/issues/89128
      // The format rawRgba always returns straight rather than premul currently.
      case ui.ImageByteFormat.rawRgba:
      case ui.ImageByteFormat.rawStraightRgba:
        final DomCanvasElement canvas = createDomCanvasElement()
          ..width = width.toDouble()
          ..height = height.toDouble();
        final DomCanvasRenderingContext2D ctx = canvas.context2D;
        ctx.drawImage(imgElement, 0, 0);
        final DomImageData imageData = ctx.getImageData(0, 0, width, height);
        return Future<ByteData?>.value(imageData.data.buffer.asByteData());
      default:
        if (imgElement.src?.startsWith('data:') ?? false) {
          final UriData data = UriData.fromUri(Uri.parse(imgElement.src!));
          return Future<ByteData?>.value(data.contentAsBytes().buffer.asByteData());
        } else {
          return Future<ByteData?>.value();
        }
    }
  }

  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;

  DomHTMLImageElement cloneImageElement() {
    if (!_didClone) {
      _didClone = true;
      imgElement.style.position = 'absolute';
    }
    return imgElement.cloneNode(true) as DomHTMLImageElement;
  }

  @override
  String toString() => '[$width\u00D7$height]';
}

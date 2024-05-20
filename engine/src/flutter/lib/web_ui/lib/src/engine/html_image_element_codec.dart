// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

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

// TODO(mdebbar): Deprecate this and remove it.
// https://github.com/flutter/flutter/issues/127395
typedef WebOnlyImageCodecChunkCallback = ui_web.ImageCodecChunkCallback;

abstract class HtmlImageElementCodec implements ui.Codec {
  HtmlImageElementCodec(this.src, {this.chunkCallback});

  final String src;
  final ui_web.ImageCodecChunkCallback? chunkCallback;

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
        if (naturalWidth == 0 &&
            naturalHeight == 0 &&
            ui_web.browser.browserEngine == ui_web.BrowserEngine.firefox) {
          const int kDefaultImageSizeFallback = 300;
          naturalWidth = kDefaultImageSizeFallback;
          naturalHeight = kDefaultImageSizeFallback;
        }
        final ui.Image image = createImageFromHTMLImageElement(
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
      final ui.Image image = createImageFromHTMLImageElement(
        imgElement,
        imgElement.naturalWidth.toInt(),
        imgElement.naturalHeight.toInt(),
      );
      completer.complete(SingleFrameInfo(image));
    });
    imgElement.addEventListener('load', loadListener);
    imgElement.src = src;
  }

  /// Creates a [ui.Image] from an [HTMLImageElement] that has been loaded.
  ui.Image createImageFromHTMLImageElement(
    DomHTMLImageElement image,
    int naturalWidth,
    int naturalHeight,
  );

  @override
  void dispose() {}
}

abstract class HtmlBlobCodec extends HtmlImageElementCodec {
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

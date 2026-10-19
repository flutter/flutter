// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import '../web.dart' as web;
import 'image_stream.dart';

/// An [ImageInfo] object indicating that the image can only be displayed in
/// an HTML element, and no [dart:ui.Image] can be created for it.
///
/// This occurs on the web when the image resource is from a different origin
/// and is not configured for CORS. Since the image bytes cannot be directly
/// fetched, [Image]s cannot be created from it. However, the image can
/// still be displayed if an HTML element is used.
class WebImageInfo implements ImageInfo {
  /// Creates a new [WebImageInfo] from a given HTML element.
  WebImageInfo(web.HTMLImageElement htmlImage, {this.debugLabel})
    : _handle = _HtmlImageElementHandle(_HtmlImageElementRef(htmlImage));

  WebImageInfo._(this._handle, {this.debugLabel});

  final _HtmlImageElementHandle _handle;

  /// The HTML element used to display this image. This HTML element has already
  /// decoded the image, so size information can be retrieved from it.
  web.HTMLImageElement get htmlImage => _handle.htmlImage;

  @override
  final String? debugLabel;

  @override
  WebImageInfo clone() {
    return WebImageInfo._(_handle.clone(), debugLabel: debugLabel);
  }

  @override
  void dispose() {
    _handle.dispose();
  }

  @override
  Image get image => throw UnsupportedError(
    'Could not create image data for this image because access to it is '
    'restricted by the Same-Origin Policy.\n'
    'See https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy',
  );

  @override
  bool isCloneOf(ImageInfo other) {
    if (other is! WebImageInfo) {
      return false;
    }

    // It is a clone if it points to the same <img> element.
    return other.htmlImage == htmlImage && other.debugLabel == debugLabel;
  }

  @override
  double get scale => 1.0;

  @override
  int get sizeBytes => (4 * htmlImage.naturalWidth * htmlImage.naturalHeight).toInt();
}

class _HtmlImageElementHandle {
  _HtmlImageElementHandle(this._ref);

  final _HtmlImageElementRef _ref;
  bool _disposed = false;

  web.HTMLImageElement get htmlImage => _ref.htmlImage;

  _HtmlImageElementHandle clone() {
    assert(!_disposed, 'Cannot clone a disposed WebImageInfo.');
    _ref.retain();
    return _HtmlImageElementHandle(_ref);
  }

  void dispose() {
    assert(!_disposed, 'Cannot dispose a WebImageInfo that has already been disposed.');
    if (_disposed) {
      return;
    }
    _disposed = true;
    _ref.release();
  }
}

class _HtmlImageElementRef {
  _HtmlImageElementRef(this.htmlImage);

  final web.HTMLImageElement htmlImage;
  int _refCount = 1;

  void retain() {
    assert(_refCount > 0);
    _refCount++;
  }

  void release() {
    assert(_refCount > 0);
    _refCount--;
    if (_refCount == 0) {
      // Clear the src attribute of the image element to eagerly release the
      // decoded image buffer in the browser (especially WebKit on iOS).
      htmlImage.src = '';
    }
  }
}

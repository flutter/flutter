// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

final bool _supportsDecode =
    js_util.hasProperty(js.JsObject(js.context['Image']), 'decode');

class HtmlCodec implements ui.Codec {
  final String src;

  HtmlCodec(this.src);

  @override
  int get frameCount => 1;

  @override
  int get repetitionCount => 0;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    StreamSubscription<html.Event> loadSubscription;
    StreamSubscription<html.Event> errorSubscription;
    final Completer<ui.FrameInfo> completer = Completer<ui.FrameInfo>();
    final html.ImageElement imgElement = html.ImageElement();
    // If the browser doesn't support asynchronous decoding of an image,
    // then use the `onload` event to decide when it's ready to paint to the
    // DOM. Unfortunately, this will case the image to be decoded synchronously
    // on the main thread, and may cause dropped framed.
    if (!_supportsDecode) {
      loadSubscription = imgElement.onLoad.listen((html.Event event) {
        loadSubscription.cancel();
        errorSubscription.cancel();
        final HtmlImage image = HtmlImage(
          imgElement,
          imgElement.naturalWidth,
          imgElement.naturalHeight,
        );
        completer.complete(SingleFrameInfo(image));
      });
    }
    errorSubscription = imgElement.onError.listen((html.Event event) {
      loadSubscription?.cancel();
      errorSubscription.cancel();
      completer.completeError(event);
    });
    imgElement.src = src;
    // If the browser supports asynchronous image decoding, use that instead
    // of `onload`.
    if (_supportsDecode) {
      imgElement.decode().then((dynamic _) {
        errorSubscription.cancel();
        final HtmlImage image = HtmlImage(
          imgElement,
          imgElement.naturalWidth,
          imgElement.naturalHeight,
        );
        completer.complete(SingleFrameInfo(image));
      });
    }
    return completer.future;
  }

  @override
  void dispose() {}
}

class HtmlBlobCodec extends HtmlCodec {
  final html.Blob blob;

  HtmlBlobCodec(this.blob) : super(html.Url.createObjectUrlFromBlob(blob));

  @override
  void dispose() {
    html.Url.revokeObjectUrl(src);
  }
}

class SingleFrameInfo implements ui.FrameInfo {
  SingleFrameInfo(this.image);

  @override
  Duration get duration => const Duration(milliseconds: 0);

  @override
  final ui.Image image;
}

class HtmlImage implements ui.Image {
  final html.ImageElement imgElement;

  HtmlImage(this.imgElement, this.width, this.height);

  @override
  void dispose() {
    // Do nothing. The codec that owns this image should take care of
    // releasing the object url.
  }

  @override
  final int width;

  @override
  final int height;

  @override
  Future<ByteData> toByteData(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    return futurize((Callback<ByteData> callback) {
      return _toByteData(format.index, (Uint8List encoded) {
        callback(encoded?.buffer?.asByteData());
      });
    });
  }

  /// Returns an error message on failure, null on success.
  String _toByteData(int format, Callback<Uint8List> callback) => null;
}

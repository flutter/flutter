// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class HtmlCodec implements ui.Codec {
  final String src;

  HtmlCodec(this.src);

  @override
  int get frameCount => 1;

  @override
  int get repetitionCount => 0;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    StreamSubscription subscription;
    StreamSubscription errorSubscription;
    final completer = Completer<ui.FrameInfo>();
    final html.ImageElement imgElement = html.ImageElement();
    subscription = imgElement.onLoad.listen((_) {
      subscription.cancel();
      errorSubscription.cancel();
      final image = HtmlImage(
        imgElement,
        imgElement.naturalWidth,
        imgElement.naturalHeight,
      );
      completer.complete(SingleFrameInfo(image));
    });
    errorSubscription = imgElement.onError.listen((e) {
      subscription.cancel();
      errorSubscription.cancel();
      completer.completeError(e);
    });
    imgElement.src = src;
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

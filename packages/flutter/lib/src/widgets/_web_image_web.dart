// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import '../../rendering.dart';
import '../../widgets.dart';
import '../painting/_network_image_web.dart';
import '../web.dart' as web;

/// Returns [true] if the bytes at [url] can be fetched.
///
/// The bytes may be unable to be fetched if they aren't from the same origin
/// and the server hosting them does not allow cross-origin requests.
Future<bool> checkIfImageBytesCanBeFetched(String url) async {
  // First check if url is same origin.
  final Uri uri = Uri.parse(url);
  if (uri.origin == web.window.origin) {
    return true;
  }

  final Completer<web.XMLHttpRequest> completer =
      Completer<web.XMLHttpRequest>();
  final web.XMLHttpRequest request = httpRequestFactory();

  request.open('HEAD', url, true);

  request.addEventListener(
      'load',
      (web.Event e) {
        final int status = request.status;
        final bool accepted = status >= 200 && status < 300;
        final bool fileUri = status == 0; // file:// URIs have status of 0.
        final bool notModified = status == 304;
        final bool unknownRedirect = status > 307 && status < 400;
        final bool success =
            accepted || fileUri || notModified || unknownRedirect;

        if (success) {
          completer.complete(request);
        } else {
          completer.completeError(e);
        }
      }.toJS);

  request.addEventListener(
      'error', ((JSObject e) => completer.completeError(e)).toJS);

  request.send();

  return completer.future.then((_) {
    return true;
  }, onError: (_) {
    return false;
  });
}

/// Returns a widget which displays the [src] in an <img> tag.
Widget createImgElementWidget(String src,
        {Key? key,
        ImageLoadingBuilder? loadingBuilder,
        ImageFrameBuilder? frameBuilder,
        ImageErrorWidgetBuilder? errorBuilder}) =>
    _ImgElementImage(
      src,
      key: key,
      loadingBuilder: loadingBuilder,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
    );

class _ImgElementImage extends StatefulWidget {
  const _ImgElementImage(
    this.src, {
    super.key,
    this.loadingBuilder,
    this.frameBuilder,
    this.errorBuilder,
  });

  final String src;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageFrameBuilder? frameBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<StatefulWidget> createState() => _ImgElementImageState();
}

class _ImgElementImageState extends State<_ImgElementImage> {
  _ImgElementImageState() {
    if (_registeredViewType == null) {
      _register();
    }
  }

  // Keeps track if this widget has already registered its view factories.
  static String? _registeredViewType;

  late _CachedImageInfo _cachedImage;

  void _onCachedImageStateChange() {
    // Rebuild when the image state changes.
    setState(() {});
  }

  static const String _viewType = 'Browser__ImageElementType__';

  static void _register() {
    assert(_registeredViewType == null);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId,
        {Object? params}) {
      final Map<Object?, Object?> paramsMap = params! as Map<Object?, Object?>;
      final String src = paramsMap['src']! as String;
      return _WebImageCache._getOrCreateCachedImage(src).image.cloneNode(true);
    });
  }

  HtmlElementView? htmlElementView;

  num? naturalWidth;
  num? naturalHeight;

  int? imgElementId;

  @override
  void initState() {
    super.initState();
    _cachedImage =
        _WebImageCache._getOrCreateCachedImage(widget.src);
    _cachedImage.state.addListener(_onCachedImageStateChange);
  }

  @override
  void dispose() {
    super.dispose();
    _cachedImage.state.removeListener(_onCachedImageStateChange);
  }

  @override
  Widget build(BuildContext context) {
    final _CachedImageInfo info =
        _WebImageCache._getOrCreateCachedImage(widget.src);
    final double naturalWidth = info.image.naturalWidth.toDouble();
    final double naturalHeight = info.image.naturalHeight.toDouble();
    return ValueListenableBuilder<_ImageLoadingState>(
      valueListenable: info.state,
      builder: (BuildContext context, _ImageLoadingState state, Widget? child) {
        final Widget? builtWidget = switch (state) {
          _ImageLoadingState.loading =>
            widget.loadingBuilder?.call(context, child!, null),
          _ImageLoadingState.success =>
            widget.frameBuilder?.call(context, child!, 0, true),
          _ImageLoadingState.error =>
            widget.errorBuilder?.call(context, info.error, null) ?? Container(),
        };
        return builtWidget ?? child!;
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: naturalWidth,
          height: naturalHeight,
          child: _buildHtmlImage(),
        ),
      ),
    );
  }

  Widget _buildHtmlImage() {
    return HtmlElementView(
      viewType: _viewType,
      creationParams: <String, String>{'src': widget.src},
      hitTestBehavior: PlatformViewHitTestBehavior.transparent,
    );
  }
}

class _WebImageCache {
  static final Map<String, _CachedImageInfo> _imageCache =
      <String, _CachedImageInfo>{};

  static _CachedImageInfo _getOrCreateCachedImage(String url) {
    _CachedImageInfo? info = _imageCache[url];
    if (info == null) {
      info = _CachedImageInfo.fromUrl(url);
      _imageCache[url] = info;
    }
    return info;
  }
}

web.HTMLImageElement _createImage(String url) {
  final web.HTMLImageElement image =
      web.document.createElement('img') as web.HTMLImageElement;
  image.src = url;
  image.style
    ..width = '100%'
    ..height = '100%';
  return image;
}

enum _ImageLoadingState {
  loading,
  success,
  error,
}

class _CachedImageInfo {
  _CachedImageInfo.fromUrl(String url) : image = _createImage(url) {
    _startDecoding();
  }

  final web.HTMLImageElement image;

  ValueNotifier<_ImageLoadingState> state =
      ValueNotifier<_ImageLoadingState>(_ImageLoadingState.loading);

  late Object? _error;
  Object get error {
    assert(hasError);
    return _error!;
  }

  bool get isLoading => state.value == _ImageLoadingState.loading;
  bool get isSuccess => state.value == _ImageLoadingState.success;
  bool get hasError => state.value == _ImageLoadingState.error;

  Future<void> _startDecoding() async {
    try {
      await image.decode().toDart;
      state.value = _ImageLoadingState.success;
    } catch (e) {
      state.value = _ImageLoadingState.error;
      _error = e;
    }
  }
}

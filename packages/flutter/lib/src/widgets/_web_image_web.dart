// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import '../../rendering.dart';
import '../../widgets.dart';
import '../foundation/synchronous_future.dart';
import '../painting/_network_image_web.dart';
import '../web.dart' as web;

/// Returns [true] if the bytes at [url] can be fetched.
///
/// The bytes may be unable to be fetched if they aren't from the same origin
/// and the server hosting them does not allow cross-origin requests.
Future<bool> checkIfImageBytesCanBeFetched(String url) {
  // First check if url is same origin.
  final Uri uri = Uri.parse(url);
  if (uri.origin == web.window.origin) {
    return SynchronousFuture<bool>(true);
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
Widget createImgElementWidget(
  ImgElementProvider provider, {
  Key? key,
  ImageLoadingBuilder? loadingBuilder,
  ImageFrameBuilder? frameBuilder,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return _ImgElementImage(
    provider as _ImgElementProviderImpl,
    key: key,
    loadingBuilder: loadingBuilder,
    frameBuilder: frameBuilder,
    errorBuilder: errorBuilder,
  );
}

ImgElementProvider createImgElementProvider(String src) =>
    _ImgElementProviderCache._getOrCreateProvider(src);

Future<void> precacheImgElement(
  ImgElementProvider provider, {
  ImageErrorListener? onError,
}) {
  final _ImgElementProviderImpl providerImpl = provider as _ImgElementProviderImpl;
  if (providerImpl.state.value != _ImageLoadingState.loading) {
    if (providerImpl.state.value == _ImageLoadingState.error) {
      if (onError != null) {
        onError(providerImpl.error, providerImpl.stackTrace);
      } else {
        FlutterError.reportError(FlutterErrorDetails(
          context: ErrorDescription('img element failed to precache'),
          library: 'web image widget',
          exception: providerImpl.error,
          stack: providerImpl.stackTrace,
          silent: true,
        ));
      }
    }
    return Future<void>.value();
  } else {
    final Completer<void> completer = Completer<void>();
    void Function()? imgElementStateListener;
    imgElementStateListener = () {
      if (providerImpl.state.value == _ImageLoadingState.error) {
        if (onError != null) {
          onError(providerImpl.error, providerImpl.stackTrace);
        } else {
          FlutterError.reportError(FlutterErrorDetails(
            context: ErrorDescription('img element failed to precache'),
            library: 'web image widget',
            exception: providerImpl.error,
            stack: providerImpl.stackTrace,
            silent: true,
          ));
        }
      }
      provider.state.removeListener(imgElementStateListener!);
      completer.complete();
    };
    provider.state.addListener(imgElementStateListener);
    return completer.future;
  }
}

class _ImgElementImage extends StatefulWidget {
  const _ImgElementImage(
    this.provider, {
    super.key,
    this.loadingBuilder,
    this.frameBuilder,
    this.errorBuilder,
  });

  final _ImgElementProviderImpl provider;
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

  void _onCachedImageStateChange() {
    // Rebuild when the image state changes.
    if (mounted) {
      setState(() {});
    }
  }

  static const String _viewType = 'Flutter__ImgElementImage__';

  static void _register() {
    assert(_registeredViewType == null);
    _registeredViewType = _viewType;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId,
        {Object? params}) {
      final Map<Object?, Object?> paramsMap = params! as Map<Object?, Object?>;
      final String src = paramsMap['src']! as String;
      return _ImgElementProviderCache._getOrCreateProvider(src)
          .image
          .cloneNode(true);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.provider.state.value == _ImageLoadingState.loading) {
      widget.provider.state.addListener(_onCachedImageStateChange);
    }
  }

  @override
  void dispose() {
    widget.provider.state.removeListener(_onCachedImageStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double naturalWidth = widget.provider.image.naturalWidth.toDouble();
    final double naturalHeight = widget.provider.image.naturalHeight.toDouble();
    return ValueListenableBuilder<_ImageLoadingState>(
      valueListenable: widget.provider.state,
      builder: (BuildContext context, _ImageLoadingState state, Widget? child) {
        final Widget? builtWidget = switch (state) {
          _ImageLoadingState.loading =>
            widget.loadingBuilder?.call(context, child!, null),
          _ImageLoadingState.success =>
            widget.frameBuilder?.call(context, child!, 0, true),
          _ImageLoadingState.error =>
            widget.errorBuilder?.call(context, widget.provider.error, null) ??
                const SizedBox.shrink(),
        };
        return builtWidget ?? child!;
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: naturalWidth,
          height: naturalHeight,
          child: HtmlElementView(
            viewType: _ImgElementImageState._viewType,
            creationParams: <String, String>{'src': widget.provider.src},
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          ),
        ),
      ),
    );
  }
}

class _ImgElementProviderCache {
  static const int _maxImages = 1000;
  static const int _maxSizeInBytes = 100000000;
  static final Map<String, _ImgElementProviderImpl> _imageCache =
      <String, _ImgElementProviderImpl>{};
  static final Queue<String> _imageQueue = Queue<String>();

  static _ImgElementProviderImpl _getOrCreateProvider(String url) {
    _ImgElementProviderImpl? info = _imageCache[url];
    if (info == null) {
      info = _ImgElementProviderImpl(url);
      void Function()? imgLoadListener;
      imgLoadListener = () {
        // The image loaded, so we need to clean up the cache now that we know
        // its size.
        _cleanupCache();
        info!.state.removeListener(imgLoadListener!);
      };
      info.state.addListener(imgLoadListener);
      _imageCache[url] = info;
    }
    _touch(url);
    return info;
  }

  static void _touch(String url) {
    _imageQueue.remove(url);
    _imageQueue.addFirst(url);
  }

  /// Remove the least recently used items from the cache until the number of
  /// items in the cache is less than [_maxImages] and the total bytes of the
  /// images in the cache is less than [_maxSizeInBytes].
  static void _cleanupCache() {
    assert(_imageQueue.length == _imageCache.length);
    if (_imageQueue.length > _maxImages) {
      final int imagesToRemove = _imageQueue.length - _maxImages;
      for (int i = 0; i < imagesToRemove; i++) {
        final String url = _imageQueue.removeLast();
        final _ImgElementProviderImpl? info = _imageCache.remove(url);
        if (info != null) {
          if (info.state.value == _ImageLoadingState.loading) {
            info.state.dispose();
          }
        }
      }
    }

    double totalSize = 0;
    for (final String url in _imageQueue) {
      final _ImgElementProviderImpl? info = _imageCache[url];
      totalSize += info!.estimatedSize;
    }
    while (totalSize > _maxSizeInBytes) {
      final String url = _imageQueue.removeLast();
      final _ImgElementProviderImpl? info = _imageCache.remove(url);
      if (info != null) {
        if (info.state.value == _ImageLoadingState.loading) {
          info.state.dispose();
        }
        totalSize -= info.estimatedSize;
      }
    }
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

class _ImgElementProviderImpl extends ImgElementProvider {
  _ImgElementProviderImpl(this.src) : image = _createImage(src) {
    _startDecoding();
  }

  final String src;
  final web.HTMLImageElement image;

  ValueNotifier<_ImageLoadingState> state =
      ValueNotifier<_ImageLoadingState>(_ImageLoadingState.loading);

  late Object? _error;
  Object get error {
    assert(state.value == _ImageLoadingState.error);
    return _error!;
  }

  late StackTrace? _stackTrace;
  StackTrace get stackTrace {
    assert(state.value == _ImageLoadingState.error);
    return _stackTrace!;
  }

  Future<void> _startDecoding() async {
    try {
      await image.decode().toDart;
      state.value = _ImageLoadingState.success;
    } catch (e, stackTrace) {
      state.value = _ImageLoadingState.error;
      _error = e;
      _stackTrace = stackTrace;
    }
    state.dispose();
  }

  double get estimatedSize => image.naturalWidth * image.naturalHeight * 4;
}

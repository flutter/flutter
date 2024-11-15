// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import '../../foundation.dart';
import '../../rendering.dart';
import '../../scheduler.dart';
import '../../widgets.dart';
import '../painting/_network_image_web.dart' as network_image_web;
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
  final web.XMLHttpRequest request = network_image_web.httpRequestFactory();

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

/// The underlying State widget for [WebImage].
class WebImageState extends State<WebImage> with WidgetsBindingObserver {
  WebImageStream? _imageStream;
  WebImageInfo? _imageInfo;
  bool _imageCanBeFetched = false;
  bool _isListeningToStream = false;
  int? _frameNumber;
  bool _wasSynchronouslyLoaded = false;
  Object? _lastException;
  StackTrace? _lastStack;
  WebImageStreamCompleterHandle? _completerHandle;
  // TODO(harryterkelsen): Add ScrollAware loading?

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    assert(_imageStream != null);
    WidgetsBinding.instance.removeObserver(this);
    _stopListeningToStream();
    _completerHandle?.dispose();
    _imageInfo = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();

    if (TickerMode.of(context)) {
      _listenToStream();
    } else {
      _stopListeningToStream(keepStreamAlive: true);
    }

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(WebImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isListeningToStream &&
        (widget.loadingBuilder == null) != (oldWidget.loadingBuilder == null)) {
      final WebImageStreamListener oldListener = _getListener();
      _imageStream!.addListener(_getListener(recreateListener: true));
      _imageStream!.removeListener(oldListener);
    }
    if (widget.image != oldWidget.image) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final WebImageStream newStream =
        (widget.image as WebImageProviderImpl).resolve();
    _updateSourceStream(newStream);
  }

  void _updateSourceStream(WebImageStream newStream) {
    if (_imageStream?.key == newStream.key) {
      return;
    }

    if (_isListeningToStream) {
      _imageStream!.removeListener(_getListener());
    }

    if (!widget.gaplessPlayback) {
      setState(() { _imageInfo = null; });
    }

    setState(() {
      _frameNumber = null;
      _wasSynchronouslyLoaded = false;
    });

    _imageStream = newStream;
    if (_isListeningToStream) {
      _imageStream!.addListener(_getListener());
    }
  }

  WebImageStreamListener? _imageStreamListener;
  WebImageStreamListener _getListener({bool recreateListener = false}) {
    if (_imageStreamListener == null || recreateListener) {
      _lastException = null;
      _lastStack = null;
      _imageStreamListener = WebImageStreamListener(
        _handleImageFrame,
        _handleImageCanBeLoaded,
        onError: widget.errorBuilder != null || kDebugMode
            ? (Object error, StackTrace? stackTrace) {
                setState(() {
                  _lastException = error;
                  _lastStack = stackTrace;
                });
                assert(() {
                  if (widget.errorBuilder == null) {
                    // ignore: only_throw_errors, since we're just proxying the error.
                    throw error; // Ensures the error message is printed to the console.
                  }
                  return true;
                }());
              }
            : null,
      );
    }
    return _imageStreamListener!;
  }

  void _handleImageFrame(WebImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageInfo = imageInfo;
      _lastException = null;
      _lastStack = null;
      _frameNumber = _frameNumber == null ? 0 : _frameNumber! + 1;
      _imageCanBeFetched = false;
      _wasSynchronouslyLoaded = _wasSynchronouslyLoaded | synchronousCall;
    });
  }

  void _handleImageCanBeLoaded(bool synchronousCall) {
    setState(() {
      _imageInfo = null;
      _lastException = null;
      _lastStack = null;
      _frameNumber = null;
      _imageCanBeFetched = true;
      _wasSynchronouslyLoaded = _wasSynchronouslyLoaded | synchronousCall;
    });
  }

  void _listenToStream() {
    if (_isListeningToStream) {
      return;
    }

    _imageStream!.addListener(_getListener());
    _completerHandle?.dispose();
    _completerHandle = null;

    _isListeningToStream = true;
  }

  /// Stops listening to the image stream, if this state object has attached a
  /// listener.
  ///
  /// If the listener from this state is the last listener on the stream, the
  /// stream will be disposed. To keep the stream alive, set `keepStreamAlive`
  /// to true, which create [ImageStreamCompleterHandle] to keep the completer
  /// alive and is compatible with the [TickerMode] being off.
  void _stopListeningToStream({bool keepStreamAlive = false}) {
    if (!_isListeningToStream) {
      return;
    }

    if (keepStreamAlive &&
        _completerHandle == null &&
        _imageStream?.completer != null) {
      _completerHandle = _imageStream!.completer!.keepAlive();
    }

    _imageStream!.removeListener(_getListener());
    _isListeningToStream = false;
  }

  Widget _debugBuildErrorWidget(BuildContext context, Object error) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        const Positioned.fill(
          child: Placeholder(
            color: Color(0xCF8D021F),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: FittedBox(
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                shadows: <Shadow>[
                  Shadow(blurRadius: 1.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lastException != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _lastException!, _lastStack);
      }
      if (kDebugMode) {
        return _debugBuildErrorWidget(context, _lastException!);
      }
    }

    if (_imageCanBeFetched) {
      return Image.network(
        widget.image.src,
        frameBuilder: widget.frameBuilder,
        loadingBuilder: widget.loadingBuilder,
        errorBuilder: widget.errorBuilder,
        semanticLabel: widget.semanticLabel,
        excludeFromSemantics: widget.excludeFromSemantics,
        width: widget.width,
        height: widget.height,
      );
    }

    Widget result = RawWebImage(
      image: _imageInfo?.image,
      debugImageLabel: _imageInfo?.debugLabel,
      width: widget.width,
      height: widget.height,
    );

    if (!widget.excludeFromSemantics) {
      result = Semantics(
        container: widget.semanticLabel != null,
        image: true,
        label: widget.semanticLabel ?? '',
        child: result,
      );
    }

    if (widget.frameBuilder != null) {
      result = widget.frameBuilder!(
          context, result, _frameNumber, _wasSynchronouslyLoaded);
    }

    if (widget.loadingBuilder != null) {
      result = widget.loadingBuilder!(context, result, null);
    }

    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<WebImageStream>('stream', _imageStream));
    properties.add(DiagnosticsProperty<WebImageInfo>('<img>', _imageInfo));
    properties.add(DiagnosticsProperty<bool>('wasSynchronouslyLoaded', _wasSynchronouslyLoaded));
  }
}

/// Displays an `<img>` element with `src` set to [src].
class ImgElementPlatformView extends StatelessWidget {
  /// Creates a platform view backed with an `<img>` element.
  ImgElementPlatformView(this.src, {super.key}) {
    if (!_registered) {
      _register();
    }
  }

  static const String _viewType = 'Flutter__ImgElementImage__';
  static bool _registered = false;

  static void _register() {
    assert(!_registered);
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId,
        {Object? params}) {
      final Map<Object?, Object?> paramsMap = params! as Map<Object?, Object?>;
      final web.HTMLImageElement img =
          webImageCache.getLoadedImage(paramsMap['key']! as String)!.image;
      return img;
    });
  }

  /// The `src` url for the `<img>` tag.
  final String? src;

  @override
  Widget build(BuildContext context) {
    if (src == null) {
      return const SizedBox.expand();
    }
    return HtmlElementView(
      viewType: _viewType,
      creationParams: <String, String?>{'key': src},
    );
  }
}

/// A widget which displays and lays out an underlying `<img>` platform view.
class RawWebImage extends SingleChildRenderObjectWidget {
  /// Creates a [RawWebImage].
  RawWebImage({
    super.key,
    required this.image,
    this.debugImageLabel,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
  }) : super(child: ImgElementPlatformView(image?.src));

  /// The underlying `<img>` tag to be displayed.
  final web.HTMLImageElement? image;

  /// A debug label explaining the image.
  final String? debugImageLabel;

  /// The requested width for this widget.
  final double? width;

  /// The requested height for this widget.
  final double? height;

  /// How the `<img>` should be inscribed in the box constraining it.
  final BoxFit? fit;

  /// How the image should be aligned in the box constraining it.
  final AlignmentGeometry alignment;

  /// Whether or not the alignment of the image should match the text direction.
  final bool matchTextDirection;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderWebImage(
      image: image,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      matchTextDirection: matchTextDirection,
      textDirection: matchTextDirection || alignment is! Alignment
          ? Directionality.of(context)
          : null,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderWebImage renderObject) {
    renderObject
      ..image = image
      ..width = width
      ..height = height
      ..fit = fit
      ..alignment = alignment
      ..matchTextDirection = matchTextDirection
      ..textDirection = matchTextDirection || alignment is! Alignment
          ? Directionality.of(context)
          : null;
  }
}

/// Lays out and positions the child `<img>` element similarly to [RenderImage].
class RenderWebImage extends RenderShiftedBox {
  /// Creates a new [RenderWebImage].
  RenderWebImage({
    RenderBox? child,
    required web.HTMLImageElement? image,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    bool matchTextDirection = false,
    TextDirection? textDirection,
  })  : _image = image,
        _width = width,
        _height = height,
        _fit = fit,
        _alignment = alignment,
        _matchTextDirection = matchTextDirection,
        _textDirection = textDirection,
        super(child);

  Alignment? _resolvedAlignment;
  bool? _flipHorizontally;

  void _resolve() {
    if (_resolvedAlignment != null) {
      return;
    }
    _resolvedAlignment = alignment.resolve(textDirection);
    _flipHorizontally =
        matchTextDirection && textDirection == TextDirection.rtl;
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    _flipHorizontally = null;
    markNeedsPaint();
  }

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is set to true, [textDirection] must not be null.
  bool get matchTextDirection => _matchTextDirection;
  bool _matchTextDirection;
  set matchTextDirection(bool value) {
    if (value == _matchTextDirection) {
      return;
    }
    _matchTextDirection = value;
    _markNeedResolution();
  }

  /// The text direction with which to resolve [alignment].
  ///
  /// This may be changed to null, but only after the [alignment] and
  /// [matchTextDirection] properties have been changed to values that do not
  /// depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  /// The image to display.
  web.HTMLImageElement? get image => _image;
  web.HTMLImageElement? _image;
  set image(web.HTMLImageElement? value) {
    if (value == _image) {
      return;
    }
    // If we get a clone of our image, it's the same underlying native data -
    // return early.
    if (value != null && _image != null && value.src == _image!.src) {
      return;
    }
    final bool sizeChanged = _image?.naturalWidth != value?.naturalWidth ||
        _image?.naturalHeight != value?.naturalHeight;
    _image = value;
    markNeedsPaint();
    if (sizeChanged && (_width == null || _height == null)) {
      markNeedsLayout();
    }
  }

  /// If non-null, requires the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double? get width => _width;
  double? _width;
  set width(double? value) {
    if (value == _width) {
      return;
    }
    _width = value;
    markNeedsLayout();
  }

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double? get height => _height;
  double? _height;
  set height(double? value) {
    if (value == _height) {
      return;
    }
    _height = value;
    markNeedsLayout();
  }

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  BoxFit? get fit => _fit;
  BoxFit? _fit;
  set fit(BoxFit? value) {
    if (value == _fit) {
      return;
    }
    _fit = value;
    markNeedsPaint();
  }

  /// How to align the image within its bounds.
  ///
  /// If this is set to a text-direction-dependent value, [textDirection] must
  /// not be null.
  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (value == _alignment) {
      return;
    }
    _alignment = value;
    _markNeedResolution();
  }

  /// Find a size for the render image within the given constraints.
  ///
  ///  - The dimensions of the RenderImage must fit within the constraints.
  ///  - The aspect ratio of the RenderImage matches the intrinsic aspect
  ///    ratio of the image.
  ///  - The RenderImage's dimension are maximal subject to being smaller than
  ///    the intrinsic size of the image.
  Size _sizeForConstraints(BoxConstraints constraints) {
    // Folds the given |width| and |height| into |constraints| so they can all
    // be treated uniformly.
    constraints = BoxConstraints.tightFor(
      width: _width,
      height: _height,
    ).enforce(constraints);

    if (_image == null) {
      return constraints.smallest;
    }

    return constraints.constrainSizeAndAttemptToPreserveAspectRatio(Size(
      _image!.naturalWidth.toDouble(),
      _image!.naturalHeight.toDouble(),
    ));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(height >= 0.0);
    if (_width == null && _height == null) {
      return 0.0;
    }
    return _sizeForConstraints(BoxConstraints.tightForFinite(height: height))
        .width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(height >= 0.0);
    return _sizeForConstraints(BoxConstraints.tightForFinite(height: height))
        .width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(width >= 0.0);
    if (_width == null && _height == null) {
      return 0.0;
    }
    return _sizeForConstraints(BoxConstraints.tightForFinite(width: width))
        .height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(width >= 0.0);
    return _sizeForConstraints(BoxConstraints.tightForFinite(width: width))
        .height;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return _sizeForConstraints(constraints);
  }

  @override
  void performLayout() {
    _resolve();
    assert(_resolvedAlignment != null);
    assert(_flipHorizontally != null);
    size = _sizeForConstraints(constraints);
    if (child != null) {
      if (image != null) {
        final Size inputSize =
            Size(image!.naturalWidth.toDouble(), image!.naturalHeight.toDouble());
        fit ??= BoxFit.scaleDown;
        final FittedSizes fittedSizes = applyBoxFit(fit!, inputSize, size);
        final Size childSize = fittedSizes.destination;
        child!.layout(BoxConstraints.tight(childSize));
        final double halfWidthDelta = (size.width - childSize.width) / 2.0;
        final double halfHeightDelta = (size.height - childSize.height) / 2.0;
        final double dx = halfWidthDelta +
            (_flipHorizontally!
                    ? -_resolvedAlignment!.x
                    : _resolvedAlignment!.x) *
                halfWidthDelta;
        final double dy =
            halfHeightDelta + _resolvedAlignment!.y * halfHeightDelta;
        final BoxParentData childParentData = child!.parentData! as BoxParentData;
        childParentData.offset = Offset(dx, dy);
      } else {
        child!.layout(BoxConstraints.tight(size));
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<web.HTMLImageElement>('image', image));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: null));
  }
}

/// Signature for the callback taken by [WebImageProvider._createErrorHandlerAndKey].
typedef _KeyAndErrorHandlerCallback = void Function(
    String key, ImageErrorListener handleError);

/// Signature used for error handling by [WebImageProvider._createErrorHandlerAndKey].
typedef _AsyncKeyErrorHandler = Future<void> Function(
    String key, Object exception, StackTrace? stack);

/// A key for loading the web image resource located at the URL [src].
class WebImageProviderImpl implements WebImageProvider {
  /// Creates a new web image resource located at [src].
  WebImageProviderImpl(this.src);

  /// The URL of the web image resource.
  @override
  final String src;

  /// Creates a [WebImageStream], and begins to load the image resource.
  ///
  /// The stream is automatically cached with the [WebImageCache].
  WebImageStream resolve() {
    final WebImageStream stream = WebImageStream();
    // Set up an error handling zone and call resolveStreamForKey.
    _createErrorHandler(
      (String key, ImageErrorListener errorHandler) {
        resolveStreamForKey(stream, key, errorHandler);
      },
      (String key, Object exception, StackTrace? stack) async {
        await null; // wait an event turn in case a listener has been added to the image stream.
        InformationCollector? collector;
        assert(() {
          collector = () => <DiagnosticsNode>[
                DiagnosticsProperty<WebImageProvider>('Image provider', this),
                DiagnosticsProperty<String>('Image key', key,
                    defaultValue: null),
              ];
          return true;
        }());
        if (stream.completer == null) {
          stream.setCompleter(_ErrorImageCompleter());
        }
        stream.completer!.reportError(
          exception: exception,
          stack: stack,
          context: ErrorDescription('while resolving an image'),
          silent: true, // could be a network error or whatnot
          informationCollector: collector,
        );
      },
    );
    return stream;
  }

  /// Returns the cache location for the key that this [ImageProvider] creates.
  ///
  /// The location may be [ImageCacheStatus.untracked], indicating that this
  /// image provider's key is not available in the [ImageCache].
  ///
  /// If the `handleError` parameter is null, errors will be reported to
  /// [FlutterError.onError], and the method will return null.
  ///
  /// A completed return value of null indicates that an error has occurred.
  Future<WebImageCacheStatus?> obtainCacheStatus({
    ImageErrorListener? handleError,
  }) {
    final Completer<WebImageCacheStatus?> completer = Completer<WebImageCacheStatus?>();
    _createErrorHandler(
      (String key, ImageErrorListener innerHandleError) {
        completer.complete(webImageCache.statusForKey(key));
      },
      (String? key, Object exception, StackTrace? stack) async {
        if (handleError != null) {
          handleError(exception, stack);
        } else {
          InformationCollector? collector;
          assert(() {
            collector = () => <DiagnosticsNode>[
              DiagnosticsProperty<WebImageProvider>('Image provider', this),
              DiagnosticsProperty<String>('Image src', key, defaultValue: null),
            ];
            return true;
          }());
          FlutterError.reportError(FlutterErrorDetails(
            context: ErrorDescription('while checking the cache location of an image'),
            informationCollector: collector,
            exception: exception,
            stack: stack,
          ));
          completer.complete();
        }
      },
    );
    return completer.future;
  }

  /// This method is used by both [resolve] and [obtainCacheStatus] to ensure
  /// that errors thrown during key creation are handled whether synchronous or
  /// asynchronous.
  void _createErrorHandler(
    _KeyAndErrorHandlerCallback successCallback,
    _AsyncKeyErrorHandler errorCallback,
  ) {
    bool didError = false;
    Future<void> handleError(Object exception, StackTrace? stack) async {
      if (didError) {
        return;
      }
      if (!didError) {
        didError = true;
        errorCallback(src, exception, stack);
      }
    }

    try {
      successCallback(src, handleError);
    } catch (error, stackTrace) {
      handleError(error, stackTrace);
    }
  }

  /// Called by [resolve] with the key as [src].
  ///
  /// The implementation uses the key to interact with the [WebImageCache],
  /// calling [WebImageCache.putIfAbsent] and notifying listeners of the
  /// [stream].
  @protected
  void resolveStreamForKey(
      WebImageStream stream, String key, ImageErrorListener handleError) {
    // This is an unusual edge case where someone has told us that they found
    // the image we want before getting to this method. We should avoid calling
    // load again, but still update the image cache with LRU information.
    if (stream.completer != null) {
      final WebImageStreamCompleter? completer = webImageCache.putIfAbsent(
        key,
        () => stream.completer!,
        onError: handleError,
      );
      assert(identical(completer, stream.completer));
      return;
    }
    final WebImageStreamCompleter? completer = webImageCache.putIfAbsent(
      key,
      () => loadImage(key),
      onError: handleError,
    );
    if (completer != null) {
      stream.setCompleter(completer);
    }
  }

  /// Creates a completer which completes if either (1) the image bytes can be
  /// fetched normally or (2) an <img> tag has decoded the image.
  WebImageStreamCompleter loadImage(String key) {
    return OneFrameWebImageStreamCompleter(
      checkIfImageBytesCanBeFetched(key),
      _decodeImageTag(),
    );
  }

  Future<WebImageInfo> _decodeImageTag() async {
    final web.HTMLImageElement img =
        web.document.createElement('img') as web.HTMLImageElement;
    img.src = src;
    img.style
      ..width = '100%'
      ..height = '100%';
    await img.decode().toDart;
    return WebImageInfo(img);
  }
}

/// A stream which can be listened to to determine if the underlying web image
/// resource can (1) be fetched directly, (2) has been decoded in an <img> tag,
/// or (3) there has been an error decoding the image.
class WebImageStream with Diagnosticable {
  /// Create an initially unbound image stream.
  ///
  /// Once a [WebImageStreamCompleter] is available, call [setCompleter].
  WebImageStream();

  /// The completer that has been assigned to this image stream.
  ///
  /// Generally there is no need to deal with the completer directly.
  WebImageStreamCompleter? get completer => _completer;
  WebImageStreamCompleter? _completer;

  List<WebImageStreamListener>? _listeners;

  /// Assigns a particular [WebImageStreamCompleter] to this [WebImageStream].
  ///
  /// This is usually done automatically by the [WebImageProvider] that created
  /// the [WebImageStream].
  ///
  /// This method can only be called once per stream. To have a [WebImageStream]
  /// represent multiple images over time, assign it a completer that
  /// completes several images in succession.
  void setCompleter(WebImageStreamCompleter value) {
    assert(_completer == null);
    _completer = value;
    if (_listeners != null) {
      final List<WebImageStreamListener> initialListeners = _listeners!;
      _listeners = null;
      _completer!._addingInitialListeners = true;
      initialListeners.forEach(_completer!.addListener);
      _completer!._addingInitialListeners = false;
    }
  }

  /// Adds a listener callback that is called whenever either it is determined
  /// that the image bytes can be fetched directly or a new concrete
  /// [WebImageInfo] object is available. If it has already been determined that
  /// the bytes can be fetched or a concrete image is already available, this
  /// object will call the listener synchronously.
  ///
  /// If the assigned [completer] completes multiple images over its lifetime,
  /// this listener will fire multiple times.
  void addListener(WebImageStreamListener listener) {
    if (_completer != null) {
      return _completer!.addListener(listener);
    }
    _listeners ??= <WebImageStreamListener>[];
    _listeners!.add(listener);
  }

  /// Stops listening for events from this stream's [WebImageStreamCompleter].
  ///
  /// If [listener] has been added multiple times, this removes the _first_
  /// instance of the listener.
  void removeListener(WebImageStreamListener listener) {
    if (_completer != null) {
      return _completer!.removeListener(listener);
    }
    assert(_listeners != null);
    for (int i = 0; i < _listeners!.length; i += 1) {
      if (_listeners![i] == listener) {
        _listeners!.removeAt(i);
        break;
      }
    }
  }

  /// Returns an object which can be used with `==` to determine if this
  /// [WebImageStream] shares the same listeners list as another
  /// [WebImageStream].
  ///
  /// This can be used to avoid un-registering and re-registering listeners
  /// after calling [WebImageProvider.resolve] on a new, but possibly
  /// equivalent, [WebImageProvider].
  ///
  /// The key may change once in the lifetime of the object. When it changes, it
  /// will go from being different than other [WebImageStream]'s keys to
  /// potentially being the same as others'. No notification is sent when this
  /// happens.
  Object get key => _completer ?? this;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<WebImageStreamCompleter>(
      'completer',
      _completer,
      ifPresent: _completer?.toStringShort(),
      ifNull: 'unresolved',
    ));
    properties.add(ObjectFlagProperty<List<WebImageStreamListener>>(
      'listeners',
      _listeners,
      ifPresent:
          '${_listeners?.length} listener${_listeners?.length == 1 ? "" : "s"}',
      ifNull: 'no listeners',
      level: _completer != null ? DiagnosticLevel.hidden : DiagnosticLevel.info,
    ));
    _completer?.debugFillProperties(properties);
  }
}

/// A completer which completes when either the web image resource has been
/// determined to be fetchable, or an <img> tag has finished decoding the image.
class WebImageStreamCompleter with Diagnosticable {
  final List<WebImageStreamListener> _listeners = <WebImageStreamListener>[];
  final List<ImageErrorListener> _ephemeralErrorListeners =
      <ImageErrorListener>[];
  WebImageInfo? _currentImage;
  bool? _bytesAreFetchable;
  FlutterErrorDetails? _currentError;

  /// A string identifying the source of the underlying image.
  String? debugLabel;

  /// Whether any listeners are currently registered.
  ///
  /// Clients should not depend on this value for their behavior, because having
  /// one listener's logic change when another listener happens to start or stop
  /// listening will lead to extremely hard-to-track bugs. Subclasses might use
  /// this information to determine whether to do any work when there are no
  /// listeners, however; for example, [MultiFrameImageStreamCompleter] uses it
  /// to determine when to iterate through frames of an animated image.
  ///
  /// Typically this is used by overriding [addListener], checking if
  /// [hasListeners] is false before calling `super.addListener()`, and if so,
  /// starting whatever work is needed to determine when to notify listeners;
  /// and similarly, by overriding [removeListener], checking if [hasListeners]
  /// is false after calling `super.removeListener()`, and if so, stopping that
  /// same work.
  ///
  /// The ephemeral error listeners (added through [addEphemeralErrorListener])
  /// will not be taken into consideration in this property.
  @protected
  @visibleForTesting
  bool get hasListeners => _listeners.isNotEmpty;

  /// We must avoid disposing a completer if it has never had a listener, even
  /// if all [keepAlive] handles get disposed.
  bool _hadAtLeastOneListener = false;

  /// Whether the future listeners added to this completer are initial listeners.
  ///
  /// This can be set to true when an [ImageStream] adds its initial listeners to
  /// this completer. This ultimately controls the synchronousCall parameter for
  /// the listener callbacks. When adding cached listeners to a completer,
  /// [_addingInitialListeners] can be set to false to indicate to the listeners
  /// that they are being called asynchronously.
  bool _addingInitialListeners = false;

  /// Adds a listener callback that is called whenever a new concrete [ImageInfo]
  /// object is available or an error is reported. If a concrete image is
  /// already available, or if an error has been already reported, this object
  /// will notify the listener synchronously.
  ///
  /// If the [ImageStreamCompleter] completes multiple images over its lifetime,
  /// this listener's [ImageStreamListener.onImage] will fire multiple times.
  ///
  /// {@macro flutter.painting.imageStream.addListener}
  ///
  /// See also:
  ///
  ///  * [addEphemeralErrorListener], which adds an error listener that is
  ///    automatically removed after first image load or error.
  void addListener(WebImageStreamListener listener) {
    _checkDisposed();
    _hadAtLeastOneListener = true;
    _listeners.add(listener);
    if (_currentImage != null) {
      try {
        listener.onImage(_currentImage!.clone(), !_addingInitialListeners);
      } catch (exception, stack) {
        reportError(
          context: ErrorDescription('by a synchronously-called image listener'),
          exception: exception,
          stack: stack,
        );
      }
    }
    if (_bytesAreFetchable != null) {
      try {
        listener.onImageCanBeFetched(!_addingInitialListeners);
      } catch (exception, stack) {
        reportError(
          context: ErrorDescription('by a synchronously-called image listener'),
          exception: exception,
          stack: stack,
        );
      }
    }
    if (_currentError != null && listener.onError != null) {
      try {
        listener.onError!(_currentError!.exception, _currentError!.stack);
      } catch (newException, newStack) {
        if (newException != _currentError!.exception) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: newException,
              library: 'image resource service',
              context: ErrorDescription(
                  'by a synchronously-called image error listener'),
              stack: newStack,
            ),
          );
        }
      }
    }
  }

  /// Adds an error listener callback that is called when the first error is reported.
  ///
  /// The callback will be removed automatically after the first successful
  /// image load or the first error - that is why it is called "ephemeral".
  ///
  /// If a concrete image is already available, the listener will be discarded
  /// synchronously. If an error has been already reported, the listener
  /// will be notified synchronously.
  ///
  /// The presence of a listener will affect neither the lifecycle of this object
  /// nor what [hasListeners] reports.
  ///
  /// It is different from [addListener] in a few points: Firstly, this one only
  /// listens to errors, while [addListener] listens to all kinds of events.
  /// Secondly, this listener will be automatically removed according to the
  /// rules mentioned above, while [addListener] will need manual removal.
  /// Thirdly, this listener will not affect how this object is disposed, while
  /// any non-removed listener added via [addListener] will forbid this object
  /// from disposal.
  ///
  /// When you want to know full information and full control, use [addListener].
  /// When you only want to get notified for an error ephemerally, use this function.
  ///
  /// See also:
  ///
  ///  * [addListener], which adds a full-featured listener and needs manual
  ///    removal.
  void addEphemeralErrorListener(ImageErrorListener listener) {
    _checkDisposed();
    if (_currentError != null) {
      // immediately fire the listener, and no need to add to _ephemeralErrorListeners
      try {
        listener(_currentError!.exception, _currentError!.stack);
      } catch (newException, newStack) {
        if (newException != _currentError!.exception) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: newException,
              library: 'image resource service',
              context: ErrorDescription(
                  'by a synchronously-called image error listener'),
              stack: newStack,
            ),
          );
        }
      }
    } else if (_currentImage == null) {
      // add to _ephemeralErrorListeners to wait for the error,
      // only if no image has been loaded
      _ephemeralErrorListeners.add(listener);
    }
  }

  int _keepAliveHandles = 0;

  /// Creates an [ImageStreamCompleterHandle] that will prevent this stream from
  /// being disposed at least until the handle is disposed.
  ///
  /// Such handles are useful when an image cache needs to keep a completer
  /// alive but does not itself have a listener subscribed, or when a widget
  /// that displays an image needs to temporarily unsubscribe from the completer
  /// but may re-subscribe in the future, for example when the [TickerMode]
  /// changes.
  WebImageStreamCompleterHandle keepAlive() {
    _checkDisposed();
    return WebImageStreamCompleterHandle._(this);
  }

  /// Stops the specified [listener] from receiving image stream events.
  ///
  /// If [listener] has been added multiple times, this removes the _first_
  /// instance of the listener.
  ///
  /// Once all listeners have been removed and all [keepAlive] handles have been
  /// disposed, this image stream is no longer usable.
  void removeListener(WebImageStreamListener listener) {
    _checkDisposed();
    for (int i = 0; i < _listeners.length; i += 1) {
      if (_listeners[i] == listener) {
        _listeners.removeAt(i);
        break;
      }
    }
    if (_listeners.isEmpty) {
      final List<VoidCallback> callbacks =
          _onLastListenerRemovedCallbacks.toList();
      for (final VoidCallback callback in callbacks) {
        callback();
      }
      _onLastListenerRemovedCallbacks.clear();
      _maybeDispose();
    }
  }

  bool _disposed = false;

  @mustCallSuper
  void _maybeDispose() {
    if (!_hadAtLeastOneListener ||
        _disposed ||
        _listeners.isNotEmpty ||
        _keepAliveHandles != 0) {
      return;
    }

    _ephemeralErrorListeners.clear();
    _currentImage = null;
    _disposed = true;
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError(
        'Stream has been disposed.\n'
        'An ImageStream is considered disposed once at least one listener has '
        'been added and subsequently all listeners have been removed and no '
        'handles are outstanding from the keepAlive method.\n'
        'To resolve this error, maintain at least one listener on the stream, '
        'or create an ImageStreamCompleterHandle from the keepAlive '
        'method, or create a new stream for the image.',
      );
    }
  }

  final List<VoidCallback> _onLastListenerRemovedCallbacks = <VoidCallback>[];

  /// Adds a callback to call when [removeListener] results in an empty
  /// list of listeners and there are no [keepAlive] handles outstanding.
  ///
  /// This callback will never fire if [removeListener] is never called.
  void addOnLastListenerRemovedCallback(VoidCallback callback) {
    _checkDisposed();
    _onLastListenerRemovedCallbacks.add(callback);
  }

  /// Removes a callback previously supplied to
  /// [addOnLastListenerRemovedCallback].
  void removeOnLastListenerRemovedCallback(VoidCallback callback) {
    _checkDisposed();
    _onLastListenerRemovedCallbacks.remove(callback);
  }

  /// Calls all the registered listeners to notify them of a new image.
  @protected
  void setImage(WebImageInfo image) {
    _checkDisposed();
    _currentImage = image;

    _ephemeralErrorListeners.clear();

    if (_listeners.isEmpty) {
      return;
    }
    // Make a copy to allow for concurrent modification.
    final List<WebImageStreamListener> localListeners =
        List<WebImageStreamListener>.of(_listeners);
    for (final WebImageStreamListener listener in localListeners) {
      try {
        listener.onImage(image.clone(), false);
      } catch (exception, stack) {
        reportError(
          context: ErrorDescription('by an image listener'),
          exception: exception,
          stack: stack,
        );
      }
    }
  }

  /// Calls all the registered error listeners to notify them of an error that
  /// occurred while resolving the image.
  ///
  /// If no error listeners (listeners with an [ImageStreamListener.onError]
  /// specified) are attached, or if the handlers all rethrow the exception
  /// verbatim (with `throw exception`), a [FlutterError] will be reported using
  /// [FlutterError.reportError].
  ///
  /// The `context` should be a string describing where the error was caught, in
  /// a form that will make sense in English when following the word "thrown",
  /// as in "thrown while obtaining the image from the network" (for the context
  /// "while obtaining the image from the network").
  ///
  /// The `exception` is the error being reported; the `stack` is the
  /// [StackTrace] associated with the exception.
  ///
  /// The `informationCollector` is a callback (of type [InformationCollector])
  /// that is called when the exception is used by [FlutterError.reportError].
  /// It is used to obtain further details to include in the logs, which may be
  /// expensive to collect, and thus should only be collected if the error is to
  /// be logged in the first place.
  ///
  /// The `silent` argument causes the exception to not be reported to the logs
  /// in release builds, if passed to [FlutterError.reportError]. (It is still
  /// sent to error handlers.) It should be set to true if the error is one that
  /// is expected to be encountered in release builds, for example network
  /// errors. That way, logs on end-user devices will not have spurious
  /// messages, but errors during development will still be reported.
  ///
  /// See [FlutterErrorDetails] for further details on these values.
  void reportError({
    DiagnosticsNode? context,
    required Object exception,
    StackTrace? stack,
    InformationCollector? informationCollector,
    bool silent = false,
  }) {
    _currentError = FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'image resource service',
      context: context,
      informationCollector: informationCollector,
      silent: silent,
    );

    // Make a copy to allow for concurrent modification.
    final List<ImageErrorListener> localErrorListeners = <ImageErrorListener>[
      ..._listeners
          .map<ImageErrorListener?>(
              (WebImageStreamListener listener) => listener.onError)
          .whereType<ImageErrorListener>(),
      ..._ephemeralErrorListeners,
    ];

    _ephemeralErrorListeners.clear();

    bool handled = false;
    for (final ImageErrorListener errorListener in localErrorListeners) {
      try {
        errorListener(exception, stack);
        handled = true;
      } catch (newException, newStack) {
        if (newException != exception) {
          FlutterError.reportError(
            FlutterErrorDetails(
              context: ErrorDescription(
                  'when reporting an error to an image listener'),
              library: 'image resource service',
              exception: newException,
              stack: newStack,
            ),
          );
        }
      }
    }
    if (!handled) {
      FlutterError.reportError(_currentError!);
    }
  }

  /// Called when it has been determined that the image can be fetched directly.
  ///
  /// In this case, an [Image.network] will be used to show the image.
  void reportImageCanBeLoaded() {
    _checkDisposed();
    _bytesAreFetchable = true;
    if (hasListeners) {
      // Make a copy to allow for concurrent modification.
      final List<WebImageCanBeFetchedListener> localListeners = _listeners
          .map<WebImageCanBeFetchedListener?>(
              (WebImageStreamListener listener) => listener.onImageCanBeFetched)
          .whereType<WebImageCanBeFetchedListener>()
          .toList();
      for (final WebImageCanBeFetchedListener listener in localListeners) {
        listener(false);
      }
    }
  }

  /// Accumulates a list of strings describing the object's state. Subclasses
  /// should override this to have their information included in [toString].
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<WebImageInfo>('current', _currentImage,
        ifNull: 'unresolved', showName: false));
    description.add(ObjectFlagProperty<List<WebImageStreamListener>>(
      'listeners',
      _listeners,
      ifPresent:
          '${_listeners.length} listener${_listeners.length == 1 ? "" : "s"}',
    ));
    description.add(ObjectFlagProperty<List<ImageErrorListener>>(
      'ephemeralErrorListeners',
      _ephemeralErrorListeners,
      ifPresent:
          '${_ephemeralErrorListeners.length} ephemeralErrorListener${_ephemeralErrorListeners.length == 1 ? "" : "s"}',
    ));
    description
        .add(FlagProperty('disposed', value: _disposed, ifTrue: '<disposed>'));
  }
}

/// Manages the loading of [web.HTMLImageElement] objects for static
/// [ImageStream]s (those with only one frame).
class OneFrameWebImageStreamCompleter extends WebImageStreamCompleter {
  /// Creates a manager for one-frame [ImageStream]s.
  ///
  /// The image resource awaits the given [Future]. When the future resolves,
  /// it notifies the [ImageListener]s that have been registered with
  /// [addListener].
  ///
  /// The [InformationCollector], if provided, is invoked if the given [Future]
  /// resolves with an error, and can be used to supplement the reported error
  /// message (for example, giving the image's URL).
  ///
  /// Errors are reported using [FlutterError.reportError] with the `silent`
  /// argument on [FlutterErrorDetails] set to true, meaning that by default the
  /// message is only dumped to the console in debug mode (see [
  /// FlutterErrorDetails]).
  OneFrameWebImageStreamCompleter(
    Future<bool> bytesCanBeFetched,
    Future<WebImageInfo> image, {
    InformationCollector? informationCollector,
  }) {
    bytesCanBeFetched.then<void>((bool canBeFetched) {
      if (canBeFetched) {
        reportImageCanBeLoaded();
        return;
      }
      image.then<void>(setImage, onError: (Object error, StackTrace stack) {
        reportError(
          context: ErrorDescription('resolving a single-frame image stream'),
          exception: error,
          stack: stack,
          informationCollector: informationCollector,
          silent: true,
        );
      });
    }, onError: (Object error, StackTrace stack) {
      reportError(
        context: ErrorDescription('resolving a single-frame image stream'),
        exception: error,
        stack: stack,
        informationCollector: informationCollector,
        silent: true,
      );
    });
  }
}

// A completer used when resolving an image fails sync.
class _ErrorImageCompleter extends WebImageStreamCompleter {}

const String _flutterWebImageLibrary = 'package:flutter/widgets/web_image.dart';

/// A handle which signifies that the associated completer should be kept alive
/// even if there are currently no listeners on it.
class WebImageStreamCompleterHandle {
  WebImageStreamCompleterHandle._(WebImageStreamCompleter this._completer) {
    _completer!._keepAliveHandles += 1;
    // TODO(polina-c): stop duplicating code across disposables
    // https://github.com/flutter/flutter/issues/137435
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: _flutterWebImageLibrary,
        className: '$WebImageStreamCompleterHandle',
        object: this,
      );
    }
  }

  WebImageStreamCompleter? _completer;

  /// Call this method to signal the [ImageStreamCompleter] that it can now be
  /// disposed when its last listener drops.
  ///
  /// This method must only be called once per object.
  void dispose() {
    assert(_completer != null);
    assert(_completer!._keepAliveHandles > 0);
    assert(!_completer!._disposed);

    _completer!._keepAliveHandles -= 1;
    _completer!._maybeDispose();
    _completer = null;
    // TODO(polina-c): stop duplicating code across disposables
    // https://github.com/flutter/flutter/issues/137435
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
  }
}

/// A listener which is notified when a web image resource can either be
/// fetched directly, or if it has been decoded by an <img> tag.
@immutable
class WebImageStreamListener {
  /// Creates a new [WebImageListener].
  const WebImageStreamListener(this.onImage, this.onImageCanBeFetched,
      {this.onError});

  /// A callback which is called when the web image resource has been decoded
  /// by an `<img>` tag.
  final WebImageListener onImage;

  /// A callback which is called when it has been determined that the web image
  /// can be fetched directly.
  final WebImageCanBeFetchedListener onImageCanBeFetched;

  /// A callback which is called if an error has been thrown while trying to
  /// determine if the web image can be fetched or while decoding it.
  final ImageErrorListener? onError;

  @override
  int get hashCode => Object.hash(onImage, onImageCanBeFetched, onError);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is WebImageStreamListener
        && other.onImage == onImage
        && other.onImageCanBeFetched == onImageCanBeFetched
        && other.onError == onError;
  }
}

/// The type of the callback for [WebImageStreamListener.onImage].
typedef WebImageListener = void Function(
    WebImageInfo info, bool synchronousCall);

/// The type of the callback for [WebImageStreamListener.onImageCanBeFetched].
typedef WebImageCanBeFetchedListener = void Function(bool synchronousCall);

/// Contains the `<img>` tag to show a web image. The underlying image is
/// guaranteed to have been decoded and is ready to display immediately.
@immutable
class WebImageInfo {
  /// Creates a new [WebImageInfo].
  const WebImageInfo(
    this.image, {
    this.debugLabel,
  });

  /// The decoded <img> element.
  final web.HTMLImageElement image;

  /// A debug label explaining the source of the image.
  final String? debugLabel;

  /// An estimate of the image size in bytes.
  int get sizeBytes => (image.naturalWidth * image.naturalHeight * 4).toInt();

  /// Creates a clone of this [WebImageInfo].
  WebImageInfo clone() {
    return WebImageInfo(
      image.cloneNode(true) as web.HTMLImageElement,
      debugLabel: debugLabel,
    );
  }

  @override
  String toString() => '${debugLabel != null ? '$debugLabel ' : ''}$image';

  @override
  int get hashCode => Object.hash(image, debugLabel);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is WebImageInfo
        && other.image == image
        && other.debugLabel == debugLabel;
  }
}

const int _kDefaultSize = 1000;
const int _kDefaultSizeBytes = 100 << 20; // 100 MiB

/// Class for caching web images.
///
/// Implements a least-recently-used cache of up to 1000 images, and up to 100
/// MB. The maximum size can be adjusted using [maximumSize] and
/// [maximumSizeBytes].
///
/// The cache also holds a list of 'live' references. An image is considered
/// live if its [WebImageStreamCompleter]'s listener count has never dropped to
/// zero after adding at least one listener. The cache uses
/// [WebImageStreamCompleter.addOnLastListenerRemovedCallback] to determine when
/// this has happened.
///
/// The [putIfAbsent] method is the main entry-point to the cache API. It
/// returns the previously cached [WebImageStreamCompleter] for the given key,
/// if available; if not, it calls the given callback to obtain it first. In
/// either case, the key is moved to the 'most recently used' position.
class WebImageCache {
  final Map<String, _PendingImage> _pendingImages = <String, _PendingImage>{};
  final Map<String, _CachedImage> _cache = <String, _CachedImage>{};

  /// WebImageStreamCompleters with at least one listener. These images may or may
  /// not fit into the _pendingImages or _cache objects.
  ///
  /// Unlike _cache, the [_CachedImage] for this may have a null byte size.
  final Map<String, _LiveImage> _liveImages = <String, _LiveImage>{};
  final Map<String, _FetchableImage> _fetchableImages =
      <String, _FetchableImage>{};

  /// Maximum number of entries to store in the cache.
  ///
  /// Once this many entries have been cached, the least-recently-used entry is
  /// evicted when adding a new entry.
  int get maximumSize => _maximumSize;
  int _maximumSize = _kDefaultSize;

  /// Changes the maximum cache size.
  ///
  /// If the new size is smaller than the current number of elements, the
  /// extraneous elements are evicted immediately. Setting this to zero and then
  /// returning it to its original value will therefore immediately clear the
  /// cache.
  set maximumSize(int value) {
    assert(value >= 0);
    if (value == maximumSize) {
      return;
    }
    TimelineTask? debugTimelineTask;
    if (!kReleaseMode) {
      debugTimelineTask = TimelineTask()
        ..start(
          'ImageCache.setMaximumSize',
          arguments: <String, dynamic>{'value': value},
        );
    }
    _maximumSize = value;
    if (maximumSize == 0) {
      clear();
    } else {
      _checkCacheSize(debugTimelineTask);
    }
    if (!kReleaseMode) {
      debugTimelineTask!.finish();
    }
  }

  /// The current number of cached entries.
  int get currentSize => _cache.length;

  /// Maximum size of entries to store in the cache in bytes.
  ///
  /// Once more than this amount of bytes have been cached, the
  /// least-recently-used entry is evicted until there are fewer than the
  /// maximum bytes.
  int get maximumSizeBytes => _maximumSizeBytes;
  int _maximumSizeBytes = _kDefaultSizeBytes;

  /// Changes the maximum cache bytes.
  ///
  /// If the new size is smaller than the current size in bytes, the
  /// extraneous elements are evicted immediately. Setting this to zero and then
  /// returning it to its original value will therefore immediately clear the
  /// cache.
  set maximumSizeBytes(int value) {
    assert(value >= 0);
    if (value == _maximumSizeBytes) {
      return;
    }
    TimelineTask? debugTimelineTask;
    if (!kReleaseMode) {
      debugTimelineTask = TimelineTask()
        ..start(
          'ImageCache.setMaximumSizeBytes',
          arguments: <String, dynamic>{'value': value},
        );
    }
    _maximumSizeBytes = value;
    if (_maximumSizeBytes == 0) {
      clear();
    } else {
      _checkCacheSize(debugTimelineTask);
    }
    if (!kReleaseMode) {
      debugTimelineTask!.finish();
    }
  }

  /// The current size of cached entries in bytes.
  int get currentSizeBytes => _currentSizeBytes;
  int _currentSizeBytes = 0;

  /// Evicts all pending and keepAlive entries from the cache.
  ///
  /// This is useful if, for instance, the root asset bundle has been updated
  /// and therefore new images must be obtained.
  ///
  /// Images which have not finished loading yet will not be removed from the
  /// cache, and when they complete they will be inserted as normal.
  ///
  /// This method does not clear live references to images, since clearing those
  /// would not reduce memory pressure. Such images still have listeners in the
  /// application code, and will still remain resident in memory.
  ///
  /// To clear live references, use [clearLiveImages].
  void clear() {
    if (!kReleaseMode) {
      Timeline.instantSync(
        'ImageCache.clear',
        arguments: <String, dynamic>{
          'pendingImages': _pendingImages.length,
          'keepAliveImages': _cache.length,
          'liveImages': _liveImages.length,
          'currentSizeInBytes': _currentSizeBytes,
        },
      );
    }
    for (final _CachedImage image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    for (final _PendingImage pendingImage in _pendingImages.values) {
      pendingImage.removeListener();
    }
    _pendingImages.clear();
    for (final _FetchableImage image in _fetchableImages.values) {
      image.dispose();
    }
    _fetchableImages.clear();
    _currentSizeBytes = 0;
  }

  /// Evicts a single entry from the cache, returning true if successful.
  ///
  /// Pending images waiting for completion are removed as well, returning true
  /// if successful. When a pending image is removed the listener on it is
  /// removed as well to prevent it from adding itself to the cache if it
  /// eventually completes.
  ///
  /// If this method removes a pending image, it will also remove
  /// the corresponding live tracking of the image, since it is no longer clear
  /// if the image will ever complete or have any listeners, and failing to
  /// remove the live reference could leave the cache in a state where all
  /// subsequent calls to [putIfAbsent] will return an [ImageStreamCompleter]
  /// that will never complete.
  ///
  /// If this method removes a completed image, it will _not_ remove the live
  /// reference to the image, which will only be cleared when the listener
  /// count on the completer drops to zero. To clear live image references,
  /// whether completed or not, use [clearLiveImages].
  ///
  /// The `key` must be equal to the string used to cache an image in
  /// [WebImageCache.putIfAbsent].
  ///
  /// The `includeLive` argument determines whether images that still have
  /// listeners in the tree should be evicted as well. This parameter should be
  /// set to true in cases where the image may be corrupted and needs to be
  /// completely discarded by the cache. It should be set to false when calls
  /// to evict are trying to relieve memory pressure, since an image with a
  /// listener will not actually be evicted from memory, and subsequent attempts
  /// to load it will end up allocating more memory for the image again.
  ///
  /// See also:
  ///
  ///  * [WebImageProvider], for providing images to the [WebImage] widget.
  bool evict(String key, {bool includeLive = true}) {
    if (includeLive) {
      // Remove from live images - the cache will not be able to mark
      // it as complete, and it might be getting evicted because it
      // will never complete, e.g. it was loaded in a FakeAsync zone.
      // In such a case, we need to make sure subsequent calls to
      // putIfAbsent don't return this image that may never complete.
      final _LiveImage? image = _liveImages.remove(key);
      image?.dispose();
    }
    final _PendingImage? pendingImage = _pendingImages.remove(key);
    if (pendingImage != null) {
      if (!kReleaseMode) {
        Timeline.instantSync('ImageCache.evict', arguments: <String, dynamic>{
          'type': 'pending',
        });
      }
      pendingImage.removeListener();
      return true;
    }
    final _CachedImage? image = _cache.remove(key);
    if (image != null) {
      if (!kReleaseMode) {
        Timeline.instantSync('ImageCache.evict', arguments: <String, dynamic>{
          'type': 'keepAlive',
          'sizeInBytes': image.sizeBytes,
        });
      }
      _currentSizeBytes -= image.sizeBytes!;
      image.dispose();
      return true;
    }
    if (!kReleaseMode) {
      Timeline.instantSync('ImageCache.evict', arguments: <String, dynamic>{
        'type': 'miss',
      });
    }
    return false;
  }

  /// Updates the least recently used image cache with this image, if it is
  /// less than the [maximumSizeBytes] of this cache.
  ///
  /// Resizes the cache as appropriate to maintain the constraints of
  /// [maximumSize] and [maximumSizeBytes].
  void _touch(String key, _CachedImage image, TimelineTask? timelineTask) {
    if (image.sizeBytes != null &&
        image.sizeBytes! <= maximumSizeBytes &&
        maximumSize > 0) {
      _currentSizeBytes += image.sizeBytes!;
      _cache[key] = image;
      _checkCacheSize(timelineTask);
    } else {
      image.dispose();
    }
  }

  void _trackLiveImage(
      String key, WebImageStreamCompleter completer, int? sizeBytes) {
    // Avoid adding unnecessary callbacks to the completer.
    _liveImages.putIfAbsent(key, () {
      // Even if no callers to ImageProvider.resolve have listened to the stream,
      // the cache is listening to the stream and will remove itself once the
      // image completes to move it from pending to keepAlive.
      // Even if the cache size is 0, we still add this tracker, which will add
      // a keep alive handle to the stream.
      return _LiveImage(
        completer,
        () {
          _liveImages.remove(key);
        },
      );
    }).sizeBytes ??= sizeBytes;
  }

  /// Returns the previously cached [WebImageStream] for the given key, if
  /// available; if not, calls the given callback to obtain it first. In either
  /// case, the key is moved to the 'most recently used' position.
  ///
  /// In the event that the loader throws an exception, it will be caught only if
  /// `onError` is also provided. When an exception is caught resolving an image,
  /// no completers are cached and `null` is returned instead of a new
  /// completer.
  ///
  /// Images that are larger than [maximumSizeBytes] are not cached, and do not
  /// cause other images in the cache to be evicted.
  WebImageStreamCompleter? putIfAbsent(
      String key, WebImageStreamCompleter Function() loader,
      {ImageErrorListener? onError}) {
    TimelineTask? debugTimelineTask;
    if (!kReleaseMode) {
      debugTimelineTask = TimelineTask()
        ..start(
          'ImageCache.putIfAbsent',
          arguments: <String, dynamic>{
            'key': key,
          },
        );
    }
    WebImageStreamCompleter? result = _pendingImages[key]?.completer;
    // Nothing needs to be done because the image hasn't loaded yet.
    if (result != null) {
      if (!kReleaseMode) {
        debugTimelineTask!
            .finish(arguments: <String, dynamic>{'result': 'pending'});
      }
      return result;
    }

    final _FetchableImage? fetchableImage = _fetchableImages[key];
    if (fetchableImage != null) {
      if (!kReleaseMode) {
        debugTimelineTask!
            .finish(arguments: <String, dynamic>{'result': 'keepAlive'});
      }
      return fetchableImage.completer;
    }

    // Remove the provider from the list so that we can move it to the
    // recently used position below.
    // Don't use _touch here, which would trigger a check on cache size that is
    // not needed since this is just moving an existing cache entry to the head.
    final _CachedImage? image = _cache.remove(key);
    if (image != null) {
      if (!kReleaseMode) {
        debugTimelineTask!
            .finish(arguments: <String, dynamic>{'result': 'keepAlive'});
      }
      // The image might have been keptAlive but had no listeners (so not live).
      // Make sure the cache starts tracking it as live again.
      _trackLiveImage(
        key,
        image.completer,
        image.sizeBytes,
      );
      _cache[key] = image;
      return image.completer;
    }

    final _LiveImage? liveImage = _liveImages[key];
    if (liveImage != null) {
      _touch(
        key,
        _CachedImage(
          liveImage.completer,
          sizeBytes: liveImage.sizeBytes,
        ),
        debugTimelineTask,
      );
      if (!kReleaseMode) {
        debugTimelineTask!
            .finish(arguments: <String, dynamic>{'result': 'keepAlive'});
      }
      return liveImage.completer;
    }

    try {
      result = loader();
      _trackLiveImage(key, result, null);
    } catch (error, stackTrace) {
      if (!kReleaseMode) {
        debugTimelineTask!.finish(arguments: <String, dynamic>{
          'result': 'error',
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        });
      }
      if (onError != null) {
        onError(error, stackTrace);
        return null;
      } else {
        rethrow;
      }
    }

    if (!kReleaseMode) {
      debugTimelineTask!.start('listener');
    }
    // A multi-frame provider may call the listener more than once. We need do make
    // sure that some cleanup works won't run multiple times, such as finishing the
    // tracing task or removing the listeners
    bool listenedOnce = false;

    // We shouldn't use the _pendingImages map if the cache is disabled, but we
    // will have to listen to the image at least once so we don't leak it in
    // the live image tracking.
    final bool trackPendingImage = maximumSize > 0 && maximumSizeBytes > 0;
    late _PendingImage pendingImage;
    void listener(WebImageInfo? info, bool syncCall) {
      int? sizeBytes;
      if (info != null) {
        sizeBytes = info.sizeBytes;
      }
      final _CachedImage image = _CachedImage(
        result!,
        sizeBytes: sizeBytes,
      );

      _trackLiveImage(key, result, sizeBytes);

      // Only touch if the cache was enabled when resolve was initially called.
      if (trackPendingImage) {
        _touch(key, image, debugTimelineTask);
      } else {
        image.dispose();
      }

      _pendingImages.remove(key);
      if (!listenedOnce) {
        pendingImage.removeListener();
      }
      if (!kReleaseMode && !listenedOnce) {
        debugTimelineTask!
          ..finish(arguments: <String, dynamic>{
            'syncCall': syncCall,
            'sizeInBytes': sizeBytes,
          })
          ..finish(arguments: <String, dynamic>{
            'currentSizeBytes': currentSizeBytes,
            'currentSize': currentSize,
          });
      }
      listenedOnce = true;
    }

    void onBytesCanBeFetchedListener(bool syncCall) {
      _fetchableImages[key] = _FetchableImage(result!);

      _pendingImages.remove(key);
      if (!listenedOnce) {
        pendingImage.removeListener();
      }
      if (!kReleaseMode && !listenedOnce) {
        debugTimelineTask!
          ..finish(arguments: <String, dynamic>{
            'syncCall': syncCall,
            'sizeInBytes': 0,
          })
          ..finish(arguments: <String, dynamic>{
            'currentSizeBytes': currentSizeBytes,
            'currentSize': currentSize,
          });
      }
      listenedOnce = true;
    }

    final WebImageStreamListener streamListener =
        WebImageStreamListener(listener, onBytesCanBeFetchedListener);
    pendingImage = _PendingImage(result, streamListener);
    if (trackPendingImage) {
      _pendingImages[key] = pendingImage;
    }
    // Listener is removed in [_PendingImage.removeListener].
    result.addListener(streamListener);

    return result;
  }

  /// Returns the already decoded `<img>` element with the given [key], if one
  /// exists.
  WebImageInfo? getLoadedImage(String key) {
    final _CachedImage? image = _cache[key];
    if (image != null) {
      return image.completer._currentImage;
    }

    return null;
  }

  /// The [WebImageCacheStatus] information for the given `key`.
  WebImageCacheStatus statusForKey(String key) {
    return WebImageCacheStatus._(
      pending: _pendingImages.containsKey(key),
      keepAlive: _cache.containsKey(key),
      live: _liveImages.containsKey(key),
      fetchable: _fetchableImages.containsKey(key),
    );
  }

  /// Returns whether this `key` has been previously added by [putIfAbsent].
  bool containsKey(String key) {
    return _pendingImages[key] != null ||
        _cache[key] != null ||
        _fetchableImages[key] != null;
  }

  /// The number of live images being held by the [WebImageCache].
  ///
  /// Compare with [WebImageCache.currentSize] for keepAlive images.
  int get liveImageCount => _liveImages.length;

  /// The number of images being tracked as pending in the [WebImageCache].
  ///
  /// Compare with [WebImageCache.currentSize] for keepAlive images.
  int get pendingImageCount => _pendingImages.length;

  /// Clears any live references to images in this cache.
  ///
  /// An image is considered live if its [WebImageStreamCompleter] has never hit
  /// zero listeners after adding at least one listener. The
  /// [WebImageStreamCompleter.addOnLastListenerRemovedCallback] is used to
  /// determine when this has happened.
  ///
  /// This is called after a hot reload to evict any stale references to image
  /// data for assets that have changed. Calling this method does not relieve
  /// memory pressure, since the live image caching only tracks image instances
  /// that are also being held by at least one other object.
  void clearLiveImages() {
    for (final _LiveImage image in _liveImages.values) {
      image.dispose();
    }
    _liveImages.clear();
  }

  // Remove images from the cache until both the length and bytes are below
  // maximum, or the cache is empty.
  void _checkCacheSize(TimelineTask? timelineTask) {
    final Map<String, dynamic> finishArgs = <String, dynamic>{};
    if (!kReleaseMode) {
      timelineTask!.start('checkCacheSize');
      finishArgs['evictedKeys'] = <String>[];
      finishArgs['currentSize'] = currentSize;
      finishArgs['currentSizeBytes'] = currentSizeBytes;
    }
    while (
        _currentSizeBytes > _maximumSizeBytes || _cache.length > _maximumSize) {
      final String key = _cache.keys.first;
      final _CachedImage image = _cache[key]!;
      _currentSizeBytes -= image.sizeBytes!;
      image.dispose();
      _cache.remove(key);
      if (!kReleaseMode) {
        (finishArgs['evictedKeys'] as List<String>).add(key);
      }
    }
    if (!kReleaseMode) {
      finishArgs['endSize'] = currentSize;
      finishArgs['endSizeBytes'] = currentSizeBytes;
      timelineTask!.finish(arguments: finishArgs);
    }
    assert(_currentSizeBytes >= 0);
    assert(_cache.length <= maximumSize);
    assert(_currentSizeBytes <= maximumSizeBytes);
  }
}

/// The singleton instance of [WebImageCache].
final WebImageCache webImageCache = WebImageCache();

/// Information about how the [WebImageCache] is tracking an image.
///
/// A [pending] image is one that has not completed yet. It may also be tracked
/// as [live] because something is listening to it.
///
/// A [keepAlive] image is being held in the cache, which uses Least Recently
/// Used semantics to determine when to evict an image. These images are subject
/// to eviction based on [WebImageCache.maximumSizeBytes] and
/// [WebImageCache.maximumSize]. It may be [live], but not [pending].
///
/// A [live] image is being held until its [ImageStreamCompleter] has no more
/// listeners. It may also be [pending] or [keepAlive].
///
/// A [fetchable] image is one that can be directly fetched.
///
/// An [untracked] image is not being cached.
///
/// To obtain an [WebImageCacheStatus], use [WebImageCache.statusForKey] or
/// [ImageProvider.obtainCacheStatus].
@immutable
class WebImageCacheStatus {
  const WebImageCacheStatus._({
    this.pending = false,
    this.keepAlive = false,
    this.live = false,
    this.fetchable = false,
  }) : assert(!pending || !keepAlive);

  /// An image that has been submitted to [WebImageCache.putIfAbsent], but
  /// not yet completed.
  final bool pending;

  /// An image that has been submitted to [WebImageCache.putIfAbsent], has
  /// completed, fits based on the sizing rules of the cache, and has not been
  /// evicted.
  ///
  /// Such images will be kept alive even if [live] is false, as long
  /// as they have not been evicted from the cache based on its sizing rules.
  final bool keepAlive;

  /// An image that has been submitted to [WebImageCache.putIfAbsent] and has at
  /// least one listener on its [WebImageStreamCompleter].
  ///
  /// Such images may also be [keepAlive] if they fit in the cache based on its
  /// sizing rules. They may also be [pending] if they have not yet resolved.
  final bool live;

  /// An image that has been submitted to [WebImageCache.putIfAbsent] and has
  /// been determined to be directly fetchable.
  final bool fetchable;

  /// An image that is tracked in some way by the [WebImageCache], whether
  /// [pending], [keepAlive], [live], or [fetchable].
  bool get tracked => pending || keepAlive || live || fetchable;

  /// An image that either has not been submitted to
  /// [WebImageCache.putIfAbsent] or has otherwise been evicted from the
  /// [keepAlive] and [live] caches.
  bool get untracked => !pending && !keepAlive && !live && !fetchable;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is WebImageCacheStatus &&
        other.pending == pending &&
        other.keepAlive == keepAlive &&
        other.live == live &&
        other.fetchable == fetchable;
  }

  @override
  int get hashCode => Object.hash(pending, keepAlive, live, fetchable);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'ImageCacheStatus')}(pending: $pending, live: $live, keepAlive: $keepAlive, fetchable: $fetchable)';
}

/// Base class for [_CachedImage] and [_LiveImage].
///
/// Exists primarily so that a [_LiveImage] cannot be added to the
/// [ImageCache._cache].
abstract class _CachedImageBase {
  _CachedImageBase(
    this.completer, {
    this.sizeBytes,
  }) : handle = completer.keepAlive() {
    // TODO(polina-c): stop duplicating code across disposables
    // https://github.com/flutter/flutter/issues/137435
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'package:flutter/painting.dart',
        className: '$_CachedImageBase',
        object: this,
      );
    }
  }

  final WebImageStreamCompleter completer;
  int? sizeBytes;
  WebImageStreamCompleterHandle? handle;

  @mustCallSuper
  void dispose() {
    assert(handle != null);
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    // Give any interested parties a chance to listen to the stream before we
    // potentially dispose it.
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      assert(handle != null);
      handle?.dispose();
      handle = null;
    }, debugLabel: 'CachedImage.disposeHandle');
  }
}

class _CachedImage extends _CachedImageBase {
  _CachedImage(super.completer, {super.sizeBytes});
}

class _LiveImage extends _CachedImageBase {
  _LiveImage(WebImageStreamCompleter completer, VoidCallback handleRemove,
      {int? sizeBytes})
      : super(completer, sizeBytes: sizeBytes) {
    _handleRemove = () {
      handleRemove();
      dispose();
    };
    completer.addOnLastListenerRemovedCallback(_handleRemove);
  }

  late VoidCallback _handleRemove;

  @override
  void dispose() {
    completer.removeOnLastListenerRemovedCallback(_handleRemove);
    super.dispose();
  }

  @override
  String toString() => describeIdentity(this);
}

class _PendingImage {
  _PendingImage(this.completer, this.listener);

  final WebImageStreamCompleter completer;
  final WebImageStreamListener listener;

  void removeListener() {
    completer.removeListener(listener);
  }
}

class _FetchableImage extends _CachedImageBase {
  _FetchableImage(super.completer) : super(sizeBytes: 0);
}

/// If the [provider] points to a web image resource that can be directly
/// fetched, then this calls [precacheImage] with the resource URL as the
/// provider. Otherwise, this completes when the underlying image resource
/// has been decoded and is ready to display in an <img> element.
Future<void> precacheWebImage(
  WebImageProvider provider,
  BuildContext context, {
  Size? size,
  ImageErrorListener? onError,
}) {
  final WebImageProviderImpl providerImpl = provider as WebImageProviderImpl;
  final Completer<void> completer = Completer<void>();
  final WebImageStream stream = providerImpl.resolve();
  WebImageStreamListener? listener;
  listener = WebImageStreamListener(
    (WebImageInfo? image, bool sync) {
      if (!completer.isCompleted) {
        completer.complete();
      }
      // Give callers until at least the end of the frame to subscribe to the
      // image stream.
      // See ImageCache._liveImages
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        stream.removeListener(listener!);
      }, debugLabel: 'precacheImage.removeListener');
    },
    (bool sync) {
      stream.removeListener(listener!);
      precacheImage(NetworkImage(provider.src), context,
              size: size, onError: onError)
          .then<void>((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
    },
    onError: (Object exception, StackTrace? stackTrace) {
      if (!completer.isCompleted) {
        completer.complete();
      }
      stream.removeListener(listener!);
      if (onError != null) {
        onError(exception, stackTrace);
      } else {
        FlutterError.reportError(FlutterErrorDetails(
          context: ErrorDescription('image failed to precache'),
          library: 'image resource service',
          exception: exception,
          stack: stackTrace,
          silent: true,
        ));
      }
    },
  );
  stream.addListener(listener);
  return completer.future;
}

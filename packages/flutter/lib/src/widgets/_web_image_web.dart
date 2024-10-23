// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:js_util';
import 'dart:ui_web' as ui_web;

import '../../widgets.dart';
import '../web.dart' as web;

@JS('fetch')
external JSPromise<_JSResponse> __fetch(JSString url);

Future<_JSResponse> _fetch(String url) {
  return promiseToFuture<_JSResponse>(__fetch(url.toJS));
}

extension type _JSResponse(JSObject _) implements JSObject {}

/// Returns [true] if the bytes at [url] can be fetched.
///
/// The bytes may be unable to be fetched if they aren't from the same origin
/// and the sever hosting them does not allow cross-origin requests.
Future<bool> checkIfImageBytesCanBeFetched(String url) {
  return _fetch(url).then((_JSResponse response) {
    return true;
  }).catchError((_) {
    return false;
  });
}

Widget createImgElementWidget(String src) => ImgElementImage(src);

class ImgElementImage extends StatefulWidget {
  ImgElementImage(
    this.src, {
    super.key,
  });

  final String src;

  @override
  State<StatefulWidget> createState() => _ImgElementImageState();
}

class _ImgElementImageState extends State<ImgElementImage> {
  _ImgElementImageState() {
    if (_registeredViewType == null) {
      _register();
    }
  }

  // Keeps track if this widget has already registered its view factories or not.
  static String? _registeredViewType;

  /// Override this to provide a custom implementation of [ui_web.platformViewRegistry.registerViewFactory].
  ///
  /// This should only be used for testing.
  // See `_platform_selectable_region_context_menu_io.dart`.
  @visibleForTesting
  // ignore: invalid_use_of_visible_for_testing_member
  static RegisterViewFactory? debugOverrideRegisterViewFactory;

  // ignore: invalid_use_of_visible_for_testing_member
  static RegisterViewFactory get _registerViewFactory =>
      debugOverrideRegisterViewFactory ??
      ui_web.platformViewRegistry.registerViewFactory;

  static const String _viewType = 'Browser__ImageElementType__';

  static int _imgElementCount = 0;
  static const String _naturalSizeCallbackPrefix =
      'Flutter__ImageElement_setNaturalSizeCallback__';

  static void _register() {
    assert(_registeredViewType == null);
    _registerViewFactory(_viewType, (int viewId, {Object? params}) {
      final Map<Object?, Object?> paramsMap = params! as Map<Object?, Object?>;
      final String paramSrc = paramsMap['src']! as String;
      print('CALLING VIEW FACTORY FOR IMG SRC = $paramSrc');
      final web.HTMLImgElement imgElement =
          web.document.createElement('img') as web.HTMLImgElement;
      imgElement
        ..style.width = '100%'
        ..style.height = '100%'
        ..src = paramSrc;
      imgElement.addEventListener(
        'load',
        (web.Event event) {
          final int setNaturalSizeCallbackId =
              paramsMap['setNaturalSizeCallbackId']! as int;
          final JSFunction setNaturalSize = web.window.getProperty(
              '$_naturalSizeCallbackPrefix$setNaturalSizeCallbackId'.toJS)!;
          print('SETTING NATURAL SIZE NOW!!!');
          setNaturalSize.callAsFunction(null, imgElement.naturalWidth.toJS,
              imgElement.naturalHeight.toJS);
        }.toJS,
        JSObject()..setProperty('once'.toJS, true.toJS),
      );
      return imgElement;
    }, isVisible: true);
  }

  HtmlElementView? htmlElementView;

  num? naturalWidth;
  num? naturalHeight;

  int? imgElementId;

  @override
  void initState() {
    super.initState();
    imgElementId = _imgElementCount++;
    web.window.setProperty(
        '$_naturalSizeCallbackPrefix$imgElementId'.toJS,
        (int width, int height) {
          setState(() {
            print('CALLING SETSTATE WITH WIDTH = $width and HEIGHT = $height');
            naturalWidth = width;
            naturalHeight = height;
          });
        }.toJS);
  }

  @override
  Widget build(BuildContext context) {
    htmlElementView = HtmlElementView(
      viewType: _viewType,
      creationParams: <String, Object>{
        'src': widget.src,
        'setNaturalSizeCallbackId': imgElementId!,
      },
    );
    if (naturalWidth == null) {
      return htmlElementView!;
    } else {
      print('SETTING ASPECT RATIO TO ${naturalWidth! / naturalHeight!}');
      return AspectRatio(
        aspectRatio: naturalWidth! / naturalHeight!,
        child: htmlElementView,
      );
    }
  }
}

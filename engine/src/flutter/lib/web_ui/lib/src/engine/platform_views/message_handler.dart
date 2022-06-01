// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../dom.dart';
import '../services.dart';
import '../util.dart';
import 'content_manager.dart';

/// The signature for a callback for a Platform Message. From the `ui` package.
/// Copied here so there's no circular dependencies.
typedef _PlatformMessageResponseCallback = void Function(ByteData? data);

/// A function that handle a newly created [DomElement] with the contents of a
/// platform view with a unique [int] id.
typedef PlatformViewContentHandler = void Function(DomElement);

/// This class handles incoming framework messages to create/dispose Platform Views.
///
/// (An instance of this class is connected to the `flutter/platform_views`
/// Platform Channel in the [EnginePlatformDispatcher] class.)
///
/// It uses a [PlatformViewManager] to handle the CRUD of the DOM of Platform Views.
/// This `contentManager` is shared across the engine, to perform
/// all operations related to platform views (registration, rendering, etc...),
/// regardless of the rendering backend.
///
/// When the `contents` of a Platform View are created, a [PlatformViewContentHandler]
/// function (passed from the outside) will decide where in the DOM to inject
/// said content.
///
/// The rendering/compositing of Platform Views can create the other "half" of a
/// Platform View: the `slot`, through the [createPlatformViewSlot] method.
///
/// When a Platform View is disposed of, it is removed from the cache (and DOM)
/// directly by the `contentManager`. The canvaskit rendering backend needs to do
/// some extra cleanup of its internal state, but it can do it automatically. See
/// [HtmlViewEmbedder.disposeViews]
class PlatformViewMessageHandler {
  final MethodCodec _codec = const StandardMethodCodec();

  final PlatformViewManager _contentManager;
  final PlatformViewContentHandler? _contentHandler;

  PlatformViewMessageHandler({
    required PlatformViewManager contentManager,
    PlatformViewContentHandler? contentHandler,
  }) : _contentManager = contentManager,
       _contentHandler = contentHandler;

  /// Handle a `create` Platform View message.
  ///
  /// This will attempt to render the `contents` and of a Platform View, if its
  /// `viewType` has been registered previously.
  ///
  /// (See [PlatformViewContentManager.registerFactory] for more details.)
  ///
  /// The `contents` are delegated to a [_contentHandler] function, so the
  /// active rendering backend can inject them in the right place of the DOM.
  ///
  /// If all goes well, this function will `callback` with an empty success envelope.
  /// In case of error, this will `callback` with an error envelope describing the error.
  void _createPlatformView(
    MethodCall methodCall,
    _PlatformMessageResponseCallback callback,
  ) {
    final Map<dynamic, dynamic> args = methodCall.arguments as Map<dynamic, dynamic>;
    final int viewId = args.readInt('id');
    final String viewType = args.readString('viewType');

    if (!_contentManager.knowsViewType(viewType)) {
      callback(_codec.encodeErrorEnvelope(
        code: 'unregistered_view_type',
        message: 'A HtmlElementView widget is trying to create a platform view '
            'with an unregistered type: <$viewType>.',
        details: 'If you are the author of the PlatformView, make sure '
            '`registerViewFactory` is invoked.',
      ));
      return;
    }

    if (_contentManager.knowsViewId(viewId)) {
      callback(_codec.encodeErrorEnvelope(
        code: 'recreating_view',
        message: 'trying to create an already created view',
        details: 'view id: $viewId',
      ));
      return;
    }

    // TODO(hterkelsen): How can users add extra `args` from the HtmlElementView widget?
    final DomElement content = _contentManager.renderContent(
      viewType,
      viewId,
      args,
    );

    // For now, we don't need anything fancier. If needed, this can be converted
    // to a PlatformViewStrategy class for each web-renderer backend?
    if (_contentHandler != null) {
      _contentHandler!(content);
    }
    callback(_codec.encodeSuccessEnvelope(null));
  }

  /// Handle a `dispose` Platform View message.
  ///
  /// This will clear the cached information that the framework has about a given
  /// `viewId`, through the [_contentManager].
  ///
  /// Once that's done, the dispose call is delegated to the [_disposeHandler]
  /// function, so the active rendering backend can dispose of whatever resources
  /// it needed to get ahold of.
  ///
  /// This function should always `callback` with an empty success envelope.
  void _disposePlatformView(
    MethodCall methodCall,
    _PlatformMessageResponseCallback callback,
  ) {
    final int viewId = methodCall.arguments as int;

    // The contentManager removes the slot and the contents from its internal
    // cache, and the DOM.
    _contentManager.clearPlatformView(viewId);

    callback(_codec.encodeSuccessEnvelope(null));
  }

  /// Handles a PlatformViewCall to the `flutter/platform_views` channel.
  ///
  /// This method handles two possible messages:
  /// * `create`: See [_createPlatformView]
  /// * `dispose`: See [_disposePlatformView]
  void handlePlatformViewCall(
    ByteData? data,
    _PlatformMessageResponseCallback callback,
  ) {
    final MethodCall decoded = _codec.decodeMethodCall(data);
    switch (decoded.method) {
      case 'create':
        _createPlatformView(decoded, callback);
        return;
      case 'dispose':
        _disposePlatformView(decoded, callback);
        return;
    }
    callback(null);
  }
}

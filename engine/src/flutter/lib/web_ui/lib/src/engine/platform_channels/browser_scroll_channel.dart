// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Platform channel for browser scroll coordination between engine and framework.
///
/// This channel allows the framework to:
/// - Enable/disable browser scrolling mode
/// - Update scroll extent when content changes
/// - Receive scroll position updates from the browser
class BrowserScrollChannel {
  /// The channel name used for browser scroll communication.
  static const String channelName = 'flutter/browserscroll';

  static const MethodCodec _codec = StandardMethodCodec();

  /// Handle incoming messages from the framework.
  static void handleMessage(ByteData? message, ui.PlatformMessageResponseCallback? callback) {
    print('[DEBUG BrowserScrollChannel] handleMessage called');

    if (message == null) {
      print('[DEBUG BrowserScrollChannel] Message is null!');
      _sendErrorResponse(callback, 'invalid_message', 'Message is null', null);
      return;
    }

    try {
      print('[DEBUG BrowserScrollChannel] Decoding method call...');
      final MethodCall methodCall = _codec.decodeMethodCall(message);
      print('[DEBUG BrowserScrollChannel] Method: ${methodCall.method}');
      print('[DEBUG BrowserScrollChannel] Arguments: ${methodCall.arguments}');

      // Convert arguments to Map<String, dynamic>
      final Map<String, dynamic> args;
      if (methodCall.arguments == null) {
        args = <String, dynamic>{};
      } else if (methodCall.arguments is Map) {
        args = Map<String, dynamic>.from(methodCall.arguments as Map);
      } else {
        _sendErrorResponse(
          callback,
          'invalid_args',
          'Arguments must be a Map, got: ${methodCall.arguments.runtimeType}',
          null,
        );
        return;
      }

      switch (methodCall.method) {
        case 'enable':
          _handleEnable(args, callback);
          break;

        case 'disable':
          _handleDisable(args, callback);
          break;

        case 'updateExtent':
          _handleUpdateExtent(args, callback);
          break;

        default:
          _sendErrorResponse(
            callback,
            'unknown_method',
            'Unknown method: ${methodCall.method}',
            null,
          );
      }
    } catch (e, stackTrace) {
      print('[DEBUG BrowserScrollChannel] Error: $e');
      print('[DEBUG BrowserScrollChannel] Stack: $stackTrace');
      _sendErrorResponse(callback, 'error', 'Error handling message: $e', null);
    }
  }

  static void _handleEnable(
    Map<String, dynamic> args,
    ui.PlatformMessageResponseCallback? callback,
  ) {
    print('[DEBUG BrowserScrollChannel] _handleEnable called with args: $args');

    final int? viewId = args['viewId'] as int?;

    if (viewId == null) {
      print('[DEBUG BrowserScrollChannel] viewId is null!');
      _sendErrorResponse(callback, 'invalid_args', 'viewId is required', null);
      return;
    }

    print('[DEBUG BrowserScrollChannel] Looking for view $viewId...');
    final EngineFlutterView? view = EnginePlatformDispatcher.instance.viewManager[viewId];

    if (view == null) {
      print('[DEBUG BrowserScrollChannel] View $viewId not found!');
      _sendErrorResponse(callback, 'view_not_found', 'View not found: $viewId', null);
      return;
    }

    print('[DEBUG BrowserScrollChannel] Calling view.enableBrowserScrolling()...');
    view.enableBrowserScrolling();
    print('[DEBUG BrowserScrollChannel] Browser scrolling enabled successfully!');
    _sendSuccessResponse(callback, true);
  }

  static void _handleDisable(
    Map<String, dynamic> args,
    ui.PlatformMessageResponseCallback? callback,
  ) {
    final int? viewId = args['viewId'] as int?;

    if (viewId == null) {
      _sendErrorResponse(callback, 'invalid_args', 'viewId is required', null);
      return;
    }

    final EngineFlutterView? view = EnginePlatformDispatcher.instance.viewManager[viewId];

    if (view == null) {
      _sendErrorResponse(callback, 'view_not_found', 'View not found: $viewId', null);
      return;
    }

    view.disableBrowserScrolling();
    _sendSuccessResponse(callback, true);
  }

  static void _handleUpdateExtent(
    Map<String, dynamic> args,
    ui.PlatformMessageResponseCallback? callback,
  ) {
    final int? viewId = args['viewId'] as int?;
    final double? height = (args['height'] as num?)?.toDouble();

    if (viewId == null || height == null) {
      _sendErrorResponse(callback, 'invalid_args', 'viewId and height are required', null);
      return;
    }

    final EngineFlutterView? view = EnginePlatformDispatcher.instance.viewManager[viewId];

    if (view == null) {
      _sendErrorResponse(callback, 'view_not_found', 'View not found: $viewId', null);
      return;
    }

    view.updateBrowserScrollExtent(height);
    _sendSuccessResponse(callback, true);
  }

  static void _sendSuccessResponse(ui.PlatformMessageResponseCallback? callback, dynamic result) {
    if (callback == null) {
      return;
    }

    final ByteData? responseData = _codec.encodeSuccessEnvelope(result);
    callback(responseData);
  }

  static void _sendErrorResponse(
    ui.PlatformMessageResponseCallback? callback,
    String code,
    String? message,
    dynamic details,
  ) {
    if (callback == null) {
      return;
    }

    final ByteData? responseData = _codec.encodeErrorEnvelope(
      code: code,
      message: message,
      details: details,
    );
    callback(responseData);
  }
}

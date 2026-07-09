// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'message_codecs.dart';
import 'platform_channel.dart';

/// A binary [MethodChannel] for handling content insertion from IMEs.
///
/// This channel uses [StandardMethodCodec] for efficient binary data transfer,
/// avoiding the performance overhead of JSON serialization for large files.
///
/// See also:
///
///  * [KeyboardInsertedContent], which represents the data received on this channel.
class ContentInsertionChannel {
  /// Creates a [ContentInsertionChannel].
  ///
  /// This channel is used internally by Flutter to handle content insertion
  /// from input method editors (IMEs) to text input fields.
  ContentInsertionChannel() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel = MethodChannel(
    'flutter/contentinsertion',
    StandardMethodCodec(),
  );

  /// Callback type for content insertion events.
  ///
  /// The callback receives a map containing:
  /// - 'mimeType': String - the MIME type of the inserted content
  /// - 'uri': String - the URI of the content (if available)
  /// - 'data': Uint8List - the raw bytes of the content (if available)
  late void Function(Map<String, dynamic>)? _onContentInserted;

  /// Sets the callback to be invoked when content is inserted.
  ///
  /// The callback receives a map with the content details.
  void setContentInsertionCallback(
    void Function(Map<String, dynamic>)? callback,
  ) {
    _onContentInserted = callback;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'commitContent':
        final Map<dynamic, dynamic> arguments = call.arguments as Map<dynamic, dynamic>;
        final Map<String, dynamic> contentMap = <String, dynamic>{
          'mimeType': arguments['mimeType'] as String,
          'uri': arguments['uri'] as String,
          if (arguments.containsKey('data'))
            'data': arguments['data'] as Uint8List?,
        };
        _onContentInserted?.call(contentMap);
      default:
        throw MissingPluginException();
    }
  }
}

/// Singleton instance of [ContentInsertionChannel].
final ContentInsertionChannel _contentInsertionChannel = ContentInsertionChannel();

/// Gets the singleton [ContentInsertionChannel] instance.
ContentInsertionChannel get contentInsertionChannel => _contentInsertionChannel;

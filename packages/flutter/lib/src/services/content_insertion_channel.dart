// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'message_codecs.dart';
library;

import 'dart:typed_data';

import 'keyboard_inserted_content.dart';
import 'message_codec.dart';
import 'platform_channel.dart';

/// A binary [MethodChannel] for handling content insertion from IMEs.
///
/// [MethodChannel] uses [StandardMethodCodec] by default, which encodes byte
/// arrays ([Uint8List]) as length-prefixed blobs. This avoids the per-byte JSON
/// serialization overhead of the `flutter/textinput` channel, which uses
/// [JSONMethodCodec] and serializes large content (such as images) element by
/// element.
///
/// See also:
///
///  * [KeyboardInsertedContent], which represents the data received on this channel.
///  * <https://github.com/flutter/flutter/issues/188977>, the performance issue
///    that motivated this channel.
class ContentInsertionChannel {
  /// Creates a [ContentInsertionChannel].
  ///
  /// This channel is used internally by Flutter to handle content insertion
  /// from input method editors (IMEs) to text input fields.
  ContentInsertionChannel._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel = MethodChannel('flutter/contentinsertion');

  /// Called when content is inserted on the binary content insertion channel.
  set onContentInserted(void Function(KeyboardInsertedContent content)? callback) {
    _onContentInserted = callback;
  }

  void Function(KeyboardInsertedContent content)? _onContentInserted;

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'commitContent':
        final Map<String, dynamic> arguments = (call.arguments as Map<dynamic, dynamic>)
            .cast<String, dynamic>();
        if (_onContentInserted != null) {
          _onContentInserted!(KeyboardInsertedContent.fromBinary(arguments));
        }
      default:
        throw MissingPluginException();
    }
  }
}

/// The singleton [ContentInsertionChannel] instance.
final ContentInsertionChannel contentInsertionChannel = ContentInsertionChannel._();

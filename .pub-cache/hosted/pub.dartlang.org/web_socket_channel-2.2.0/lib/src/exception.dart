// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'channel.dart';

/// An exception thrown by a [WebSocketChannel].
class WebSocketChannelException implements Exception {
  final String? message;

  /// The exception that caused this one, if available.
  final Object? inner;

  WebSocketChannelException([this.message]) : inner = null;

  WebSocketChannelException.from(this.inner) : message = inner.toString();

  @override
  String toString() => message == null
      ? 'WebSocketChannelException'
      : 'WebSocketChannelException: $message';
}

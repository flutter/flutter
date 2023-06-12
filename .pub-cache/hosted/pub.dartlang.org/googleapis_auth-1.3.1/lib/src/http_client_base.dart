// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart';

/// Base class for delegating HTTP clients.
///
/// Depending on [closeUnderlyingClient] it will close the client it is
/// delegating to or not.
abstract class DelegatingClient extends BaseClient {
  final Client baseClient;
  final bool closeUnderlyingClient;
  bool _isClosed = false;

  DelegatingClient(this.baseClient, {this.closeUnderlyingClient = true});

  @override
  void close() {
    if (_isClosed) {
      throw StateError('Cannot close a HTTP client more than once.');
    }
    _isClosed = true;
    super.close();

    if (closeUnderlyingClient) {
      baseClient.close();
    }
  }
}

/// A reference counted HTTP client.
///
/// It uses a base [Client] which will be closed once the reference count
/// reaches zero. The initial reference count is one, since the caller has a
/// reference to the constructed instance.
class RefCountedClient extends DelegatingClient {
  int _refCount;

  RefCountedClient(Client baseClient, {int initialRefCount = 1})
      : _refCount = initialRefCount,
        super(baseClient, closeUnderlyingClient: true);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    _ensureClientIsOpen();
    return baseClient.send(request);
  }

  /// Acquires a new reference which causes the reference count to be
  /// incremented by 1.
  void acquire() {
    _ensureClientIsOpen();
    _refCount++;
  }

  /// Releases a new reference which causes the reference count to be
  /// decremented by 1.
  void release() {
    _ensureClientIsOpen();
    _refCount--;

    if (_refCount == 0) {
      super.close();
    }
  }

  /// Is equivalent to calling `release`.
  @override
  void close() {
    release();
  }

  void _ensureClientIsOpen() {
    if (_refCount <= 0) {
      throw StateError(
        'This reference counted HTTP client has reached a count of zero and '
        'can no longer be used for making HTTP requests.',
      );
    }
  }
}

// NOTE:
// Calling close on the returned client once will not close the underlying
// [baseClient].
Client nonClosingClient(Client baseClient) =>
    RefCountedClient(baseClient, initialRefCount: 2);

class RequestImpl extends BaseRequest {
  final Stream<List<int>> _stream;

  RequestImpl(String method, Uri url, [Stream<List<int>>? stream])
      : _stream = stream ?? const Stream.empty(),
        super(method, url);

  @override
  ByteStream finalize() {
    super.finalize();
    return ByteStream(_stream);
  }
}

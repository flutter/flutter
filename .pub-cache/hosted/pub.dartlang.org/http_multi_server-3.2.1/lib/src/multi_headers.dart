// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A class that delegates header access and setting to many [HttpHeaders]
/// instances.
class MultiHeaders implements HttpHeaders {
  /// The wrapped headers.
  final Set<HttpHeaders> _headers;

  @override
  bool get chunkedTransferEncoding => _headers.first.chunkedTransferEncoding;
  @override
  set chunkedTransferEncoding(bool value) {
    for (var headers in _headers) {
      headers.chunkedTransferEncoding = value;
    }
  }

  @override
  int get contentLength => _headers.first.contentLength;
  @override
  set contentLength(int value) {
    for (var headers in _headers) {
      headers.contentLength = value;
    }
  }

  @override
  ContentType? get contentType => _headers.first.contentType;
  @override
  set contentType(ContentType? value) {
    for (var headers in _headers) {
      headers.contentType = value;
    }
  }

  @override
  DateTime? get date => _headers.first.date;
  @override
  set date(DateTime? value) {
    for (var headers in _headers) {
      headers.date = value;
    }
  }

  @override
  DateTime? get expires => _headers.first.expires;
  @override
  set expires(DateTime? value) {
    for (var headers in _headers) {
      headers.expires = value;
    }
  }

  @override
  String? get host => _headers.first.host;
  @override
  set host(String? value) {
    for (var headers in _headers) {
      headers.host = value;
    }
  }

  @override
  DateTime? get ifModifiedSince => _headers.first.ifModifiedSince;
  @override
  set ifModifiedSince(DateTime? value) {
    for (var headers in _headers) {
      headers.ifModifiedSince = value;
    }
  }

  @override
  bool get persistentConnection => _headers.first.persistentConnection;
  @override
  set persistentConnection(bool value) {
    for (var headers in _headers) {
      headers.persistentConnection = value;
    }
  }

  @override
  int? get port => _headers.first.port;
  @override
  set port(int? value) {
    for (var headers in _headers) {
      headers.port = value;
    }
  }

  MultiHeaders(Iterable<HttpHeaders> headers) : _headers = headers.toSet();

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    for (var headers in _headers) {
      headers.add(name, value, preserveHeaderCase: preserveHeaderCase);
    }
  }

  @override
  void forEach(void Function(String name, List<String> values) f) =>
      _headers.first.forEach(f);

  @override
  void noFolding(String name) {
    for (var headers in _headers) {
      headers.noFolding(name);
    }
  }

  @override
  void remove(String name, Object value) {
    for (var headers in _headers) {
      headers.remove(name, value);
    }
  }

  @override
  void removeAll(String name) {
    for (var headers in _headers) {
      headers.removeAll(name);
    }
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    for (var headers in _headers) {
      headers.set(name, value, preserveHeaderCase: preserveHeaderCase);
    }
  }

  @override
  String? value(String name) => _headers.first.value(name);

  @override
  List<String>? operator [](String name) => _headers.first[name];

  @override
  void clear() {
    for (var headers in _headers) {
      headers.clear();
    }
  }
}

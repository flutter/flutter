// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sync.http;

/// A simple synchronous HTTP client.
///
/// This is a two-step process. When a [SyncHttpClientRequest] is returned the
/// underlying network connection has been established, but no data has yet been
/// sent. The HTTP headers and body can be set on the request, and close is
/// called to send it to the server and get the [SyncHttpClientResponse].
abstract class SyncHttpClient {
  /// Send a GET request to the provided URL.
  static SyncHttpClientRequest getUrl(Uri uri) =>
      SyncHttpClientRequest._('GET', uri, false);

  /// Send a POST request to the provided URL.
  static SyncHttpClientRequest postUrl(Uri uri) =>
      SyncHttpClientRequest._('POST', uri, true);

  /// Send a DELETE request to the provided URL.
  static SyncHttpClientRequest deleteUrl(Uri uri) =>
      SyncHttpClientRequest._('DELETE', uri, false);

  /// Send a PUT request to the provided URL.
  static SyncHttpClientRequest putUrl(Uri uri) =>
      SyncHttpClientRequest._('PUT', uri, true);
}

/// HTTP request for a synchronous client connection.
class SyncHttpClientRequest {
  static const String _protocolVersion = '1.1';

  /// The length of the request body. Is set to `-1` when no body exists.
  int get contentLength => hasBody ? _body!.length : -1;

  HttpHeaders? _headers;

  /// The headers associated with the HTTP request.
  HttpHeaders get headers => _headers ??= _SyncHttpClientRequestHeaders(this);

  /// The type of HTTP request being made.
  final String method;

  /// The Uri the HTTP request will be sent to.
  final Uri uri;

  /// The default encoding for the HTTP request (UTF8).
  final Encoding encoding = utf8;

  /// The body of the HTTP request. This can be empty if there is no body
  /// associated with the request.
  final BytesBuilder? _body;

  /// The synchronous socket used to initiate the HTTP request.
  final RawSynchronousSocket _socket;

  SyncHttpClientRequest._(this.method, this.uri, bool body)
      : _body = body ? BytesBuilder() : null,
        _socket = RawSynchronousSocket.connectSync(uri.host, uri.port);

  /// Write content into the body of the HTTP request.
  void write(Object? obj) {
    if (hasBody) {
      if (obj != null) {
        _body!.add(encoding.encoder.convert(obj.toString()));
      }
    } else {
      throw StateError('write not allowed for method $method');
    }
  }

  /// Specifies whether or not the HTTP request has a body.
  bool get hasBody => _body != null;

  /// Send the HTTP request and get the response.
  SyncHttpClientResponse close() {
    var queryString = '';
    if (uri.hasQuery) {
      var query = StringBuffer();
      query.write('?');
      uri.queryParameters.forEach((k, v) {
        query.write(Uri.encodeComponent(k));
        query.write('=');
        query.write(Uri.encodeComponent(v));
        query.write('&');
      });
      queryString = query.toString().substring(0, query.length - 1);
    }
    var buffer = StringBuffer();
    buffer.write('$method ${uri.path}$queryString HTTP/$_protocolVersion\r\n');
    headers.forEach((name, values) {
      for (var value in values) {
        buffer.write('$name: $value\r\n');
      }
    });
    buffer.write('\r\n');
    if (hasBody) {
      buffer.write(String.fromCharCodes(_body!.takeBytes()));
    }
    _socket.writeFromSync(buffer.toString().codeUnits);
    return SyncHttpClientResponse(_socket);
  }
}

class _SyncHttpClientRequestHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = <String, List<String>>{};

  final SyncHttpClientRequest _request;
  @override
  ContentType? contentType;

  _SyncHttpClientRequestHeaders(this._request);

  @override
  List<String>? operator [](String name) {
    switch (name) {
      case HttpHeaders.acceptCharsetHeader:
        return ['utf-8'];
      case HttpHeaders.acceptEncodingHeader:
        return ['identity'];
      case HttpHeaders.connectionHeader:
        return ['close'];
      case HttpHeaders.contentLengthHeader:
        if (!_request.hasBody) {
          return null;
        }
        return [contentLength.toString()];
      case HttpHeaders.contentTypeHeader:
        if (contentType == null) {
          return null;
        }
        return [contentType.toString()];
      case HttpHeaders.hostHeader:
        return ['$host:$port'];
      default:
        var values = _headers[name];
        if (values == null || values.isEmpty) {
          return null;
        }
        return values.map<String>((e) => e.toString()).toList(growable: false);
    }
  }

  /// Add [value] to the list of values associated with header [name].
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    switch (name) {
      case HttpHeaders.acceptCharsetHeader:
      case HttpHeaders.acceptEncodingHeader:
      case HttpHeaders.connectionHeader:
      case HttpHeaders.contentLengthHeader:
      case HttpHeaders.dateHeader:
      case HttpHeaders.expiresHeader:
      case HttpHeaders.ifModifiedSinceHeader:
      case HttpHeaders.hostHeader:
        throw UnsupportedError('Unsupported or immutable property: $name');
      case HttpHeaders.contentTypeHeader:
        contentType = value as ContentType?;
        break;
      default:
        if (_headers[name] == null) {
          _headers[name] = <String>[];
        }
        _headers[name]!.add(value as String);
    }
  }

  /// Remove [value] from the list associated with header [name].
  @override
  void remove(String name, Object value) {
    switch (name) {
      case HttpHeaders.acceptCharsetHeader:
      case HttpHeaders.acceptEncodingHeader:
      case HttpHeaders.connectionHeader:
      case HttpHeaders.contentLengthHeader:
      case HttpHeaders.dateHeader:
      case HttpHeaders.expiresHeader:
      case HttpHeaders.ifModifiedSinceHeader:
      case HttpHeaders.hostHeader:
        throw UnsupportedError('Unsupported or immutable property: $name');
      case HttpHeaders.contentTypeHeader:
        if (contentType == value) {
          contentType = null;
        }
        break;
      default:
        if (_headers[name] != null) {
          _headers[name]!.remove(value);
          if (_headers[name]!.isEmpty) {
            _headers.remove(name);
          }
        }
    }
  }

  /// Remove all headers associated with key [name].
  @override
  void removeAll(String name) {
    switch (name) {
      case HttpHeaders.acceptCharsetHeader:
      case HttpHeaders.acceptEncodingHeader:
      case HttpHeaders.connectionHeader:
      case HttpHeaders.contentLengthHeader:
      case HttpHeaders.dateHeader:
      case HttpHeaders.expiresHeader:
      case HttpHeaders.ifModifiedSinceHeader:
      case HttpHeaders.hostHeader:
        throw UnsupportedError('Unsupported or immutable property: $name');
      case HttpHeaders.contentTypeHeader:
        contentType = null;
        break;
      default:
        _headers.remove(name);
    }
  }

  /// Replace values associated with key [name] with [value].
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    removeAll(name);
    add(name, value, preserveHeaderCase: preserveHeaderCase);
  }

  /// Returns the values associated with key [name], if it exists, otherwise
  /// returns null.
  @override
  String? value(String name) {
    var val = this[name];
    if (val == null || val.isEmpty) {
      return null;
    } else if (val.length == 1) {
      return val[0];
    } else {
      throw HttpException('header $name has more than one value');
    }
  }

  /// Iterates over all header key-value pairs and applies [f].
  @override
  void forEach(void Function(String name, List<String> values) f) {
    void forEachFunc(String name) {
      var values = this[name];
      if (values != null && values.isNotEmpty) {
        f(name, values);
      }
    }

    [
      HttpHeaders.acceptCharsetHeader,
      HttpHeaders.acceptEncodingHeader,
      HttpHeaders.connectionHeader,
      HttpHeaders.contentLengthHeader,
      HttpHeaders.contentTypeHeader,
      HttpHeaders.hostHeader
    ].forEach(forEachFunc);
    _headers.keys.forEach(forEachFunc);
  }

  @override
  bool get chunkedTransferEncoding =>
      value(HttpHeaders.transferEncodingHeader)?.toLowerCase() == 'chunked';

  @override
  set chunkedTransferEncoding(bool _chunkedTransferEncoding) {
    throw UnsupportedError('chunked transfer is unsupported');
  }

  @override
  int get contentLength => _request.contentLength;

  @override
  set contentLength(int _contentLength) {
    throw UnsupportedError('content length is automatically set');
  }

  @override
  set date(DateTime? _date) {
    throw UnsupportedError('date is unsupported');
  }

  @override
  DateTime? get date => null;

  @override
  set expires(DateTime? _expires) {
    throw UnsupportedError('expires is unsupported');
  }

  @override
  DateTime? get expires => null;

  @override
  set host(String? _host) {
    throw UnsupportedError('host is automatically set');
  }

  @override
  String get host => _request.uri.host;

  @override
  DateTime? get ifModifiedSince => null;

  @override
  set ifModifiedSince(DateTime? _ifModifiedSince) {
    throw UnsupportedError('if modified since is unsupported');
  }

  @override
  void noFolding(String name) {
    throw UnsupportedError('no folding is unsupported');
  }

  @override
  bool get persistentConnection => false;

  @override
  set persistentConnection(bool _persistentConnection) {
    throw UnsupportedError('persistence connections are unsupported');
  }

  @override
  set port(int? _port) {
    throw UnsupportedError('port is automatically set');
  }

  @override
  int get port => _request.uri.port;

  /// Clear all header key-value pairs.
  @override
  void clear() {
    contentType = null;
    _headers.clear();
  }
}

/// HTTP response for a client connection.
class SyncHttpClientResponse {
  /// The length of the body associated with the HTTP response.
  int get contentLength => headers.contentLength;

  /// The headers associated with the HTTP response.
  final HttpHeaders headers;

  /// A short textual description of the status code associated with the HTTP
  /// response.
  final String? reasonPhrase;

  /// The resulting HTTP status code associated with the HTTP response.
  final int? statusCode;

  /// The body of the HTTP response.
  final String? body;

  /// Creates an instance of [SyncHttpClientResponse] that contains the response
  /// sent by the HTTP server over [socket].
  factory SyncHttpClientResponse(RawSynchronousSocket socket) {
    int? statusCode;
    String? reasonPhrase;
    var body = StringBuffer();
    var headers = <String, List<String>>{};

    var inHeader = false;
    var inBody = false;
    var contentLength = 0;
    var contentRead = 0;

    void processLine(String line, int bytesRead, _LineDecoder decoder) {
      if (inBody) {
        body.write(line);
        contentRead += bytesRead;
      } else if (inHeader) {
        if (line.trim().isEmpty) {
          inBody = true;
          if (contentLength > 0) {
            decoder.expectedByteCount = contentLength;
          }
          return;
        }
        var separator = line.indexOf(':');
        var name = line.substring(0, separator).toLowerCase().trim();
        var value = line.substring(separator + 1).trim();
        if (name == HttpHeaders.transferEncodingHeader &&
            value.toLowerCase() != 'identity') {
          throw UnsupportedError('only identity transfer encoding is accepted');
        }
        if (name == HttpHeaders.contentLengthHeader) {
          contentLength = int.parse(value);
        }
        if (!headers.containsKey(name)) {
          headers[name] = [];
        }
        headers[name]!.add(value);
      } else if (line.startsWith('HTTP/1.1') || line.startsWith('HTTP/1.0')) {
        statusCode = int.parse(
            line.substring('HTTP/1.x '.length, 'HTTP/1.x xxx'.length));
        reasonPhrase = line.substring('HTTP/1.x xxx '.length);
        inHeader = true;
      } else {
        throw UnsupportedError('unsupported http response format');
      }
    }

    var lineDecoder = _LineDecoder.withCallback(processLine);

    try {
      while (!inHeader ||
          !inBody ||
          ((contentRead + lineDecoder.bufferedBytes) < contentLength)) {
        var bytes = socket.readSync(1024);

        if (bytes == null || bytes.isEmpty) {
          break;
        }
        lineDecoder.add(bytes);
      }
    } finally {
      try {
        lineDecoder.close();
      } finally {
        socket.closeSync();
      }
    }

    return SyncHttpClientResponse._(headers,
        reasonPhrase: reasonPhrase,
        statusCode: statusCode,
        body: body.toString());
  }

  SyncHttpClientResponse._(Map<String, List<String>> headers,
      {this.reasonPhrase, this.statusCode, this.body})
      : headers = _SyncHttpClientResponseHeaders(headers);
}

class _SyncHttpClientResponseHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers;

  _SyncHttpClientResponseHeaders(this._headers);

  @override
  List<String>? operator [](String name) => _headers[name];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  bool get chunkedTransferEncoding =>
      value(HttpHeaders.transferEncodingHeader)?.toLowerCase() == 'chunked';

  @override
  set chunkedTransferEncoding(bool _chunkedTransferEncoding) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  int get contentLength {
    var val = value(HttpHeaders.contentLengthHeader);
    if (val != null) {
      var parsed = int.tryParse(val);
      if (parsed != null) {
        return parsed;
      }
    }
    return -1;
  }

  @override
  set contentLength(int _contentLength) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  ContentType? get contentType {
    var val = value(HttpHeaders.contentTypeHeader);
    if (val != null) {
      return ContentType.parse(val);
    }
    return null;
  }

  @override
  set contentType(ContentType? _contentType) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  set date(DateTime? _date) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  DateTime? get date {
    var val = value(HttpHeaders.dateHeader);
    if (val != null) {
      return DateTime.parse(val);
    }
    return null;
  }

  @override
  set expires(DateTime? _expires) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  DateTime? get expires {
    var val = value(HttpHeaders.expiresHeader);
    if (val != null) {
      return DateTime.parse(val);
    }
    return null;
  }

  @override
  void forEach(void Function(String name, List<String> values) f) =>
      _headers.forEach(f);

  @override
  set host(String? _host) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  String? get host {
    var val = value(HttpHeaders.hostHeader);
    if (val != null) {
      return Uri.parse(val).host;
    }
    return null;
  }

  @override
  DateTime? get ifModifiedSince {
    var val = value(HttpHeaders.ifModifiedSinceHeader);
    if (val != null) {
      return DateTime.parse(val);
    }
    return null;
  }

  @override
  set ifModifiedSince(DateTime? _ifModifiedSince) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  void noFolding(String name) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  bool get persistentConnection => false;

  @override
  set persistentConnection(bool _persistentConnection) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  set port(int? _port) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  int? get port {
    var val = value(HttpHeaders.hostHeader);
    if (val != null) {
      return Uri.parse(val).port;
    }
    return null;
  }

  @override
  void remove(String name, Object value) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  void removeAll(String name) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    throw UnsupportedError('Response headers are immutable');
  }

  @override
  String? value(String name) {
    var val = this[name];
    if (val == null || val.isEmpty) {
      return null;
    } else if (val.length == 1) {
      return val[0];
    } else {
      throw HttpException('header $name has more than one value');
    }
  }

  @override
  void clear() {
    throw UnsupportedError('Response headers are immutable');
  }
}

// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'dart:collection';

import '_exports_in_browser.dart';

final _digitsValidator = RegExp(r"^\d+$");

class HttpHeadersImpl implements HttpHeaders {
  final Map<String, List<String>> _headers;
  // The original header names keyed by the lowercase header names.
  Map<String, String>? _originalHeaderNames;
  final String protocolVersion;

  bool _mutable = true; // Are the headers currently mutable?
  List<String>? _noFoldingHeaders;

  int _contentLength = -1;
  bool _persistentConnection = true;
  bool _chunkedTransferEncoding = false;
  String? _host;
  int? _port;

  final int _defaultPortForScheme;

  HttpHeadersImpl(this.protocolVersion,
      {int defaultPortForScheme = HttpClient.defaultHttpPort,
      HttpHeadersImpl? initialHeaders})
      : _headers = HashMap<String, List<String>>(),
        _defaultPortForScheme = defaultPortForScheme {
    if (initialHeaders != null) {
      initialHeaders._headers.forEach((name, value) => _headers[name] = value);
      _contentLength = initialHeaders._contentLength;
      _persistentConnection = initialHeaders._persistentConnection;
      _chunkedTransferEncoding = initialHeaders._chunkedTransferEncoding;
      _host = initialHeaders._host;
      _port = initialHeaders._port;
    }
    if (protocolVersion == "1.0") {
      _persistentConnection = false;
      _chunkedTransferEncoding = false;
    }
  }

  @override
  bool get chunkedTransferEncoding => _chunkedTransferEncoding;

  @override
  set chunkedTransferEncoding(bool chunkedTransferEncoding) {
    _checkMutable();
    if (chunkedTransferEncoding && protocolVersion == "1.0") {
      throw HttpException(
          "Trying to set 'Transfer-Encoding: Chunked' on HTTP 1.0 headers");
    }
    if (chunkedTransferEncoding == _chunkedTransferEncoding) return;
    if (chunkedTransferEncoding) {
      List<String>? values = _headers[HttpHeaders.transferEncodingHeader];
      if (values == null || !values.contains("chunked")) {
        // Headers does not specify chunked encoding - add it if set.
        _addValue(HttpHeaders.transferEncodingHeader, "chunked");
      }
      contentLength = -1;
    } else {
      // Headers does specify chunked encoding - remove it if not set.
      remove(HttpHeaders.transferEncodingHeader, "chunked");
    }
    _chunkedTransferEncoding = chunkedTransferEncoding;
  }

  @override
  int get contentLength => _contentLength;

  @override
  set contentLength(int contentLength) {
    _checkMutable();
    if (protocolVersion == "1.0" &&
        persistentConnection &&
        contentLength == -1) {
      throw HttpException(
          "Trying to clear ContentLength on HTTP 1.0 headers with "
          "'Connection: Keep-Alive' set");
    }
    if (_contentLength == contentLength) return;
    _contentLength = contentLength;
    if (_contentLength >= 0) {
      if (chunkedTransferEncoding) chunkedTransferEncoding = false;
      _set(HttpHeaders.contentLengthHeader, contentLength.toString());
    } else {
      _headers.remove(HttpHeaders.contentLengthHeader);
      if (protocolVersion == "1.1") {
        chunkedTransferEncoding = true;
      }
    }
  }

  @override
  ContentType? get contentType {
    var values = _headers[HttpHeaders.contentTypeHeader];
    if (values != null) {
      return ContentType.parse(values[0]);
    } else {
      return null;
    }
  }

  @override
  set contentType(ContentType? contentType) {
    _checkMutable();
    if (contentType == null) {
      _headers.remove(HttpHeaders.contentTypeHeader);
    } else {
      _set(HttpHeaders.contentTypeHeader, contentType.toString());
    }
  }

  @override
  DateTime? get date {
    List<String>? values = _headers[HttpHeaders.dateHeader];
    if (values != null) {
      assert(values.isNotEmpty);
      try {
        return HttpDate.parse(values[0]);
      } on Exception {
        return null;
      }
    }
    return null;
  }

  @override
  set date(DateTime? date) {
    _checkMutable();
    if (date == null) {
      _headers.remove(HttpHeaders.dateHeader);
    } else {
      // Format "DateTime" header with date in Greenwich Mean Time (GMT).
      String formatted = HttpDate.format(date.toUtc());
      _set(HttpHeaders.dateHeader, formatted);
    }
  }

  @override
  DateTime? get expires {
    List<String>? values = _headers[HttpHeaders.expiresHeader];
    if (values != null) {
      assert(values.isNotEmpty);
      try {
        return HttpDate.parse(values[0]);
      } on Exception {
        return null;
      }
    }
    return null;
  }

  @override
  set expires(DateTime? expires) {
    _checkMutable();
    if (expires == null) {
      _headers.remove(HttpHeaders.expiresHeader);
    } else {
      // Format "Expires" header with date in Greenwich Mean Time (GMT).
      String formatted = HttpDate.format(expires.toUtc());
      _set(HttpHeaders.expiresHeader, formatted);
    }
  }

  @override
  String? get host => _host;

  @override
  set host(String? host) {
    _checkMutable();
    _host = host;
    _updateHostHeader();
  }

  @override
  DateTime? get ifModifiedSince {
    List<String>? values = _headers[HttpHeaders.ifModifiedSinceHeader];
    if (values != null) {
      assert(values.isNotEmpty);
      try {
        return HttpDate.parse(values[0]);
      } on Exception {
        return null;
      }
    }
    return null;
  }

  @override
  set ifModifiedSince(DateTime? ifModifiedSince) {
    _checkMutable();
    if (ifModifiedSince == null) {
      _headers.remove(HttpHeaders.ifModifiedSinceHeader);
    } else {
      // Format "ifModifiedSince" header with date in Greenwich Mean Time (GMT).
      String formatted = HttpDate.format(ifModifiedSince.toUtc());
      _set(HttpHeaders.ifModifiedSinceHeader, formatted);
    }
  }

  @override
  bool get persistentConnection => _persistentConnection;

  @override
  set persistentConnection(bool persistentConnection) {
    _checkMutable();
    if (persistentConnection == _persistentConnection) return;
    final originalName = _originalHeaderName(HttpHeaders.connectionHeader);
    if (persistentConnection) {
      if (protocolVersion == "1.1") {
        remove(HttpHeaders.connectionHeader, "close");
      } else {
        if (_contentLength < 0) {
          throw HttpException(
              "Trying to set 'Connection: Keep-Alive' on HTTP 1.0 headers with "
              "no ContentLength");
        }
        add(originalName, "keep-alive", preserveHeaderCase: true);
      }
    } else {
      if (protocolVersion == "1.1") {
        add(originalName, "close", preserveHeaderCase: true);
      } else {
        remove(HttpHeaders.connectionHeader, "keep-alive");
      }
    }
    _persistentConnection = persistentConnection;
  }

  @override
  int? get port => _port;

  @override
  set port(int? port) {
    _checkMutable();
    _port = port;
    _updateHostHeader();
  }

  @override
  List<String>? operator [](String name) => _headers[_validateField(name)];

  @override
  void add(String name, value, {bool preserveHeaderCase = false}) {
    _checkMutable();
    String lowercaseName = _validateField(name);

    if (preserveHeaderCase && name != lowercaseName) {
      (_originalHeaderNames ??= {})[lowercaseName] = name;
    } else {
      _originalHeaderNames?.remove(lowercaseName);
    }
    _addAll(lowercaseName, value);
  }

  void build(BytesBuilder builder, {bool skipZeroContentLength = false}) {
    // per https://tools.ietf.org/html/rfc7230#section-3.3.2
    // A user agent SHOULD NOT send a
    // Content-Length header field when the request message does not
    // contain a payload body and the method semantics do not anticipate
    // such a body.
    String? ignoreHeader = _contentLength == 0 && skipZeroContentLength
        ? HttpHeaders.contentLengthHeader
        : null;
    _headers.forEach((String name, List<String> values) {
      if (ignoreHeader == name) {
        return;
      }
      String originalName = _originalHeaderName(name);
      bool fold = _foldHeader(name);
      var nameData = originalName.codeUnits;
      builder.add(nameData);
      builder.addByte(_CharCode.colon);
      builder.addByte(_CharCode.sp);
      for (int i = 0; i < values.length; i++) {
        if (i > 0) {
          if (fold) {
            builder.addByte(_CharCode.comma);
            builder.addByte(_CharCode.sp);
          } else {
            builder.addByte(_CharCode.cr);
            builder.addByte(_CharCode.lf);
            builder.add(nameData);
            builder.addByte(_CharCode.colon);
            builder.addByte(_CharCode.sp);
          }
        }
        builder.add(values[i].codeUnits);
      }
      builder.addByte(_CharCode.cr);
      builder.addByte(_CharCode.lf);
    });
  }

  @override
  void clear() {
    _checkMutable();
    _headers.clear();
    _contentLength = -1;
    _persistentConnection = true;
    _chunkedTransferEncoding = false;
    _host = null;
    _port = null;
  }

  void finalize() {
    _mutable = false;
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach((String name, List<String> values) {
      String originalName = _originalHeaderName(name);
      action(originalName, values);
    });
  }

  @override
  void noFolding(String name) {
    name = _validateField(name);
    (_noFoldingHeaders ??= <String>[]).add(name);
  }

  @override
  void remove(String name, Object value) {
    _checkMutable();
    name = _validateField(name);
    value = _validateValue(value);
    List<String>? values = _headers[name];
    if (values != null) {
      values.remove(_valueToString(value));
      if (values.isEmpty) {
        _headers.remove(name);
        _originalHeaderNames?.remove(name);
      }
    }
    if (name == HttpHeaders.transferEncodingHeader && value == "chunked") {
      _chunkedTransferEncoding = false;
    }
  }

  @override
  void removeAll(String name) {
    _checkMutable();
    name = _validateField(name);
    _headers.remove(name);
    _originalHeaderNames?.remove(name);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _checkMutable();
    String lowercaseName = _validateField(name);
    _headers.remove(lowercaseName);
    _originalHeaderNames?.remove(lowercaseName);
    if (lowercaseName == HttpHeaders.contentLengthHeader) {
      _contentLength = -1;
    }
    if (lowercaseName == HttpHeaders.transferEncodingHeader) {
      _chunkedTransferEncoding = false;
    }
    if (preserveHeaderCase && name != lowercaseName) {
      (_originalHeaderNames ??= {})[lowercaseName] = name;
    }
    _addAll(lowercaseName, value);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    _headers.forEach((String name, List<String> values) {
      String originalName = _originalHeaderName(name);
      sb
        ..write(originalName)
        ..write(": ");
      bool fold = _foldHeader(name);
      for (int i = 0; i < values.length; i++) {
        if (i > 0) {
          if (fold) {
            sb.write(", ");
          } else {
            sb
              ..write("\n")
              ..write(originalName)
              ..write(": ");
          }
        }
        sb.write(values[i]);
      }
      sb.write("\n");
    });
    return sb.toString();
  }

  @override
  String? value(String name) {
    name = _validateField(name);
    List<String>? values = _headers[name];
    if (values == null) return null;
    assert(values.isNotEmpty);
    if (values.length > 1) {
      throw HttpException("More than one value for header $name");
    }
    return values[0];
  }

  // [name] must be a lower-case version of the name.
  void _add(String name, value) {
    assert(name == _validateField(name));
    // Use the length as index on what method to call. This is notable
    // faster than computing hash and looking up in a hash-map.
    switch (name.length) {
      case 4:
        if (HttpHeaders.dateHeader == name) {
          _addDate(name, value);
          return;
        }
        if (HttpHeaders.hostHeader == name) {
          _addHost(name, value);
          return;
        }
        break;
      case 7:
        if (HttpHeaders.expiresHeader == name) {
          _addExpires(name, value);
          return;
        }
        break;
      case 10:
        if (HttpHeaders.connectionHeader == name) {
          _addConnection(name, value);
          return;
        }
        break;
      case 12:
        if (HttpHeaders.contentTypeHeader == name) {
          _addContentType(name, value);
          return;
        }
        break;
      case 14:
        if (HttpHeaders.contentLengthHeader == name) {
          _addContentLength(name, value);
          return;
        }
        break;
      case 17:
        if (HttpHeaders.transferEncodingHeader == name) {
          _addTransferEncoding(name, value);
          return;
        }
        if (HttpHeaders.ifModifiedSinceHeader == name) {
          _addIfModifiedSince(name, value);
          return;
        }
    }
    _addValue(name, value);
  }

  void _addAll(String name, value) {
    if (value is Iterable) {
      for (var v in value) {
        _add(name, _validateValue(v));
      }
    } else {
      _add(name, _validateValue(value));
    }
  }

  void _addConnection(String name, String value) {
    var lowerCaseValue = value.toLowerCase();
    if (lowerCaseValue == 'close') {
      _persistentConnection = false;
    } else if (lowerCaseValue == 'keep-alive') {
      _persistentConnection = true;
    }
    _addValue(name, value);
  }

  void _addContentLength(String name, value) {
    if (value is int) {
      if (value < 0) {
        throw HttpException("Content-Length must contain only digits");
      }
    } else if (value is String) {
      if (!_digitsValidator.hasMatch(value)) {
        throw HttpException("Content-Length must contain only digits");
      }
      value = int.parse(value);
    } else {
      throw HttpException("Unexpected type for header named $name");
    }
    contentLength = value;
  }

  void _addContentType(String name, value) {
    _set(HttpHeaders.contentTypeHeader, value);
  }

  void _addDate(String name, value) {
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      _set(HttpHeaders.dateHeader, value);
    } else {
      throw HttpException("Unexpected type for header named $name");
    }
  }

  void _addExpires(String name, value) {
    if (value is DateTime) {
      expires = value;
    } else if (value is String) {
      _set(HttpHeaders.expiresHeader, value);
    } else {
      throw HttpException("Unexpected type for header named $name");
    }
  }

  void _addHost(String name, value) {
    if (value is String) {
      // value.indexOf will only work for ipv4, ipv6 which has multiple : in its
      // host part needs lastIndexOf
      int pos = value.lastIndexOf(":");
      // According to RFC 3986, section 3.2.2, host part of ipv6 address must be
      // enclosed by square brackets.
      // https://serverfault.com/questions/205793/how-can-one-distinguish-the-host-and-the-port-in-an-ipv6-url
      if (pos == -1 || value.startsWith("[") && value.endsWith("]")) {
        _host = value;
        _port = HttpClient.defaultHttpPort;
      } else {
        if (pos > 0) {
          _host = value.substring(0, pos);
        } else {
          _host = null;
        }
        if (pos + 1 == value.length) {
          _port = HttpClient.defaultHttpPort;
        } else {
          try {
            _port = int.parse(value.substring(pos + 1));
          } on FormatException {
            _port = null;
          }
        }
      }
      _set(HttpHeaders.hostHeader, value);
    } else {
      throw HttpException("Unexpected type for header named $name");
    }
  }

  void _addIfModifiedSince(String name, value) {
    if (value is DateTime) {
      ifModifiedSince = value;
    } else if (value is String) {
      _set(HttpHeaders.ifModifiedSinceHeader, value);
    } else {
      throw HttpException("Unexpected type for header named $name");
    }
  }

  void _addTransferEncoding(String name, value) {
    if (value == "chunked") {
      chunkedTransferEncoding = true;
    } else {
      _addValue(HttpHeaders.transferEncodingHeader, value);
    }
  }

  void _addValue(String name, Object value) {
    List<String> values = (_headers[name] ??= <String>[]);
    values.add(_valueToString(value));
  }

  void _checkMutable() {
    if (!_mutable) throw HttpException("HTTP headers are not mutable");
  }

  bool _foldHeader(String name) {
    if (name == HttpHeaders.setCookieHeader) return false;
    var noFoldingHeaders = _noFoldingHeaders;
    return noFoldingHeaders == null || !noFoldingHeaders.contains(name);
  }

  String _originalHeaderName(String name) {
    return _originalHeaderNames?[name] ?? name;
  }

  void _set(String name, String value) {
    assert(name == _validateField(name));
    _headers[name] = <String>[value];
  }

  void _updateHostHeader() {
    var host = _host;
    if (host != null) {
      bool defaultPort = _port == null || _port == _defaultPortForScheme;
      _set("host", defaultPort ? host : "$host:$_port");
    }
  }

  String _valueToString(Object value) {
    if (value is DateTime) {
      return HttpDate.format(value);
    } else if (value is String) {
      return value; // TODO(39784): no _validateValue?
    } else {
      return _validateValue(value.toString()) as String;
    }
  }

  static String _validateField(String field) {
    return field.toLowerCase();
  }

  static Object _validateValue(Object value) {
    if (value is! String) return value;
    return value;
  }
}

// Frequently used character codes.
class _CharCode {
  static const int lf = 10;
  static const int cr = 13;
  static const int sp = 32;
  static const int comma = 44;
  static const int colon = 58;
}

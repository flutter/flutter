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

part of universal_io.http;

bool _isTokenChar(int byte) {
  return byte > 31 && byte < 128 && !_Const.SEPARATOR_MAP[byte];
}

bool _isValueChar(int byte) {
  return (byte > 31 && byte < 128) ||
      (byte == _CharCode.SP) ||
      (byte == _CharCode.HT);
}

class HttpHeadersImpl implements HttpHeaders {
  final Map<String, List<String>> _headers;

  // The original header names keyed by the lowercase header names.
  Map<String, String>? _originalHeaderNames;
  final String protocolVersion;

  final bool _mutable = true; // Are the headers currently mutable?
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
    if (protocolVersion == '1.0') {
      _persistentConnection = false;
      _chunkedTransferEncoding = false;
    }
  }

  @override
  bool get chunkedTransferEncoding => _chunkedTransferEncoding;

  @override
  set chunkedTransferEncoding(bool chunkedTransferEncoding) {
    _checkMutable();
    if (chunkedTransferEncoding && protocolVersion == '1.0') {
      throw HttpException(
          "Trying to set 'Transfer-Encoding: Chunked' on HTTP 1.0 headers");
    }
    if (chunkedTransferEncoding == _chunkedTransferEncoding) return;
    if (chunkedTransferEncoding) {
      final values = _headers[HttpHeaders.transferEncodingHeader];
      if (values == null || !values.contains('chunked')) {
        // Headers does not specify chunked encoding - add it if set.
        _addValue(HttpHeaders.transferEncodingHeader, 'chunked');
      }
      contentLength = -1;
    } else {
      // Headers does specify chunked encoding - remove it if not set.
      remove(HttpHeaders.transferEncodingHeader, 'chunked');
    }
    _chunkedTransferEncoding = chunkedTransferEncoding;
  }

  @override
  int get contentLength => _contentLength;

  @override
  set contentLength(int contentLength) {
    _checkMutable();
    if (protocolVersion == '1.0' &&
        persistentConnection &&
        contentLength == -1) {
      throw HttpException(
          'Trying to clear ContentLength on HTTP 1.0 headers with '
          "'Connection: Keep-Alive' set");
    }
    if (_contentLength == contentLength) return;
    _contentLength = contentLength;
    if (_contentLength >= 0) {
      if (chunkedTransferEncoding) chunkedTransferEncoding = false;
      _set(HttpHeaders.contentLengthHeader, contentLength.toString());
    } else {
      _headers.remove(HttpHeaders.contentLengthHeader);
      if (protocolVersion == '1.1') {
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
    final values = _headers[HttpHeaders.dateHeader];
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
      final formatted = HttpDate.format(date.toUtc());
      _set(HttpHeaders.dateHeader, formatted);
    }
  }

  @override
  DateTime? get expires {
    final values = _headers[HttpHeaders.expiresHeader];
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
      final formatted = HttpDate.format(expires.toUtc());
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
    final values = _headers[HttpHeaders.ifModifiedSinceHeader];
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
      final formatted = HttpDate.format(ifModifiedSince.toUtc());
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
      if (protocolVersion == '1.1') {
        remove(HttpHeaders.connectionHeader, 'close');
      } else {
        if (_contentLength < 0) {
          throw HttpException(
              "Trying to set 'Connection: Keep-Alive' on HTTP 1.0 headers with "
              'no ContentLength');
        }
        add(originalName, 'keep-alive', preserveHeaderCase: true);
      }
    } else {
      if (protocolVersion == '1.1') {
        add(originalName, 'close', preserveHeaderCase: true);
      } else {
        remove(HttpHeaders.connectionHeader, 'keep-alive');
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
    final lowercaseName = _validateField(name);

    if (preserveHeaderCase && name != lowercaseName) {
      (_originalHeaderNames ??= {})[lowercaseName] = name;
    } else {
      _originalHeaderNames?.remove(lowercaseName);
    }
    _addAll(lowercaseName, value);
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

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach((String name, List<String> values) {
      final originalName = _originalHeaderName(name);
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
    final values = _headers[name];
    if (values != null) {
      values.remove(_valueToString(value));
      if (values.isEmpty) {
        _headers.remove(name);
        _originalHeaderNames?.remove(name);
      }
    }
    if (name == HttpHeaders.transferEncodingHeader && value == 'chunked') {
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
    final lowercaseName = _validateField(name);
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
    var sb = StringBuffer();
    _headers.forEach((String name, List<String> values) {
      final originalName = _originalHeaderName(name);
      sb.write(originalName);
      sb.write(': ');
      final fold = _foldHeader(name);
      for (var i = 0; i < values.length; i++) {
        if (i > 0) {
          if (fold) {
            sb.write(', ');
          } else {
            sb..write('\n')..write(originalName)..write(': ');
          }
        }
        sb.write(values[i]);
      }
      sb.write('\n');
    });
    return sb.toString();
  }

  @override
  String? value(String name) {
    name = _validateField(name);
    final values = _headers[name];
    if (values == null) return null;
    assert(values.isNotEmpty);
    if (values.length > 1) {
      throw HttpException('More than one value for header $name');
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

  void _addConnection(String name, value) {
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
      contentLength = value;
    } else if (value is String) {
      contentLength = int.parse(value);
    } else {
      throw HttpException('Unexpected type for header named $name');
    }
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
      throw HttpException('Unexpected type for header named $name');
    }
  }

  void _addExpires(String name, value) {
    if (value is DateTime) {
      expires = value;
    } else if (value is String) {
      _set(HttpHeaders.expiresHeader, value);
    } else {
      throw HttpException('Unexpected type for header named $name');
    }
  }

  void _addHost(String name, value) {
    if (value is String) {
      final pos = value.indexOf(':');
      if (pos == -1) {
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
      throw HttpException('Unexpected type for header named $name');
    }
  }

  void _addIfModifiedSince(String name, value) {
    if (value is DateTime) {
      ifModifiedSince = value;
    } else if (value is String) {
      _set(HttpHeaders.ifModifiedSinceHeader, value);
    } else {
      throw HttpException('Unexpected type for header named $name');
    }
  }

  void _addTransferEncoding(String name, value) {
    if (value == 'chunked') {
      chunkedTransferEncoding = true;
    } else {
      _addValue(HttpHeaders.transferEncodingHeader, value);
    }
  }

  void _addValue(String name, Object value) {
    final values = (_headers[name] ??= <String>[]);
    values.add(_valueToString(value));
  }

  void _checkMutable() {
    if (!_mutable) throw HttpException('HTTP headers are not mutable');
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
      final defaultPort = _port == null || _port == _defaultPortForScheme;
      _set('host', defaultPort ? host : '$host:$_port');
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
    for (var i = 0; i < field.length; i++) {
      if (!_isTokenChar(field.codeUnitAt(i))) {
        throw FormatException(
            'Invalid HTTP header field name: ${json.encode(field)}', field, i);
      }
    }
    return field.toLowerCase();
  }

  static Object _validateValue(Object value) {
    if (value is! String) return value;
    for (var i = 0; i < value.length; i++) {
      if (!_isValueChar(value.codeUnitAt(i))) {
        throw FormatException(
            'Invalid HTTP header field value: ${json.encode(value)}', value, i);
      }
    }
    return value;
  }
}

class _CharCode {
  static const int HT = 9;
  static const int SP = 32;
}

// Global constants.
class _Const {
  static const bool T = true;
  static const bool F = false;

  // Loopup-map for the following characters: '()<>@,;:\\"/[]?={} \t'.
  static const SEPARATOR_MAP = [
    F, F, F, F, F, F, F, F, F, T, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, T, F, T, F, F, F, F, F, T, T, F, F, T, F, F, T, //
    F, F, F, F, F, F, F, F, F, F, T, T, T, T, T, T, T, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, T, T, T, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, T, F, T, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F
  ];
}

class _ContentType extends _HeaderValue implements ContentType {
  String _primaryType = '';
  String _subType = '';

  _ContentType(String primaryType, String subType, String? charset,
      Map<String, String?> parameters)
      : _primaryType = primaryType,
        _subType = subType,
        super('') {
    // TODO(40614): Remove once non-nullability is sound.
    String emptyIfNull(String? string) => string ?? '';
    _primaryType = emptyIfNull(_primaryType);
    _subType = emptyIfNull(_subType);
    _value = '$_primaryType/$_subType';
    // TODO(40614): Remove once non-nullability is sound.
    if (charset != null) {
      _ensureParameters()['charset'] = charset.toLowerCase();
    }
  }

  _ContentType._();

  @override
  String? get charset => parameters['charset'];

  @override
  String get mimeType => '$primaryType/$subType';

  @override
  String get primaryType => _primaryType;

  @override
  String get subType => _subType;

  static _ContentType parse(String value) {
    var result = _ContentType._();
    result._parse(value, ';', null, false);
    final index = result._value.indexOf('/');
    if (index == -1 || index == (result._value.length - 1)) {
      result._primaryType = result._value.trim().toLowerCase();
    } else {
      result._primaryType =
          result._value.substring(0, index).trim().toLowerCase();
      result._subType = result._value.substring(index + 1).trim().toLowerCase();
    }
    return result;
  }
}

class _Cookie implements Cookie {
  String _name;
  String _value;
  @override
  DateTime? expires;
  @override
  int? maxAge;
  @override
  String? domain;
  String? _path;
  @override
  bool httpOnly = false;
  @override
  bool secure = false;

  _Cookie(String name, String value)
      : _name = _validateName(name),
        _value = _validateValue(value),
        httpOnly = true;

  _Cookie.fromSetCookieValue(String value)
      : _name = '',
        _value = '' {
    // Parse the 'set-cookie' header value.
    _parseSetCookieValue(value);
  }

  @override
  String get name => _name;

  @override
  set name(String newName) {
    _validateName(newName);
    _name = newName;
  }

  @override
  String? get path => _path;

  @override
  set path(String? newPath) {
    _validatePath(newPath);
    _path = newPath;
  }

  @override
  String get value => _value;

  @override
  set value(String newValue) {
    _validateValue(newValue);
    _value = newValue;
  }

  // Parse a 'set-cookie' header value according to the rules in RFC 6265.
  @override
  String toString() {
    final sb = StringBuffer();
    sb..write(_name)..write('=')..write(_value);
    var expires = this.expires;
    if (expires != null) {
      sb..write('; Expires=')..write(HttpDate.format(expires));
    }
    if (maxAge != null) {
      sb..write('; Max-Age=')..write(maxAge);
    }
    if (domain != null) {
      sb..write('; Domain=')..write(domain);
    }
    if (path != null) {
      sb..write('; Path=')..write(path);
    }
    if (secure) sb.write('; Secure');
    if (httpOnly) sb.write('; HttpOnly');
    return sb.toString();
  }

  void _parseSetCookieValue(String s) {
    var index = 0;

    bool done() => index == s.length;

    String parseName() {
      final start = index;
      while (!done()) {
        if (s[index] == '=') break;
        index++;
      }
      return s.substring(start, index).trim();
    }

    String parseValue() {
      final start = index;
      while (!done()) {
        if (s[index] == ';') break;
        index++;
      }
      return s.substring(start, index).trim();
    }

    void parseAttributes() {
      String parseAttributeName() {
        final start = index;
        while (!done()) {
          if (s[index] == '=' || s[index] == ';') break;
          index++;
        }
        return s.substring(start, index).trim().toLowerCase();
      }

      String parseAttributeValue() {
        final start = index;
        while (!done()) {
          if (s[index] == ';') break;
          index++;
        }
        return s.substring(start, index).trim().toLowerCase();
      }

      while (!done()) {
        final name = parseAttributeName();
        var value = '';
        if (!done() && s[index] == '=') {
          index++; // Skip the = character.
          value = parseAttributeValue();
        }
        if (name == 'expires') {
          expires = HttpDate._parseCookieDate(value);
        } else if (name == 'max-age') {
          maxAge = int.parse(value);
        } else if (name == 'domain') {
          domain = value;
        } else if (name == 'path') {
          path = value;
        } else if (name == 'httponly') {
          httpOnly = true;
        } else if (name == 'secure') {
          secure = true;
        }
        if (!done()) index++; // Skip the ; character
      }
    }

    _name = _validateName(parseName());
    if (done() || _name.isEmpty) {
      throw HttpException('Failed to parse header value [$s]');
    }
    index++; // Skip the = character.
    _value = _validateValue(parseValue());
    if (done()) return;
    index++; // Skip the ; character.
    parseAttributes();
  }

  static String _validateName(String newName) {
    const separators = [
      '(',
      ')',
      '<',
      '>',
      '@',
      ',',
      ';',
      ':',
      '\\',
      '"',
      '/',
      '[',
      ']',
      '?',
      '=',
      '{',
      '}'
    ];
    for (var i = 0; i < newName.length; i++) {
      final codeUnit = newName.codeUnitAt(i);
      if (codeUnit <= 32 ||
          codeUnit >= 127 ||
          separators.contains(newName[i])) {
        throw FormatException(
            "Invalid character in cookie name, code unit: '$codeUnit'",
            newName,
            i);
      }
    }
    return newName;
  }

  static void _validatePath(String? path) {
    if (path == null) return;
    for (var i = 0; i < path.length; i++) {
      final codeUnit = path.codeUnitAt(i);
      // According to RFC 6265, semicolon and controls should not occur in the
      // path.
      // path-value = <any CHAR except CTLs or ";">
      // CTLs = %x00-1F / %x7F
      if (codeUnit < 0x20 || codeUnit >= 0x7f || codeUnit == 0x3b /*;*/) {
        throw FormatException(
            "Invalid character in cookie path, code unit: '$codeUnit'");
      }
    }
  }

  static String _validateValue(String newValue) {
    // Per RFC 6265, consider surrounding "" as part of the value, but otherwise
    // double quotes are not allowed.
    var start = 0;
    var end = newValue.length;
    if (2 <= newValue.length &&
        newValue.codeUnits[start] == 0x22 &&
        newValue.codeUnits[end - 1] == 0x22) {
      start++;
      end--;
    }

    for (var i = start; i < end; i++) {
      final codeUnit = newValue.codeUnits[i];
      if (!(codeUnit == 0x21 ||
          (codeUnit >= 0x23 && codeUnit <= 0x2B) ||
          (codeUnit >= 0x2D && codeUnit <= 0x3A) ||
          (codeUnit >= 0x3C && codeUnit <= 0x5B) ||
          (codeUnit >= 0x5D && codeUnit <= 0x7E))) {
        throw FormatException(
            "Invalid character in cookie value, code unit: '$codeUnit'",
            newValue,
            i);
      }
    }
    return newValue;
  }
}

// Frequently used character codes.
class _HeaderValue implements HeaderValue {
  String _value;
  Map<String, String?>? _parameters;
  Map<String, String?>? _unmodifiableParameters;

  _HeaderValue([this._value = '', Map<String, String?> parameters = const {}]) {
    if (parameters.isNotEmpty) {
      _parameters = HashMap<String, String?>.from(parameters);
    }
  }

  @override
  Map<String, String?> get parameters =>
      _unmodifiableParameters ??= UnmodifiableMapView(_ensureParameters());

  @override
  String get value => _value;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(_value);
    var parameters = _parameters;
    if (parameters != null && parameters.isNotEmpty) {
      parameters.forEach((String name, String? value) {
        sb..write('; ')..write(name);
        if (value != null) {
          sb.write('=');
          if (_isToken(value)) {
            sb.write(value);
          } else {
            sb.write('"');
            var start = 0;
            for (var i = 0; i < value.length; i++) {
              // Can use codeUnitAt here instead.
              final codeUnit = value.codeUnitAt(i);
              if (codeUnit == 92 /* backslash */ ||
                  codeUnit == 34 /* double quote */) {
                sb.write(value.substring(start, i));
                sb.write(r'\');
                start = i;
              }
            }
            sb..write(value.substring(start))..write('"');
          }
        }
      });
    }
    return sb.toString();
  }

  Map<String, String?> _ensureParameters() =>
      _parameters ??= <String, String?>{};

  void _parse(String s, String parameterSeparator, String? valueSeparator,
      bool preserveBackslash) {
    var index = 0;

    bool done() => index == s.length;

    void skipWS() {
      while (!done()) {
        if (s[index] != ' ' && s[index] != '\t') return;
        index++;
      }
    }

    String parseValue() {
      final start = index;
      while (!done()) {
        var char = s[index];
        if (char == ' ' ||
            char == '\t' ||
            char == valueSeparator ||
            char == parameterSeparator) break;
        index++;
      }
      return s.substring(start, index);
    }

    void expect(String expected) {
      if (done() || s[index] != expected) {
        throw HttpException('Failed to parse header value');
      }
      index++;
    }

    bool maybeExpect(String expected) {
      if (done() || !s.startsWith(expected, index)) {
        return false;
      }
      index++;
      return true;
    }

    void parseParameters() {
      var parameters = _ensureParameters();

      String parseParameterName() {
        final start = index;
        while (!done()) {
          var char = s[index];
          if (char == ' ' ||
              char == '\t' ||
              char == '=' ||
              char == parameterSeparator ||
              char == valueSeparator) break;
          index++;
        }
        return s.substring(start, index).toLowerCase();
      }

      String parseParameterValue() {
        if (!done() && s[index] == '\"') {
          // Parse quoted value.
          final sb = StringBuffer();
          index++;
          while (!done()) {
            var char = s[index];
            if (char == '\\') {
              if (index + 1 == s.length) {
                throw HttpException('Failed to parse header value');
              }
              if (preserveBackslash && s[index + 1] != '\"') {
                sb.write(char);
              }
              index++;
            } else if (char == '\"') {
              index++;
              return sb.toString();
            }
            char = s[index];
            sb.write(char);
            index++;
          }
          throw HttpException('Failed to parse header value');
        } else {
          // Parse non-quoted value.
          return parseValue();
        }
      }

      while (!done()) {
        skipWS();
        if (done()) return;
        final name = parseParameterName();
        skipWS();
        if (maybeExpect('=')) {
          skipWS();
          var value = parseParameterValue();
          if (name == 'charset' && this is _ContentType) {
            // Charset parameter of ContentTypes are always lower-case.
            value = value.toLowerCase();
          }
          parameters[name] = value;
          skipWS();
        } else if (name.isNotEmpty) {
          parameters[name] = null;
        }
        if (done()) return;
        // TODO: Implement support for multi-valued parameters.
        if (s[index] == valueSeparator) return;
        expect(parameterSeparator);
      }
    }

    skipWS();
    _value = parseValue();
    skipWS();
    if (done()) return;
    if (s[index] == valueSeparator) return;
    maybeExpect(parameterSeparator);
    parseParameters();
  }

  static _HeaderValue parse(String value,
      {String parameterSeparator = ';',
      String? valueSeparator,
      bool preserveBackslash = false}) {
    // Parse the string.
    var result = _HeaderValue();
    result._parse(value, parameterSeparator, valueSeparator, preserveBackslash);
    return result;
  }

  static bool _isToken(String token) {
    if (token.isEmpty) {
      return false;
    }
    final delimiters = '\"(),/:;<=>?@[\]{}';
    for (var i = 0; i < token.length; i++) {
      final codeUnit = token.codeUnitAt(i);
      if (codeUnit <= 32 || codeUnit >= 127 || delimiters.contains(token[i])) {
        return false;
      }
    }
    return true;
  }
}

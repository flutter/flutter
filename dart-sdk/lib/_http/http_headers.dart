// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:_http";

class _HttpHeaders implements HttpHeaders {
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

  _HttpHeaders(
    this.protocolVersion, {
    int defaultPortForScheme = HttpClient.defaultHttpPort,
    _HttpHeaders? initialHeaders,
  }) : _headers = HashMap<String, List<String>>(),
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

  List<String>? operator [](String name) => _headers[_validateField(name)];

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

  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _checkMutable();
    String lowercaseName = _validateField(name);

    if (preserveHeaderCase && name != lowercaseName) {
      (_originalHeaderNames ??= {})[lowercaseName] = name;
    } else {
      _originalHeaderNames?.remove(lowercaseName);
    }
    _addAll(lowercaseName, value);
  }

  void _addAll(String name, Object value) {
    if (value is Iterable) {
      for (var v in value) {
        _add(name, _validateValue(v));
      }
    } else {
      _add(name, _validateValue(value));
    }
  }

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

  void removeAll(String name) {
    _checkMutable();
    name = _validateField(name);
    _headers.remove(name);
    _originalHeaderNames?.remove(name);
  }

  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach((String name, List<String> values) {
      String originalName = _originalHeaderName(name);
      action(originalName, values);
    });
  }

  void noFolding(String name) {
    name = _validateField(name);
    (_noFoldingHeaders ??= <String>[]).add(name);
  }

  bool get persistentConnection => _persistentConnection;

  void set persistentConnection(bool persistentConnection) {
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
            "no ContentLength",
          );
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

  int get contentLength => _contentLength;

  void set contentLength(int contentLength) {
    _checkMutable();
    if (protocolVersion == "1.0" &&
        persistentConnection &&
        contentLength == -1) {
      throw HttpException(
        "Trying to clear ContentLength on HTTP 1.0 headers with "
        "'Connection: Keep-Alive' set",
      );
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

  bool get chunkedTransferEncoding => _chunkedTransferEncoding;

  void set chunkedTransferEncoding(bool chunkedTransferEncoding) {
    _checkMutable();
    if (chunkedTransferEncoding && protocolVersion == "1.0") {
      throw HttpException(
        "Trying to set 'Transfer-Encoding: Chunked' on HTTP 1.0 headers",
      );
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

  String? get host => _host;

  void set host(String? host) {
    _checkMutable();
    _host = host;
    _updateHostHeader();
  }

  int? get port => _port;

  void set port(int? port) {
    _checkMutable();
    _port = port;
    _updateHostHeader();
  }

  DateTime? get ifModifiedSince {
    List<String>? values = _headers[HttpHeaders.ifModifiedSinceHeader];
    if (values != null) {
      assert(values.isNotEmpty);
      return HttpDate._tryParse(values[0]);
    }
    return null;
  }

  void set ifModifiedSince(DateTime? ifModifiedSince) {
    _checkMutable();
    if (ifModifiedSince == null) {
      _headers.remove(HttpHeaders.ifModifiedSinceHeader);
    } else {
      // Format "ifModifiedSince" header with date in Greenwich Mean Time (GMT).
      String formatted = HttpDate.format(ifModifiedSince.toUtc());
      _set(HttpHeaders.ifModifiedSinceHeader, formatted);
    }
  }

  DateTime? get date {
    List<String>? values = _headers[HttpHeaders.dateHeader];
    if (values != null) {
      assert(values.isNotEmpty);
      return HttpDate._tryParse(values[0]);
    }
    return null;
  }

  void set date(DateTime? date) {
    _checkMutable();
    if (date == null) {
      _headers.remove(HttpHeaders.dateHeader);
    } else {
      // Format "DateTime" header with date in Greenwich Mean Time (GMT).
      String formatted = HttpDate.format(date.toUtc());
      _set(HttpHeaders.dateHeader, formatted);
    }
  }

  DateTime? get expires {
    List<String>? values = _headers[HttpHeaders.expiresHeader];
    if (values != null) {
      assert(values.isNotEmpty);
      return HttpDate._tryParse(values[0]);
    }
    return null;
  }

  void set expires(DateTime? expires) {
    _checkMutable();
    if (expires == null) {
      _headers.remove(HttpHeaders.expiresHeader);
    } else {
      // Format "Expires" header with date in Greenwich Mean Time (GMT).
      String formatted = HttpDate.format(expires.toUtc());
      _set(HttpHeaders.expiresHeader, formatted);
    }
  }

  ContentType? get contentType {
    var values = _headers[HttpHeaders.contentTypeHeader];
    if (values != null) {
      return ContentType.parse(values[0]);
    } else {
      return null;
    }
  }

  void set contentType(ContentType? contentType) {
    _checkMutable();
    if (contentType == null) {
      _headers.remove(HttpHeaders.contentTypeHeader);
    } else {
      _set(HttpHeaders.contentTypeHeader, contentType.toString());
    }
  }

  void clear() {
    _checkMutable();
    _headers.clear();
    _contentLength = -1;
    _persistentConnection = true;
    _chunkedTransferEncoding = false;
    _host = null;
    _port = null;
  }

  // [name] must be a lower-case version of the name.
  void _add(String name, Object value) {
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
          _addHost(name, _checkString(name, value));
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
          _addConnection(name, _checkString(name, value));
          return;
        }
        break;
      case 12:
        if (HttpHeaders.contentTypeHeader == name) {
          _addContentType(name, _checkString(name, value));
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

  static String _checkString(String name, Object value) {
    if (value is String) return value;
    throw HttpException("Unexpected type for header named $name");
  }

  void _addContentLength(String name, Object value) {
    if (value is int) {
      if (value >= 0) {
        contentLength = value;
        return;
      }
      throw HttpException("Content-Length must contain only digits");
    }
    if (value is String && value.isNotEmpty) {
      var length = 0;
      var number = 0;
      var incrementLength = 0;
      for (var i = 0; i < value.length; i++) {
        var digit = value.codeUnitAt(i) ^ _CharCode.ZERO;
        if (digit <= 9) {
          number = number * 10 + digit;
          if (number != 0) incrementLength = 1;
          length += incrementLength;
          continue;
        }
        throw HttpException("Content-Length must contain only digits");
      }
      if (length >= 16) {
        throw HttpException("Content-Length too large");
      }
      contentLength = number;
      return;
    }
    throw HttpException("Unexpected type for header named $name");
  }

  void _addTransferEncoding(String name, Object value) {
    if (value == "chunked") {
      chunkedTransferEncoding = true;
    } else {
      _addValue(HttpHeaders.transferEncodingHeader, value);
    }
  }

  void _addDate(String name, Object value) {
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      _set(HttpHeaders.dateHeader, value);
    } else {
      throw HttpException("Unexpected type for header named $name");
    }
  }

  void _addExpires(String name, Object value) {
    if (value is DateTime) {
      expires = value;
    } else if (value is String) {
      _set(HttpHeaders.expiresHeader, value);
    } else {
      throw HttpException("Unexpected type for header named $name");
    }
  }

  void _addIfModifiedSince(String name, Object value) {
    if (value is DateTime) {
      ifModifiedSince = value;
    } else if (value is String) {
      _set(HttpHeaders.ifModifiedSinceHeader, value);
    } else {
      throw HttpException("Unexpected type for header named $name");
    }
  }

  void _addHost(String name, String value) {
    // value.indexOf will only work for ipv4, ipv6 which has multiple : in its
    // host part needs lastIndexOf
    int pos = value.lastIndexOf(":");
    // According to RFC 3986, section 3.2.2, host part of ipv6 address must be
    // enclosed by square brackets.
    // https://serverfault.com/questions/205793/how-can-one-distinguish-the-host-and-the-port-in-an-ipv6-url
    if (pos < 0 || value.startsWith("[") && value.endsWith("]")) {
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
        _port = int.tryParse(value.substring(pos + 1), radix: 10);
      }
    }
    _set(HttpHeaders.hostHeader, value);
  }

  void _addConnection(String name, String value) {
    if (_isTextNoCase(value, 0, value.length, 'close')) {
      _persistentConnection = false;
    } else if (_isTextNoCase(value, 0, value.length, 'keep-alive')) {
      _persistentConnection = true;
    }
    _addValue(name, value);
  }

  void _addContentType(String name, String value) {
    _set(HttpHeaders.contentTypeHeader, value);
  }

  void _addValue(String name, Object value) {
    List<String> values = (_headers[name] ??= <String>[]);
    values.add(_valueToString(value));
  }

  String _valueToString(Object value) {
    if (value is DateTime) {
      return HttpDate.format(value);
    } else if (value is String) {
      return value; // TODO(39784): no _validateValue?
    } else {
      var stringValue = value.toString();
      _validateValue(stringValue);
      return stringValue;
    }
  }

  void _set(String name, String value) {
    assert(name == _validateField(name));
    _headers[name] = <String>[value];
  }

  void _checkMutable() {
    if (!_mutable) throw HttpException("HTTP headers are not mutable");
  }

  void _updateHostHeader() {
    var host = _host;
    if (host != null) {
      bool defaultPort = _port == null || _port == _defaultPortForScheme;
      _set("host", defaultPort ? host : "$host:$_port");
    }
  }

  bool _shouldFoldMultiValueHeader(String name) {
    if (name == HttpHeaders.setCookieHeader) return false;
    var noFoldingHeaders = _noFoldingHeaders;
    return noFoldingHeaders == null || !noFoldingHeaders.contains(name);
  }

  void _finalize() {
    _mutable = false;
  }

  void _build(BytesBuilder builder, {bool skipZeroContentLength = false}) {
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
      bool fold = _shouldFoldMultiValueHeader(name);
      var nameData = originalName.codeUnits;
      builder.add(nameData);
      builder.addByte(_CharCode.COLON);
      builder.addByte(_CharCode.SP);
      for (int i = 0; i < values.length; i++) {
        if (i > 0) {
          if (fold) {
            builder.addByte(_CharCode.COMMA);
            builder.addByte(_CharCode.SP);
          } else {
            builder.addByte(_CharCode.CR);
            builder.addByte(_CharCode.LF);
            builder.add(nameData);
            builder.addByte(_CharCode.COLON);
            builder.addByte(_CharCode.SP);
          }
        }
        builder.add(values[i].codeUnits);
      }
      builder.addByte(_CharCode.CR);
      builder.addByte(_CharCode.LF);
    });
  }

  String toString() {
    StringBuffer sb = StringBuffer();
    _headers.forEach((String name, List<String> values) {
      String originalName = _originalHeaderName(name);
      sb
        ..write(originalName)
        ..write(": ");
      bool fold = _shouldFoldMultiValueHeader(name);
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

  List<Cookie> _parseCookies() {
    // Parse a Cookie header value according to the rules in RFC 6265.
    var cookies = <Cookie>[];
    void parseCookieString(String source) {
      int index = 0;

      String parseName() {
        int start = index;
        while (index < source.length) {
          if (source.codeUnitAt(index)
              case == _CharCode.SP || == _CharCode.HT || == _CharCode.EQUALS)
            break;
          index++;
        }
        return source.substring(start, index);
      }

      String parseValue() {
        int start = index;
        while (index < source.length) {
          if (source.codeUnitAt(index)
              case == _CharCode.SP ||
                  == _CharCode.HT ||
                  == _CharCode.SEMI_COLON)
            break;
          index++;
        }
        return source.substring(start, index);
      }

      bool expect(int charCode) {
        if (index < source.length && source.codeUnitAt(index) == charCode) {
          index++;
          return true;
        }
        return false;
      }

      while (index < source.length) {
        index = _skipWhitespace(source, index);
        if (index >= source.length) break;
        String name = parseName();
        index = _skipWhitespace(source, index);
        if (expect(_CharCode.EQUALS)) {
          index = _skipWhitespace(source, index);
          String value = parseValue();
          try {
            cookies.add(_Cookie(name, value));
          } catch (_) {
            // Skip it, invalid cookie data.
          }
          index = _skipWhitespace(source, index);
        }
        if (index >= source.length) return;
        index = source.indexOf(';', index);
        if (index < 0) break;
        index++;
      }
    }

    List<String>? values = _headers[HttpHeaders.cookieHeader];
    if (values != null) {
      for (var headerValue in values) {
        parseCookieString(headerValue);
      }
    }
    return cookies;
  }

  // Returns negative if valid, positive position of an error if not.
  static int _isValidFieldString(String field) {
    for (var i = 0; i < field.length; i++) {
      if (!_HttpParser._isTokenChar(field.codeUnitAt(i))) {
        return i;
      }
    }
    return -1;
  }

  // Returns negative if valid, positive position of an error if not.
  static int _isValidValueString(String value) {
    for (var i = 0; i < value.length; i++) {
      if (!_HttpParser._isValueChar(value.codeUnitAt(i))) {
        return i;
      }
    }
    return -1;
  }

  static String _validateField(String field) {
    var errorAt = _isValidFieldString(field);
    if (errorAt >= 0) {
      throw FormatException(
        "Invalid HTTP header field name: ${json.encode(field)}",
        field,
        errorAt,
      );
    }
    return field.toLowerCase();
  }

  static Object _validateValue(Object value) {
    if (value is String) {
      var errorAt = _isValidValueString(value);
      if (errorAt >= 0) {
        throw FormatException(
          "Invalid HTTP header field value: ${json.encode(value)}",
          value,
          errorAt,
        );
      }
    }
    return value;
  }

  String _originalHeaderName(String name) {
    return _originalHeaderNames?[name] ?? name;
  }
}

class _HeaderValue implements HeaderValue {
  String _value;
  final Map<String, String?> _parameters;
  Map<String, String?>? _unmodifiableParameters;

  _HeaderValue([this._value = "", this._parameters = const {}]);

  static _HeaderValue parse(
    String value, {
    required int parameterSeparator,
    int valueSeparator = _CharCode.NONE,
    bool preserveBackslash = false,
  }) {
    // Parse the string.
    var result = _HeaderValue('', {});
    result._parse(value, parameterSeparator, valueSeparator, preserveBackslash);
    return result;
  }

  String get value => _value;

  Map<String, String?> get parameters =>
      _unmodifiableParameters ??= UnmodifiableMapView(_parameters);

  static bool _isToken(String token) {
    if (token.isEmpty) {
      return false;
    }
    const delimiters = '"(),/:;<=>?@[]{}';
    var delimiterCodeUnits = delimiters.codeUnits;
    for (int i = 0; i < token.length; i++) {
      int codeUnit = token.codeUnitAt(i);
      if (codeUnit <= 32 ||
          codeUnit >= 127 ||
          delimiterCodeUnits.contains(codeUnit)) {
        return false;
      }
    }
    return true;
  }

  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write(_value);
    _parameters.forEach((String name, String? value) {
      sb
        ..write("; ")
        ..write(name);
      if (value != null) {
        sb.write("=");
        if (_isToken(value)) {
          sb.write(value);
        } else {
          sb.writeCharCode(_CharCode.QUOTE);
          for (int i = 0; i < value.length; i++) {
            int codeUnit = value.codeUnitAt(i);
            if (codeUnit == _CharCode.BACKSLASH ||
                codeUnit == _CharCode.QUOTE) {
              // Escape embedded `"` or `\`.
              sb.writeCharCode(_CharCode.BACKSLASH);
            }
            sb.writeCharCode(codeUnit);
          }
          sb.writeCharCode(_CharCode.QUOTE);
        }
      }
    });
    return sb.toString();
  }

  void _parse(
    String source,
    int parameterSeparator,
    int valueSeparator, // Use negative value for `none`.
    bool preserveBackslash,
  ) {
    int index = 0;

    bool done() => index == source.length;

    String parseValue() {
      int start = index;
      while (index < source.length) {
        var char = source.codeUnitAt(index);
        if (char != _CharCode.SP &&
            char != _CharCode.HT &&
            char != valueSeparator &&
            char != parameterSeparator) {
          index++;
        } else {
          break;
        }
      }
      return source.substring(start, index);
    }

    bool maybeExpect(int codeUnit) {
      if (index < source.length && source.codeUnitAt(index) == codeUnit) {
        index++;
        return true;
      }
      return false;
    }

    void expect(int codeUnit) {
      if (!maybeExpect(codeUnit)) {
        throw HttpException("Failed to parse header value");
      }
    }

    void parseParameters() {
      String parseParameterName() {
        int start = index;
        while (index < source.length) {
          var char = source.codeUnitAt(index);
          if (char != _CharCode.SP &&
              char != _CharCode.HT &&
              char != _CharCode.EQUALS &&
              char != parameterSeparator &&
              char != valueSeparator) {
            index++;
          } else {
            break;
          }
        }
        return source.substring(start, index).toLowerCase();
      }

      String parseParameterValue() {
        if (maybeExpect(_CharCode.QUOTE)) {
          // Parse quoted value.
          StringBuffer sb = StringBuffer();
          while (index < source.length) {
            var char = source.codeUnitAt(index);
            index++;
            if (char != _CharCode.QUOTE) {
              if (char != _CharCode.BACKSLASH) {
                sb.writeCharCode(char);
                continue;
              }
              // If `preserveBackslash` is true, retain backslashes
              // except those escaping a backslash.
              // Otherwise remove backslash.
              // Then retain the next char verbatim.
              if (index < source.length) {
                char = source.codeUnitAt(index);
                index++;
                if (preserveBackslash && char != _CharCode.QUOTE) {
                  sb.writeCharCode(_CharCode.BACKSLASH);
                }
                sb.writeCharCode(char);
              } else {
                // No char after a `\`, and also no end quote.
                break;
              }
            } else {
              // Char is end quote.
              return sb.toString();
            }
          }
          throw HttpException("Failed to parse header value");
        } else {
          // Parse non-quoted value.
          return parseValue();
        }
      }

      while (index < source.length) {
        index = _skipWhitespace(source, index);
        if (index >= source.length) return;
        String name = parseParameterName();
        index = _skipWhitespace(source, index);
        if (maybeExpect(_CharCode.EQUALS)) {
          index = _skipWhitespace(source, index);
          String value = parseParameterValue();
          if (name == 'charset' && this is _ContentType) {
            // Charset parameter of ContentTypes are always lower-case.
            value = value.toLowerCase();
          }
          _parameters[name] = value;
        } else if (name.isNotEmpty) {
          _parameters[name] = null;
        }
        index = _skipWhitespace(source, index);
        if (index >= source.length) return;
        // TODO: Implement support for multi-valued parameters.
        if (source.codeUnitAt(index) == valueSeparator) return;
        expect(parameterSeparator);
      }
    }

    index = _skipWhitespace(source, index);
    _value = parseValue();
    index = _skipWhitespace(source, index);
    if (index >= source.length) return;
    // TODO: Implement support for multi-valued parameters.
    if (source.codeUnitAt(index) == valueSeparator) return;
    maybeExpect(parameterSeparator); // Separator is optional.
    parseParameters();
  }
}

class _ContentType extends _HeaderValue implements ContentType {
  String _primaryType = "";
  String _subType = "";

  _ContentType(
    this._primaryType,
    this._subType,
    String? charset,
    Map<String, String?> parameters,
  ) : super("$_primaryType/$_subType", _createParams(parameters, charset));

  static Map<String, String?> _createParams(
    Map<String, String?> parameters,
    String? charset,
  ) {
    var result = <String, String?>{};
    parameters.forEach((String key, String? value) {
      String lowerCaseKey = key.toLowerCase();
      if (lowerCaseKey == "charset") {
        if (value != null) value = value.toLowerCase();
      }
      result[lowerCaseKey] = value;
    });
    if (charset != null) {
      result["charset"] = charset.toLowerCase();
    }

    return result;
  }

  _ContentType._() : super('', {});

  static _ContentType parse(String source) {
    var result = _ContentType._();
    result._parse(source, _CharCode.SEMI_COLON, _CharCode.NONE, false);
    String value = result.value;
    int index = value.indexOf("/");
    if (index < 0 || index == (value.length - 1)) {
      result._primaryType = value.trim().toLowerCase();
    } else {
      result._primaryType = value.substring(0, index).trim().toLowerCase();
      result._subType = value.substring(index + 1).trim().toLowerCase();
    }
    return result;
  }

  String get mimeType => '$primaryType/$subType';

  String get primaryType => _primaryType;

  String get subType => _subType;

  String? get charset => parameters["charset"];
}

class _Cookie implements Cookie {
  String _name;
  String _value;
  DateTime? expires;
  int? maxAge;
  String? domain;
  String? _path;
  bool httpOnly = false;
  bool secure = false;
  SameSite? sameSite;

  _Cookie(String name, String value)
    : _name = _validateName(name),
      _value = _validateValue(value),
      httpOnly = true;

  String get name => _name;
  String get value => _value;

  String? get path => _path;

  set path(String? newPath) {
    _validatePath(newPath);
    _path = newPath;
  }

  set name(String newName) {
    _validateName(newName);
    _name = newName;
  }

  set value(String newValue) {
    _validateValue(newValue);
    _value = newValue;
  }

  _Cookie.fromSetCookieValue(String value) : _name = "", _value = "" {
    // Parse the 'set-cookie' header value.
    _parseSetCookieValue(value);
  }

  // Parse a 'set-cookie-string' value according to the rules in RFC 6265,
  // and update this cookie with the result.
  //
  // Is more permissive about whitespace than the grammar,
  // by allowing spaces or horizontal tabs around any `;` or `=`.
  // Is case-insensitive about attribute names and known values.
  //
  //  set-cookie-header = "Set-Cookie:" SP set-cookie-string
  //  set-cookie-string = cookie-pair *( ";" SP cookie-av )
  //  cookie-pair       = cookie-name "=" cookie-value
  //  cookie-name       = token
  //  cookie-value      = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
  //  cookie-octet      = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E
  //                        ; US-ASCII characters excluding CTLs,
  //                        ; whitespace DQUOTE, comma, semicolon,
  //                        ; and backslash
  //  token             = <token, defined in [RFC2616], Section 2.2>
  //
  //  cookie-av         = expires-av / max-age-av / domain-av /
  //                      path-av / secure-av / httponly-av /
  //                      extension-av
  //  expires-av        = "Expires=" sane-cookie-date
  //  sane-cookie-date  = <rfc1123-date, defined in [RFC2616], Section 3.3.1>
  //  max-age-av        = "Max-Age=" non-zero-digit *DIGIT
  //                        ; In practice, both expires-av and max-age-av
  //                        ; are limited to dates representable by the
  //                        ; user agent.
  //  non-zero-digit    = %x31-39
  //                        ; digits 1 through 9
  //  domain-av         = "Domain=" domain-value
  //  domain-value      = <subdomain>
  //                        ; defined in [RFC1034], Section 3.5, as
  //                        ; enhanced by [RFC1123], Section 2.1
  //  path-av           = "Path=" path-value
  //  path-value        = <any CHAR except CTLs or ";">
  //  secure-av         = "Secure"
  //  httponly-av       = "HttpOnly"
  //  extension-av      = <any CHAR except CTLs or ";">
  void _parseSetCookieValue(String source) {
    int index = 0;

    // Skips until after next [charCode] or to end of input, whichever is first.
    //
    // The [charCode] must not be space or tab.
    //
    // Returns the position after the last non-whitespace character before
    // [charCode].
    int parseUntil(int charCode) {
      int start = index;
      int afterLastNonWhitespace = index;
      while (index < source.length) {
        var char = source.codeUnitAt(index);
        index++;
        if (char != charCode) {
          if (char != _CharCode.SP && char != _CharCode.HT) {
            afterLastNonWhitespace = index;
          }
        } else {
          break;
        }
      }
      return afterLastNonWhitespace;
    }

    index = _skipWhitespace(source, index);
    var nameStart = index;
    var nameEnd = parseUntil(_CharCode.EQUALS);
    if (index >= source.length || nameEnd == nameStart) {
      // Missing `=` after name or no name at all.
      throw HttpException("Failed to parse header value [$source]");
    }
    var name = source.substring(nameStart, nameEnd);
    _name = _validateName(name);

    index = _skipWhitespace(source, index);
    var valueStart = index;
    var valueEnd = parseUntil(_CharCode.SEMI_COLON);
    var value = source.substring(valueStart, valueEnd);
    _value = _validateValue(value);

    // Parse attributes. After `;` of cookie or previous attribute, or at end.
    while (index < source.length) {
      index = _skipWhitespace(source, index);
      if (index >= source.length) break;

      int nameStart = index;
      int nameEnd = index;
      int char = 0;
      // Name is until `=` or `;`, ignore trailing whitespace.
      // (Can't use `parseUntil` since that only accepts one end-character.)
      do {
        char = source.codeUnitAt(index);
        index++;
        if (char != _CharCode.EQUALS && char != _CharCode.SEMI_COLON) {
          if (char != _CharCode.SP && char != _CharCode.HT) {
            nameEnd = index;
          }
        } else {
          break;
        }
      } while (index < source.length);
      int nameLength = nameEnd - nameStart;

      int valueStart = 0;
      int valueEnd = 0;
      if (char == _CharCode.EQUALS) {
        index = _skipWhitespace(source, index);
        valueStart = index;
        valueEnd = parseUntil(_CharCode.SEMI_COLON);
      }

      if (_isTextNoCase(source, nameStart, nameLength, "Expires")) {
        if (valueStart > 0) {
          expires = HttpDate._parseCookieDate(source, valueStart, valueEnd);
        } else {
          throw HttpException("Missing value for 'Expires'");
        }
      } else if (_isTextNoCase(source, nameStart, nameLength, "Max-Age")) {
        if (valueStart > 0) {
          maxAge = int.parse(source.substring(valueStart, valueEnd));
        } else {
          throw HttpException("Missing value for 'Max-Age'");
        }
      } else if (_isTextNoCase(source, nameStart, nameLength, "Domain")) {
        domain = valueStart > 0 ? source.substring(valueStart, valueEnd) : "";
      } else if (_isTextNoCase(source, nameStart, nameLength, "Path")) {
        path = valueStart > 0 ? source.substring(valueStart, valueEnd) : "";
      } else if (_isTextNoCase(source, nameStart, nameLength, "HttpOnly")) {
        if (valueStart > 0) {
          throw HttpException("Value given for 'HttpOnly'");
        }
        httpOnly = true;
      } else if (_isTextNoCase(source, nameStart, nameLength, "Secure")) {
        if (valueStart > 0) {
          throw HttpException("Value given for 'Secure'");
        }
        secure = true;
      } else if (_isTextNoCase(source, nameStart, nameLength, "SameSite")) {
        var valueLength = valueEnd - valueStart; // Is 0 if no value.
        sameSite = switch (valueLength) {
          "Lax".length
              when _isTextNoCase(source, valueStart, valueLength, "Lax") =>
            SameSite.lax,
          "None".length
              when _isTextNoCase(source, valueStart, valueLength, "None") =>
            SameSite.none,
          "Strict".length
              when _isTextNoCase(source, valueStart, valueLength, "Strict") =>
            SameSite.strict,
          _ => throw HttpException(
            "'SameSite' value should be one of 'Lax', 'Strict' or 'None'.",
          ),
        };
      } else {
        // An extension-av, which is not validated or processed.
      }
    }
  }

  String toString() {
    StringBuffer out = StringBuffer();
    out
      ..write(_name)
      ..write("=")
      ..write(_value);

    void writeParameter(String name, Object? value) {
      out
        ..write('; ')
        ..write(name);
      if (value != null) {
        out
          ..write('=')
          ..write(value);
      }
    }

    var expires = this.expires;
    if (expires != null) {
      writeParameter('Expires', ''); // Writes empty value.
      HttpDate._formatTo(expires, out);
    }
    if (maxAge != null) {
      writeParameter('Max-Age', maxAge);
    }
    var domain = this.domain;
    if (domain != null) {
      writeParameter('Domain', domain.trim());
    }
    var path = this.path;
    if (path != null) {
      writeParameter('Path', path.trim());
    }
    if (secure) writeParameter('Secure', null);
    if (httpOnly) writeParameter("HttpOnly", null);
    var sameSite = this.sameSite;
    if (sameSite != null) {
      writeParameter('SameSite', sameSite.name);
    }
    return out.toString();
  }

  static int _isValidName(String newName) {
    const separators = r"""()<>@,;:\"/[]?={}""";
    var separatorCodeUnits = separators.codeUnits;
    for (int i = 0; i < newName.length; i++) {
      int codeUnit = newName.codeUnitAt(i);
      if (codeUnit <= _CharCode.SP ||
          codeUnit >= 0x7F ||
          separatorCodeUnits.contains(codeUnit)) {
        return i;
      }
    }
    return -1;
  }

  static String _validateName(String newName) {
    var errorAt = _isValidName(newName);
    if (errorAt >= 0) {
      throw FormatException(
        "Invalid character in cookie name, code unit: '${newName.codeUnitAt(errorAt)}'",
        newName,
        errorAt,
      );
    }
    return newName;
  }

  static int _isValidValueString(String newValue) {
    var start = 0;
    var end = newValue.length;
    // Per RFC 6265, consider surrounding "" as part of the value, but otherwise
    // double quotes are not allowed.
    if (end >= start + 2 &&
        newValue.codeUnitAt(start) == _CharCode.QUOTE &&
        newValue.codeUnitAt(end - 1) == _CharCode.QUOTE) {
      start++;
      end--;
    }

    for (int i = start; i < end; i++) {
      int codeUnit = newValue.codeUnitAt(i);
      if (!((codeUnit >= 0x21 && codeUnit <= 0x7E) &&
          codeUnit != _CharCode.QUOTE &&
          codeUnit != _CharCode.COMMA &&
          codeUnit != _CharCode.SEMI_COLON &&
          codeUnit != _CharCode.BACKSLASH)) {
        return i;
      }
    }
    return -1;
  }

  static String _validateValue(String source) {
    var errorAt = _isValidValueString(source);
    if (errorAt >= 0) {
      throw FormatException(
        "Invalid character in cookie value, code unit: '${source.codeUnitAt(errorAt)}'",
        source,
        errorAt,
      );
    }
    return source;
  }

  static int _isValidPath(String path, int start, int end) {
    for (int i = start; i < end; i++) {
      int codeUnit = path.codeUnitAt(i);
      // According to RFC 6265, ';' and controls should not occur in the
      // path.
      // path-value = <any CHAR except CTLs or ";">
      // CTLs = %x00-1F / %x7F
      if (codeUnit < _CharCode.SP ||
          codeUnit >= _CharCode.DEL ||
          codeUnit == _CharCode.SEMI_COLON) {
        return i;
      }
    }
    return -1;
  }

  static void _validatePath(String? path) {
    if (path == null) return;
    var errorAt = _isValidPath(path, 0, path.length);
    if (errorAt >= 0) {
      throw FormatException(
        "Invalid character in cookie path, code unit: '${path.codeUnitAt(errorAt)}'",
        path,
        errorAt,
      );
    }
  }
}

/// Checks if `source.substring(at, at + length)` is the same as [text].
///
/// If [offset] is non-zero, only checks against `text.substring(offset)`.
/// Starts by checking that [text] has length [length] - [offset].
///
/// Ignores case of ASCII letters.
///
/// The [text] should match the casing of the expected input to make
/// checking faster.
bool _isTextNoCase(
  String source,
  int at,
  int length,
  String text, [
  int offset = 0,
]) {
  if (text.length - offset != length) return false;
  for (var i = 0; i < length; i++) {
    int testChar = text.codeUnitAt(offset + i);
    int actualChar = source.codeUnitAt(at + i);
    var delta = testChar ^ actualChar;
    if (delta == 0) continue;
    if (delta == 0x20) {
      testChar |= 0x20; // To lower case if ASCII letter.
      if (testChar >= _CharCode.LETTER_a && testChar <= _CharCode.LETTER_z) {
        continue;
      }
    }
    return false;
  }
  return true;
}

int _skipWhitespace(String source, int index) {
  while (index < source.length) {
    int charCode = source.codeUnitAt(index);
    if (charCode == _CharCode.SP || charCode == _CharCode.HT) {
      index++;
      continue;
    }
    break;
  }
  return index;
}

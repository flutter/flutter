// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:stream_channel/stream_channel.dart';

import 'hijack_exception.dart';
import 'message.dart';
import 'util.dart';

/// An HTTP request to be processed by a Shelf application.
class Request extends Message {
  /// The URL path from the current handler to the requested resource, relative
  /// to [handlerPath], plus any query parameters.
  ///
  /// This should be used by handlers for determining which resource to serve,
  /// in preference to [requestedUri]. This allows handlers to do the right
  /// thing when they're mounted anywhere in the application. Routers should be
  /// sure to update this when dispatching to a nested handler, using the
  /// `path` parameter to [change].
  ///
  /// [url]'s path is always relative. It may be empty, if [requestedUri] ends
  /// at this handler. [url] will always have the same query parameters as
  /// [requestedUri].
  ///
  /// [handlerPath] and [url]'s path combine to create [requestedUri]'s path.
  final Uri url;

  /// The HTTP request method, such as "GET" or "POST".
  final String method;

  /// The URL path to the current handler.
  ///
  /// This allows a handler to know its location within the URL-space of an
  /// application. Routers should be sure to update this when dispatching to a
  /// nested handler, using the `path` parameter to [change].
  ///
  /// [handlerPath] is always a root-relative URL path; that is, it always
  /// starts with `/`. It will also end with `/` whenever [url]'s path is
  /// non-empty, or if [requestedUri]'s path ends with `/`.
  ///
  /// [handlerPath] and [url]'s path combine to create [requestedUri]'s path.
  final String handlerPath;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  final String protocolVersion;

  /// The original [Uri] for the request.
  final Uri requestedUri;

  /// The callback wrapper for hijacking this request.
  ///
  /// This will be `null` if this request can't be hijacked.
  final _OnHijack? _onHijack;

  /// Whether this request can be hijacked.
  ///
  /// This will be `false` either if the adapter doesn't support hijacking, or
  /// if the request has already been hijacked.
  bool get canHijack => _onHijack != null && !_onHijack!.called;

  /// If this is non-`null` and the requested resource hasn't been modified
  /// since this date and time, the server should return a 304 Not Modified
  /// response.
  ///
  /// This is parsed from the If-Modified-Since header in [headers]. If
  /// [headers] doesn't have an If-Modified-Since header, this will be `null`.
  ///
  /// Throws [FormatException], if incoming HTTP request has an invalid
  /// If-Modified-Since header.
  DateTime? get ifModifiedSince {
    if (_ifModifiedSinceCache != null) return _ifModifiedSinceCache;
    if (!headers.containsKey('if-modified-since')) return null;
    _ifModifiedSinceCache = parseHttpDate(headers['if-modified-since']!);
    return _ifModifiedSinceCache;
  }

  DateTime? _ifModifiedSinceCache;

  /// Creates a new [Request].
  ///
  /// [handlerPath] must be root-relative. [url]'s path must be fully relative,
  /// and it must have the same query parameters as [requestedUri].
  /// [handlerPath] and [url]'s path must combine to be the path component of
  /// [requestedUri]. If they're not passed, [handlerPath] will default to `/`
  /// and [url] to `requestedUri.path` without the initial `/`. If only one is
  /// passed, the other will be inferred.
  ///
  /// [body] is the request body. It may be either a [String], a [List<int>], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. The default
  /// encoding is UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  /// [headers] must contain values that are either `String` or `List<String>`.
  /// An empty list will cause the header to be omitted.
  ///
  /// The default value for [protocolVersion] is '1.1'.
  ///
  /// ## `onHijack`
  ///
  /// [onHijack] allows handlers to take control of the underlying socket for
  /// the request. It should be passed by adapters that can provide access to
  /// the bidirectional socket underlying the HTTP connection stream.
  ///
  /// The [onHijack] callback will only be called once per request. It will be
  /// passed another callback which takes a byte StreamChannel. [onHijack] must
  /// pass the channel for the connection stream to this callback, although it
  /// may do so asynchronously.
  ///
  /// If a request is hijacked, the adapter should expect to receive a
  /// [HijackException] from the handler. This is a special exception used to
  /// indicate that hijacking has occurred. The adapter should avoid either
  /// sending a response or notifying the user of an error if a
  /// [HijackException] is caught.
  ///
  /// An adapter can check whether a request was hijacked using [canHijack],
  /// which will be `false` for a hijacked request. The adapter may throw an
  /// error if a [HijackException] is received for a non-hijacked request, or if
  /// no [HijackException] is received for a hijacked request.
  ///
  /// See also [hijack].
  // TODO(kevmoo) finish documenting the rest of the arguments.
  Request(
    String method,
    Uri requestedUri, {
    String? protocolVersion,
    Map<String, /* String | List<String> */ Object>? headers,
    String? handlerPath,
    Uri? url,
    Object? body,
    Encoding? encoding,
    Map<String, Object>? context,
    void Function(void Function(StreamChannel<List<int>>))? onHijack,
  }) : this._(method, requestedUri,
            protocolVersion: protocolVersion,
            headers: headers,
            url: url,
            handlerPath: handlerPath,
            body: body,
            encoding: encoding,
            context: context,
            onHijack: onHijack == null ? null : _OnHijack(onHijack));

  /// This constructor has the same signature as [Request.new] except that
  /// accepts [onHijack] as [_OnHijack].
  ///
  /// Any [Request] created by calling [change] will pass [_onHijack] from the
  /// source [Request] to ensure that [hijack] can only be called once, even
  /// from a changed [Request].
  Request._(
    this.method,
    this.requestedUri, {
    String? protocolVersion,
    Map<String, /* String | List<String> */ Object>? headers,
    String? handlerPath,
    Uri? url,
    Object? body,
    Encoding? encoding,
    Map<String, Object>? context,
    _OnHijack? onHijack,
  })  : protocolVersion = protocolVersion ?? '1.1',
        url = _computeUrl(requestedUri, handlerPath, url),
        handlerPath = _computeHandlerPath(requestedUri, handlerPath, url),
        _onHijack = onHijack,
        super(body, encoding: encoding, headers: headers, context: context) {
    if (method.isEmpty) {
      throw ArgumentError.value(method, 'method', 'cannot be empty.');
    }

    try {
      // Trigger URI parsing methods that may throw format exception (in Request
      // constructor or in handlers / routing).
      requestedUri.pathSegments;
      requestedUri.queryParametersAll;
    } on FormatException catch (e) {
      throw ArgumentError.value(
          requestedUri, 'requestedUri', 'URI parsing failed: $e');
    }

    if (!requestedUri.isAbsolute) {
      throw ArgumentError.value(
          requestedUri, 'requestedUri', 'must be an absolute URL.');
    }

    if (requestedUri.fragment.isNotEmpty) {
      throw ArgumentError.value(
          requestedUri, 'requestedUri', 'may not have a fragment.');
    }

    // Notice that because relative paths must encode colon (':') as %3A we
    // cannot actually combine this.handlerPath and this.url.path, but we can
    // compare the pathSegments. In practice exposing this.url.path as a Uri
    // and not a String is probably the underlying flaw here.
    final handlerPart = Uri(path: this.handlerPath).pathSegments.join('/');
    final rest = this.url.pathSegments.join('/');
    final join = this.url.path.startsWith('/') ? '/' : '';
    final pathSegments = '$handlerPart$join$rest';
    if (pathSegments != requestedUri.pathSegments.join('/')) {
      throw ArgumentError.value(
          requestedUri,
          'requestedUri',
          'handlerPath "${this.handlerPath}" and url "${this.url}" must '
              'combine to equal requestedUri path "${requestedUri.path}".');
    }
  }

  /// Creates a new [Request] by copying existing values and applying specified
  /// changes.
  ///
  /// New key-value pairs in [context] and [headers] will be added to the copied
  /// [Request]. If [context] or [headers] includes a key that already exists,
  /// the key-value pair will replace the corresponding entry in the copied
  /// [Request]. If [context] or [headers] contains a `null` value the
  /// corresponding `key` will be removed if it exists, otherwise the `null`
  /// value will be ignored.
  /// For [headers] a value which is an empty list will also cause the
  /// corresponding key to be removed.
  ///
  /// All other context and header values from the [Request] will be
  /// included in the copied [Request] unchanged.
  ///
  /// [body] is the request body. It may be either a [String], a [List<int>], a
  /// [Stream<List<int>>], or `null` to indicate no body.
  ///
  /// [path] is used to update both [handlerPath] and [url]. It's designed for
  /// routing middleware, and represents the path from the current handler to
  /// the next handler. It must be a prefix of [url]; [handlerPath] becomes
  /// `handlerPath + "/" + path`, and [url] becomes relative to that. For
  /// example:
  ///
  ///     print(request.handlerPath); // => /static/
  ///     print(request.url);        // => dir/file.html
  ///
  ///     request = request.change(path: "dir");
  ///     print(request.handlerPath); // => /static/dir/
  ///     print(request.url);        // => file.html
  @override
  Request change({
    Map<String, /* String | List<String> */ Object?>? headers,
    Map<String, Object?>? context,
    String? path,
    Object? body,
  }) {
    final headersAll = updateHeaders(this.headersAll, headers);
    final newContext = updateMap<String, Object>(this.context, context);

    body ??= extractBody(this);

    var handlerPath = this.handlerPath;
    if (path != null) handlerPath += path;

    return Request._(method, requestedUri,
        protocolVersion: protocolVersion,
        headers: headersAll,
        handlerPath: handlerPath,
        body: body,
        context: newContext,
        onHijack: _onHijack);
  }

  /// Takes control of the underlying request socket.
  ///
  /// Synchronously, this throws a [HijackException] that indicates to the
  /// adapter that it shouldn't emit a response itself. Asynchronously,
  /// [callback] is called with a [StreamChannel<List<int>>] that provides
  /// access to the underlying request socket.
  ///
  /// This may only be called when using a Shelf adapter that supports
  /// hijacking, such as the `dart:io` adapter. In addition, a given request may
  /// only be hijacked once. [canHijack] can be used to detect whether this
  /// request can be hijacked.
  Never hijack(void Function(StreamChannel<List<int>>) callback) {
    if (_onHijack == null) {
      throw StateError("This request can't be hijacked.");
    }

    _onHijack!.run(callback);

    throw const HijackException();
  }
}

/// A callback for [Request.hijack] and tracking of whether it has been called.
class _OnHijack {
  final void Function(void Function(StreamChannel<List<int>>)) _callback;

  bool called = false;

  _OnHijack(this._callback);

  /// Calls [this].
  ///
  /// Throws a [StateError] if [this] has already been called.
  void run(void Function(StreamChannel<List<int>>) callback) {
    if (called) throw StateError('This request has already been hijacked.');
    called = true;
    Future.microtask(() => _callback(callback));
  }
}

/// Computes `url` from the provided [Request] constructor arguments.
///
/// If [url] is `null`, the value is inferred from [requestedUri] and
/// [handlerPath] if available. Otherwise [url] is returned.
Uri _computeUrl(Uri requestedUri, String? handlerPath, Uri? url) {
  if (handlerPath != null &&
      handlerPath != requestedUri.path &&
      !handlerPath.endsWith('/')) {
    handlerPath += '/';
  }

  if (url != null) {
    if (url.scheme.isNotEmpty || url.hasAuthority || url.fragment.isNotEmpty) {
      throw ArgumentError('url "$url" may contain only a path and query '
          'parameters.');
    }

    if (!requestedUri.path.endsWith(url.path)) {
      throw ArgumentError('url "$url" must be a suffix of requestedUri '
          '"$requestedUri".');
    }

    if (requestedUri.query != url.query) {
      throw ArgumentError('url "$url" must have the same query parameters '
          'as requestedUri "$requestedUri".');
    }

    if (url.path.startsWith('/')) {
      throw ArgumentError('url "$url" must be relative.');
    }

    var startOfUrl = requestedUri.path.length - url.path.length;
    if (url.path.isNotEmpty &&
        requestedUri.path.substring(startOfUrl - 1, startOfUrl) != '/') {
      throw ArgumentError('url "$url" must be on a path boundary in '
          'requestedUri "$requestedUri".');
    }

    return url;
  } else if (handlerPath != null) {
    return Uri(
        path: requestedUri.path.substring(handlerPath.length),
        query: requestedUri.query);
  } else {
    // Skip the initial "/".
    var path = requestedUri.path.substring(1);
    return Uri(path: path, query: requestedUri.query);
  }
}

/// Computes `handlerPath` from the provided [Request] constructor arguments.
///
/// If [handlerPath] is `null`, the value is inferred from [requestedUri] and
/// [url] if available. Otherwise [handlerPath] is returned.
String _computeHandlerPath(Uri requestedUri, String? handlerPath, Uri? url) {
  if (handlerPath != null &&
      handlerPath != requestedUri.path &&
      !handlerPath.endsWith('/')) {
    handlerPath += '/';
  }

  if (handlerPath != null) {
    if (!requestedUri.path.startsWith(handlerPath)) {
      throw ArgumentError('handlerPath "$handlerPath" must be a prefix of '
          'requestedUri path "${requestedUri.path}"');
    }

    if (!handlerPath.startsWith('/')) {
      throw ArgumentError('handlerPath "$handlerPath" must be root-relative.');
    }

    return handlerPath;
  } else if (url != null) {
    if (url.path.isEmpty) return requestedUri.path;

    var index = requestedUri.path.indexOf(url.path);
    return requestedUri.path.substring(0, index);
  } else {
    return '/';
  }
}

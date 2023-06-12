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

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:typed_data/typed_buffers.dart';

import '../http/http.dart' show HttpHeadersImpl;
import '../io_impl_js.dart';
import 'http_client.dart';
import 'http_client_exception.dart';
import 'http_client_response.dart';
import 'io_sink_base.dart';

class BrowserHttpClientRequest extends HttpClientRequest with IOSinkBase {
  final BrowserHttpClient client;

  String? _browserResponseType;

  /// Enables [CORS "credentials mode"](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials)
  /// in _XHR_ request. Disabled by default.
  ///
  /// # Example
  /// ```
  /// Future<void> main() async {
  ///   final client = HttpClient();
  ///   final request = client.getUrl(Url.parse('http://host/path'));
  ///   if (request is BrowserHttpClientRequest) {
  ///     request.browserCredentialsMode = true;
  ///   }
  ///   final response = await request.close();
  ///   // ...
  /// }
  ///  ```
  bool browserCredentialsMode = false;

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = HttpHeadersImpl('1.1');

  final Completer<HttpClientResponse> _completer =
      Completer<HttpClientResponse>();

  Future? _addStreamFuture;

  @override
  final List<Cookie> cookies = <Cookie>[];

  final bool _supportsBody;

  @override
  Encoding encoding = utf8;

  Future<HttpClientResponse>? _result;

  final _buffer = Uint8Buffer();

  @internal
  BrowserHttpClientRequest(this.client, this.method, this.uri)
      : _supportsBody = _httpMethodSupportsBody(method) {
    // Add "User-Agent" header
    final userAgent = client.userAgent;
    if (userAgent != null) {
      headers.set(HttpHeaders.userAgentHeader, userAgent);
    }

    // Set default values
    browserCredentialsMode = client.browserCredentialsMode;
    followRedirects = true;
    maxRedirects = 5;
    bufferOutput = true;
  }

  /// Sets _responseType_ in _XHR_ request.
  ///
  /// By default null, which means that the [HttpClientResponse] should contain
  /// bytes.
  String? get browserResponseType => _browserResponseType;

  set browserResponseType(String? value) {
    if (value != null) {
      const validValues = <String>{
        'arraybuffer',
        'blob',
        'document',
        'json',
        'text'
      };
      if (!validValues.contains(value)) {
        throw ArgumentError.value(value);
      }
    }
    _browserResponseType = value;
  }

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  Future<HttpClientResponse> get done {
    return _completer.future;
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> event) {
    if (!_supportsBody) {
      throw StateError('HTTP method $method does not support body');
    }
    if (_completer.isCompleted) {
      throw StateError('StreamSink is closed');
    }
    if (_addStreamFuture != null) {
      throw StateError('StreamSink is bound to a stream');
    }
    _buffer.addAll(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) {
      throw StateError('HTTP request is closed already');
    }
    _completer.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    if (_completer.isCompleted) {
      throw StateError('StreamSink is closed');
    }
    if (_addStreamFuture != null) {
      throw StateError('StreamSink is bound to a stream');
    }
    final future = stream.listen((item) {
      add(item);
    }, onError: (error) {
      addError(error);
    }, cancelOnError: true).asFuture(null);
    _addStreamFuture = future;
    await future;
    _addStreamFuture = null;
    return null;
  }

  @override
  Future<HttpClientResponse> close() async {
    return _result ??= _close();
  }

  @override
  Future flush() async {
    // Wait for added stream
    if (_addStreamFuture != null) {
      await _addStreamFuture;
      _addStreamFuture = null;
    }
  }

  Future<HttpClientResponse> _close() async {
    await flush();

    if (cookies.isNotEmpty) {
      _completer.completeError(StateError(
        'Attempted to send cookies, but XMLHttpRequest does not support them.',
      ));
      return _completer.future;
    }

    // Callback
    if (browserResponseType == null) {
      browserResponseType = 'arraybuffer';
      final accept = headers.value('Accept');
      if (accept != null) {
        final isText = isTextContentType(accept);
        if (isText) {
          browserResponseType = 'text';
        }
      }
    }

    final callback = client.onBrowserHttpClientRequestClose;
    if (callback != null) {
      await Future(() => callback(this));
    }
    try {
      final xhr = html.HttpRequest();

      // Set method and URI
      final method = this.method;
      final uriString = uri.toString();
      xhr.open(method, uriString);

      // Set response body type
      final browserResponseType = this.browserResponseType ?? 'arraybuffer';
      xhr.responseType = browserResponseType;

      // Timeout
      final timeout = client.connectionTimeout;
      if (timeout != null) {
        xhr.timeout = timeout.inMilliseconds;
      }

      // Credentials mode?
      final browserCredentialsMode = this.browserCredentialsMode;
      xhr.withCredentials = browserCredentialsMode;

      // Copy headers to html.HttpRequest
      final headers = this.headers;
      headers.forEach((name, values) {
        for (var value in values) {
          xhr.setRequestHeader(name, value);
        }
      });

      final headersCompleter = _completer;
      final controller = StreamController<Uint8List>();
      var bodySeenLength = 0;

      BrowserHttpClientResponse? currentHttpClientResponse;
      void completeHeaders() {
        if (headersCompleter.isCompleted) {
          return;
        }

        // Create HttpClientResponse
        final httpClientResponse = BrowserHttpClientResponse(
          this,
          xhr.status ?? 200,
          xhr.statusText ?? 'OK',
          controller.stream,
        );
        currentHttpClientResponse = httpClientResponse;

        final headers = httpClientResponse.headers;
        xhr.responseHeaders.forEach((name, value) {
          headers.add(name, value);
        });

        // Complete the future
        headersCompleter.complete(httpClientResponse);
      }

      void addChunk() {
        currentHttpClientResponse?.browserResponse = xhr.response;

        // Close stream
        if (!headersCompleter.isCompleted || controller.isClosed) {
          return;
        }
        final body = xhr.response;
        if (body == null) {
          return;
        } else if (body is String) {
          final chunk = body.substring(bodySeenLength);
          bodySeenLength = body.length;
          controller.add(Utf8Encoder().convert(chunk));
        } else if (body is ByteBuffer) {
          final chunk = Uint8List.view(body, bodySeenLength);
          bodySeenLength = body.lengthInBytes;
          controller.add(chunk);
        } else {
          return;
        }
      }

      xhr.onReadyStateChange.listen((event) {
        switch (xhr.readyState) {
          case html.HttpRequest.HEADERS_RECEIVED:
            // Complete future
            completeHeaders();
            break;
        }
      });

      xhr.onProgress.listen((html.ProgressEvent event) {
        addChunk();
      });

      // ignore: unawaited_futures
      xhr.onLoad.first.then((event) {
        addChunk();
        controller.close();
      });

      // ignore: unawaited_futures
      xhr.onTimeout.first.then((event) {
        if (!headersCompleter.isCompleted) {
          headersCompleter.completeError(TimeoutException('Timeout'));
        } else {
          controller.addError(TimeoutException('Timeout'));
          controller.close();
        }
      });

      final origin = html.window.origin;
      // ignore: unawaited_futures
      xhr.onError.first.then((html.ProgressEvent event) {
        // The underlying XMLHttpRequest API doesn't expose any specific
        // information about the error itself.
        //
        // We gather the information that we have and try to produce a
        // descriptive exception.
        final error = BrowserHttpClientException(
          method: method,
          url: uriString,
          origin: origin,
          headers: headers,
          browserResponseType: browserResponseType,
          browserCredentialsMode: browserCredentialsMode,
        );

        if (!headersCompleter.isCompleted) {
          // Complete future
          headersCompleter.completeError(error, StackTrace.current);
        } else if (!controller.isClosed) {
          // Close stream
          controller.addError(error);
          controller.close();
        }
      });

      final buffer = _buffer;
      if (buffer.isNotEmpty) {
        // Send with body
        xhr.send(Uint8List.fromList(buffer));
      } else {
        // Send without body
        xhr.send();
      }
    } catch (e) {
      // Something went wrong
      _completer.completeError(e);
    }
    return _completer.future;
  }

  /// Determines whether the content type is text.
  static bool isTextContentType(String value) {
    final contentType = ContentType.parse(value);
    switch (contentType.primaryType) {
      case 'application':
        switch (contentType.subType) {
          case 'grpc-web':
            return true;
          default:
            return false;
        }
      case 'text':
        return true;
      default:
        return false;
    }
  }

  static bool _httpMethodSupportsBody(String method) {
    switch (method) {
      case 'GET':
        return false;
      case 'HEAD':
        return false;
      case 'OPTIONS':
        return false;
      default:
        return true;
    }
  }
}

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

import '_browser_http_client_response_impl.dart';
import '_exports_in_browser.dart';
import '_http_headers_impl.dart';
import '_io_sink_base.dart';

class BrowserHttpClientRequestImpl extends IOSinkBase
    implements BrowserHttpClientRequest {
  final BrowserHttpClient client;

  String? _browserResponseType;

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

  Future<HttpClientResponse>? _result;

  final _buffer = Uint8Buffer();

  @override
  bool bufferOutput = false;

  @override
  int contentLength = -1;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = false;

  @internal
  BrowserHttpClientRequestImpl(this.client, this.method, this.uri)
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

  @override
  String? get browserResponseType => _browserResponseType;

  @override
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
    _checkAddRequirements();
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
    _checkAddRequirements();
    final future = stream.listen((item) {
      _buffer.addAll(item);
    }, onError: (error) {
      addError(error);
    }, cancelOnError: true).asFuture(null);
    _addStreamFuture = future;
    await future;
    _addStreamFuture = null;
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

  void _checkAddRequirements() {
    if (!_supportsBody) {
      throw StateError('HTTP method $method does not support body');
    }
    if (_completer.isCompleted) {
      throw StateError('StreamSink is closed');
    }
    if (_addStreamFuture != null) {
      throw StateError('StreamSink is bound to a stream');
    }
  }

  String _chooseBrowserResponseType() {
    final custom = browserResponseType;
    if (custom != null) {
      return custom;
    }
    final accept = headers.value('Accept');
    if (accept != null) {
      try {
        final contentType = ContentType.parse(accept);
        final textMimes = BrowserHttpClient.defaultTextMimes;
        if ((contentType.primaryType == 'text' &&
                textMimes.contains('text/*')) ||
            textMimes.contains(contentType.mimeType)) {
          return 'text';
        }
      } catch (error) {
        // Ignore error
      }
    }
    return 'arraybuffer';
  }

  Future<HttpClientResponse> _close() async {
    await flush();

    if (cookies.isNotEmpty) {
      _completer.completeError(StateError(
        'Attempted to send cookies, but XMLHttpRequest does not support them.',
      ));
      return _completer.future;
    }

    final browserResponseType = _chooseBrowserResponseType();
    _browserResponseType = browserResponseType;

    final callback = client.onBrowserHttpClientRequestClose;
    if (callback != null) {
      await callback(this);
    }

    try {
      final xhr = html.HttpRequest();

      // Set method and URI
      final method = this.method;
      final uriString = uri.toString();
      xhr.open(method, uriString);

      // Set response body type
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
      final streamController = StreamController<Uint8List>();
      streamController.onCancel = () {
        if (xhr.readyState != html.HttpRequest.DONE) {
          xhr.abort();
        }
      };
      BrowserHttpClientResponseImpl? currentHttpClientResponse;

      void completeHeaders() {
        if (headersCompleter.isCompleted) {
          return;
        }
        try {
          // Create HttpClientResponse
          final httpClientResponse = BrowserHttpClientResponseImpl(
            this,
            xhr.status ?? 200,
            xhr.statusText ?? 'OK',
            streamController.stream,
          );
          currentHttpClientResponse = httpClientResponse;
          final headers = httpClientResponse.headers;
          xhr.responseHeaders.forEach((name, value) {
            headers.add(name, value);
          });
          headersCompleter.complete(httpClientResponse);
          httpClientResponse.browserResponse = xhr.response;
        } catch (error, stackTrace) {
          headersCompleter.completeError(error, stackTrace);
        }
      }

      if (browserResponseType == 'text') {
        //
        // "text"
        //
        var seenTextLength = -1;
        void addTextChunk() {
          if (!streamController.isClosed) {
            final response = xhr.response;
            if (response is String) {
              final textChunk = seenTextLength < 0
                  ? response
                  : response.substring(seenTextLength);
              seenTextLength = response.length;
              streamController.add(Utf8Encoder().convert(textChunk));
            }
          }
        }

        xhr.onReadyStateChange.listen((event) {
          switch (xhr.readyState) {
            case html.HttpRequest.HEADERS_RECEIVED:
              completeHeaders();
              break;

            case html.HttpRequest.DONE:
              currentHttpClientResponse?.browserResponse = xhr.response;
              if (!streamController.isClosed) {
                addTextChunk();
                streamController.close();
              }
              break;
          }
        });
        streamController.onListen = () {
          addTextChunk();
          if (xhr.readyState == html.HttpRequest.DONE) {
            streamController.close();
          }
        };
        xhr.onProgress.listen((html.ProgressEvent event) {
          if (streamController.hasListener) {
            addTextChunk();
          }
        });
      } else if (browserResponseType == 'arraybuffer') {
        //
        // "arraybuffer"
        //
        xhr.onReadyStateChange.listen((event) {
          switch (xhr.readyState) {
            case html.HttpRequest.HEADERS_RECEIVED:
              completeHeaders();
              break;

            case html.HttpRequest.DONE:
              final object = xhr.response;
              currentHttpClientResponse?.browserResponse = object;
              if (!streamController.isClosed) {
                if (object is ByteBuffer) {
                  // "arraybuffer" response type
                  streamController.add(Uint8List.view(object));
                }
                streamController.close();
              }
              break;
          }
        });
      } else {
        //
        // Something else than "text" or "arraybuffer"
        //
        xhr.onReadyStateChange.listen((event) {
          switch (xhr.readyState) {
            case html.HttpRequest.HEADERS_RECEIVED:
              completeHeaders();
              break;

            case html.HttpRequest.DONE:
              currentHttpClientResponse?.browserResponse = xhr.response;
              if (!streamController.isClosed) {
                streamController.close();
              }
              break;
          }
        });
      }

      // ignore: unawaited_futures
      xhr.onTimeout.first.then((event) {
        if (!headersCompleter.isCompleted) {
          headersCompleter.completeError(
            TimeoutException(null, timeout),
            StackTrace.current,
          );
        }
        if (!streamController.isClosed) {
          streamController.addError(
            TimeoutException(null, timeout),
            StackTrace.current,
          );
          streamController.close();
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
          headersCompleter.completeError(error, StackTrace.current);
        }
        if (!streamController.isClosed) {
          streamController.addError(error, StackTrace.current);
          streamController.close();
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

  @override
  bool browserCredentialsMode = false;
}

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
import 'dart:typed_data';

import '../http/http.dart' show HttpHeadersImpl;
import '../io_impl_js.dart';
import 'http_client_request.dart';

/// Used by [_BrowserHttpClient].
class BrowserHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final HttpHeaders headers = HttpHeadersImpl('1.1');
  final BrowserHttpClientRequest request;

  /// Response object of _XHR_ request.
  ///
  /// You need to finish reading this [HttpClientResponse] to get the final
  /// value.
  dynamic browserResponse;

  List<Cookie>? _cookies;

  final Stream<Uint8List> _body;

  @override
  final String reasonPhrase;

  @override
  final int statusCode;

  BrowserHttpClientResponse(
    this.request,
    this.statusCode,
    this.reasonPhrase,
    this._body,
  );

  @override
  X509Certificate? get certificate => null;

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.decompressed;
  }

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  int get contentLength => -1;

  @override
  List<Cookie> get cookies {
    var cookies = _cookies;
    if (cookies == null) {
      cookies = <Cookie>[];
      final headerValues = headers[HttpHeaders.setCookieHeader] ?? <String>[];
      for (var headerValue in headerValues) {
        _cookies!.add(Cookie.fromSetCookieValue(headerValue));
      }
      _cookies = cookies;
    }
    return cookies;
  }

  @override
  bool get isRedirect {
    if (request.method == 'GET' || request.method == 'HEAD') {
      return statusCode == HttpStatus.movedPermanently ||
          statusCode == HttpStatus.permanentRedirect ||
          statusCode == HttpStatus.found ||
          statusCode == HttpStatus.seeOther ||
          statusCode == HttpStatus.temporaryRedirect;
    } else if (request.method == 'POST') {
      return statusCode == HttpStatus.seeOther;
    }
    return false;
  }

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  Future<Socket> detachSocket() {
    throw UnimplementedError();
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _body.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<HttpClientResponse> redirect(
      [String? method, Uri? url, bool? followLoops]) {
    final newUrl = url ?? Uri.parse(headers.value(HttpHeaders.locationHeader)!);
    return request.client
        .openUrl(method ?? request.method, newUrl)
        .then((newRequest) {
      request.headers.forEach((name, value) {
        newRequest.headers.add(name, value);
      });
      newRequest.followRedirects = true;
      return newRequest.close();
    });
  }
}

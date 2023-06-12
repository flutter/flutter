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

import 'dart:async';
import 'dart:io' as dart_io;

import 'package:universal_io/io.dart';

/// A client that receives content, such as web pages, from
/// a server using the HTTP protocol.
///
/// HttpClient contains a number of methods to send an [HttpClientRequest]
/// to an Http server and receive an [HttpClientResponse] back.
/// For example, you can use the [get], [getUrl], [post], and [postUrl] methods
/// for GET and POST requests, respectively.
///
/// ## Making a simple GET request: an example
///
/// A `getUrl` request is a two-step process, triggered by two [Future]s.
/// When the first future completes with a [HttpClientRequest], the underlying
/// network connection has been established, but no data has been sent.
/// In the callback function for the first future, the HTTP headers and body
/// can be set on the request. Either the first write to the request object
/// or a call to [close] sends the request to the server.
///
/// When the HTTP response is received from the server,
/// the second future, which is returned by close,
/// completes with an [HttpClientResponse] object.
/// This object provides access to the headers and body of the response.
/// The body is available as a stream implemented by HttpClientResponse.
/// If a body is present, it must be read. Otherwise, it leads to resource
/// leaks. Consider using [HttpClientResponse.drain] if the body is unused.
///
///     HttpClient client = HttpClient();
///     client.getUrl(Uri.parse("http://www.example.com/"))
///         .then((HttpClientRequest request) {
///           // Optionally set up headers...
///           // Optionally write to the request object...
///           // Then call close.
///           ...
///           return request.close();
///         })
///         .then((HttpClientResponse response) {
///           // Process the response.
///           ...
///         });
///
/// The future for [HttpClientRequest] is created by methods such as
/// [getUrl] and [open].
///
/// ## HTTPS connections
///
/// An HttpClient can make HTTPS requests, connecting to a server using
/// the TLS (SSL) secure networking protocol. Calling [getUrl] with an
/// https: scheme will work automatically, if the server's certificate is
/// signed by a root CA (certificate authority) on the default list of
/// well-known trusted CAs, compiled by Mozilla.
///
/// To add a custom trusted certificate authority, or to send a client
/// certificate to servers that request one, pass a [SecurityContext] object
/// as the optional `context` argument to the `HttpClient` constructor.
/// The desired security options can be set on the [SecurityContext] object.
///
/// ## Headers
///
/// All HttpClient requests set the following header by default:
///
///     Accept-Encoding: gzip
///
/// This allows the HTTP server to use gzip compression for the body if
/// possible. If this behavior is not desired set the
/// `Accept-Encoding` header to something else.
/// To turn off gzip compression of the response, clear this header:
///
///      request.headers.removeAll(HttpHeaders.acceptEncodingHeader)
///
/// ## Closing the HttpClient
///
/// The HttpClient supports persistent connections and caches network
/// connections to reuse them for multiple requests whenever
/// possible. This means that network connections can be kept open for
/// some time after a request has completed. Use HttpClient.close
/// to force the HttpClient object to shut down and to close the idle
/// network connections.
///
/// ## Turning proxies on and off
///
/// By default the HttpClient uses the proxy configuration available
/// from the environment, see [findProxyFromEnvironment]. To turn off
/// the use of proxies set the [findProxy] property to
/// `null`.
///
///     HttpClient client = HttpClient();
///     client.findProxy = null;
abstract class HttpClient implements dart_io.HttpClient {
  static const int defaultHttpPort = 80;
  static const int defaultHttpsPort = 443;

  /// Current state of HTTP request logging from all [HttpClient]s to the
  /// developer timeline.
  ///
  /// Default is `false`.
  static bool enableTimelineLogging = false;

  factory HttpClient({SecurityContext? context}) {
    var overrides = HttpOverrides.current;
    if (overrides == null) {
      return newUniversalHttpClient() as HttpClient;
    }
    return overrides.createHttpClient(context) as HttpClient;
  }

  /// Function for resolving the proxy server to be used for a HTTP
  /// connection from the proxy configuration specified through
  /// environment variables.
  ///
  /// The following environment variables are taken into account:
  ///
  ///     http_proxy
  ///     https_proxy
  ///     no_proxy
  ///     HTTP_PROXY
  ///     HTTPS_PROXY
  ///     NO_PROXY
  ///
  /// [:http_proxy:] and [:HTTP_PROXY:] specify the proxy server to use for
  /// http:// urls. Use the format [:hostname:port:]. If no port is used a
  /// default of 1080 will be used. If both are set the lower case one takes
  /// precedence.
  ///
  /// [:https_proxy:] and [:HTTPS_PROXY:] specify the proxy server to use for
  /// https:// urls. Use the format [:hostname:port:]. If no port is used a
  /// default of 1080 will be used. If both are set the lower case one takes
  /// precedence.
  ///
  /// [:no_proxy:] and [:NO_PROXY:] specify a comma separated list of
  /// postfixes of hostnames for which not to use the proxy
  /// server. E.g. the value "localhost,127.0.0.1" will make requests
  /// to both "localhost" and "127.0.0.1" not use a proxy. If both are set
  /// the lower case one takes precedence.
  ///
  /// To activate this way of resolving proxies assign this function to
  /// the [findProxy] property on the [HttpClient].
  ///
  ///     HttpClient client = HttpClient();
  ///     client.findProxy = HttpClient.findProxyFromEnvironment;
  ///
  /// If you don't want to use the system environment you can use a
  /// different one by wrapping the function.
  ///
  ///     HttpClient client = HttpClient();
  ///     client.findProxy = (url) {
  ///       return HttpClient.findProxyFromEnvironment(
  ///           url, environment: {"http_proxy": ..., "no_proxy": ...});
  ///     }
  ///
  /// If a proxy requires authentication it is possible to configure
  /// the username and password as well. Use the format
  /// [:username:password@hostname:port:] to include the username and
  /// password. Alternatively the API [addProxyCredentials] can be used
  /// to set credentials for proxies which require authentication.
  static String findProxyFromEnvironment(Uri url,
      {Map<String, String>? environment}) {
    return 'DIRECT';
  }
}

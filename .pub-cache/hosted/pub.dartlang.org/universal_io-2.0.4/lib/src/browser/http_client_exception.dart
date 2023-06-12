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

import 'dart:html' as html;

import '../io_impl_js.dart';

class BrowserHttpClientException implements SocketException {
  /// Can be used to disable verbose messages in development mode.
  static bool verbose = true;

  static final Set<String> _corsSimpleMethods = const {
    'GET',
    'HEAD',
    'POST',
  };

  final String method;
  final String url;
  final String? origin;
  final HttpHeaders headers;
  final bool browserCredentialsMode;
  final String browserResponseType;

  @override
  final OSError? osError = null;

  @override
  final InternetAddress? address = null;

  @override
  final int? port = null;

  BrowserHttpClientException({
    required this.method,
    required this.url,
    required this.origin,
    required this.headers,
    required this.browserCredentialsMode,
    required this.browserResponseType,
  });

  @override
  String get message => 'XMLHttpRequest (XHR) error';

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('XMLHttpRequest (XHR) error.');
    if (verbose) {
      assert(() {
        sb.write('\n');
        for (var i = 0; i < 80; i++) {
          sb.write('-');
        }
        sb.write('\n');

        // Write key details
        void addEntry(String key, String? value) {
          sb.write(key.padRight(30));
          sb.write(value);
          sb.write('\n');
        }

        final parsedUrl = Uri.parse(url);
        final isCrossOrigin = parsedUrl.origin != html.window.origin;
        addEntry('Request method: ', method);
        addEntry('Request URL: ', url);
        addEntry('Origin: ', origin);
        addEntry('Cross-origin: ', '$isCrossOrigin');
        addEntry('browserCredentialsMode: ', '$browserCredentialsMode');
        addEntry('browserResponseType: ', '$browserResponseType');
        sb.write(
          '''

THE REASON FOR THE XHR ERROR IS UNKNOWN.
(For security reasons, browsers do not explain XHR errors.)

Is the server down? Did the server have an internal error?

''',
        );

        // Warn about possible problem with missing CORS headers
        if (isCrossOrigin) {
          // List of header name that the server may need to whitelist
          final sortedHeaderNames = <String>[];
          headers.forEach((name, values) {
            sortedHeaderNames.add(name);
          });
          sortedHeaderNames.sort();
          if (browserCredentialsMode) {
            if (method != 'HEAD' && method != 'GET') {
              sb.write(
                'Did the server respond to a cross-origin "preflight" (OPTIONS) request?\n'
                '\n',
              );
            }
            sb.write(
              'Did the server respond with the following headers?\n'
              '  * Access-Control-Allow-Credentials: true\n'
              '    * Alternatively, disable "credentials mode".\n'
              '  * Access-Control-Allow-Origin: $origin\n'
              '    * In credentials mode, wildcard ("*") would not work!\n'
              '  * Access-Control-Allow-Methods: $method\n'
              '    * In credentials mode, wildcard ("*") would not work!\n',
            );
            if (sortedHeaderNames.isNotEmpty) {
              final joinedHeaderNames = sortedHeaderNames.join(', ');
              sb.write(
                '  * Access-Control-Allow-Headers: $joinedHeaderNames\n'
                '    * In credentials mode, wildcard ("*") would not work!\n',
              );
            }
          } else {
            sb.write("""
Enabling credentials mode would enable use of some HTTP headers in both the
request and the response. For example, credentials mode is required for
sending/receiving cookies. If you think you need to enable 'credentials mode',
do the following:

    final httpClientRequest = ...;
    if (httpClientRequest is BrowserHttpClientRequest) {
      httpClientRequest.browserCredentialsMode = true;
    }

""");
            if (method != 'HEAD' && method != 'GET') {
              sb.write(
                'Did the server respond to a cross-origin "preflight" (OPTIONS) request?\n'
                '\n',
              );
            }
            sb.write(
              'Did the server respond with the following headers?\n'
              '  * Access-Control-Allow-Origin: $origin\n'
              '    * You can also use wildcard ("*").\n'
              '    * Always required for cross-origin requests!\n',
            );
            if (!_corsSimpleMethods.contains(method)) {
              sb.write(
                '  * Access-Control-Allow-Methods: $method\n'
                '    * You can also use wildcard ("*").\n',
              );
            }

            if (sortedHeaderNames.isNotEmpty) {
              final joinedHeaderNames = sortedHeaderNames.join(', ');
              sb.write(
                '  * Access-Control-Allow-Headers: $joinedHeaderNames\n'
                '    * You can also use wildcard ("*").\n',
              );
            }
          }
        }
        sb.write(
          '\n'
          'Want shorter error messages? Set the following static field:\n'
          '    BrowserHttpException.verbose = false;\n',
        );
        // Write a line
        for (var i = 0; i < 80; i++) {
          sb.write('-');
        }
        sb.write('\n');
        return true;
      }());
    }
    return sb.toString();
  }
}

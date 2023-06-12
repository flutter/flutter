// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This contains a reader that accesses data using the HttpRequest
/// facility, and thus works only in the web browser.

library http_request_data_reader;

import 'dart:async';
import 'dart:html';
import 'intl_helpers.dart';

class HttpRequestDataReader implements LocaleDataReader {
  /// The base url from which we read the data.
  String url;
  HttpRequestDataReader(this.url);

  Future<String> read(String locale) {
    var request = HttpRequest();
    request.timeout = 5000;
    return _getString('$url$locale.json', request).then((r) => r.responseText!);
  }

  /// Read a string with the given request. This is a stripped down copy
  /// of HttpRequest getString, but was the simplest way I could find to
  /// issue a request with a timeout.
  Future<HttpRequest> _getString(String url, HttpRequest xhr) {
    var completer = Completer<HttpRequest>();
    xhr.open('GET', url, async: true);
    xhr.onLoad.listen((e) {
      // Note: file:// URIs have status of 0.
      if ((xhr.status! >= 200 && xhr.status! < 300) ||
          xhr.status == 0 ||
          xhr.status == 304) {
        completer.complete(xhr);
      } else {
        completer.completeError(e);
      }
    });

    xhr.onError.listen(completer.completeError);
    xhr.send();

    return completer.future;
  }
}

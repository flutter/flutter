// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;

class RequestImpl extends http.BaseRequest {
  final Stream<List<int>> _stream;

  RequestImpl(String method, Uri url, [Stream<List<int>>? stream])
      : _stream = stream ?? const Stream.empty(),
        super(method, url);

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_stream);
  }
}

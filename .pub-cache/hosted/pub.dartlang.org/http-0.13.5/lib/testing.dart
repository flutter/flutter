// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains testing classes for the HTTP library.
///
/// The [MockClient] class is a drop-in replacement for `http.Client` that
/// allows test code to set up a local request handler in order to fake a server
/// that responds to HTTP requests:
///
///     import 'dart:convert';
///     import 'package:http/testing.dart';
///
///     var client = MockClient((request) async {
///       if (request.url.path != "/data.json") {
///         return Response("", 404);
///       }
///       return Response(
///           json.encode({
///             'numbers': [1, 4, 15, 19, 214]
///           }),
///           200,
///           headers: {'content-type': 'application/json'});
///     });
library http.testing;

import 'src/mock_client.dart';

export 'src/mock_client.dart';

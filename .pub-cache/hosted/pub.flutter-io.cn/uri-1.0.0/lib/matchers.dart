// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uri.matchers;

import 'package:matcher/matcher.dart' show Matcher, anything, isA;

/// Matches the individual parts of a [Uri]. If a matcher is not specified for a
/// part, the default matcher is [anything]. This allows you to just match on a
/// single part, like the scheme, while ignoring the rest.
Matcher matchesUri({
  Object? fragment = anything,
  Object? host = anything,
  Object? path = anything,
  Object? port = anything,
  Object? queryParameters = anything,
  Object? scheme = anything,
  Object? userInfo = anything,
}) =>
    isA<Uri>()
        .having((e) => e.fragment, 'fragment', fragment)
        .having((e) => e.host, 'host', host)
        .having((e) => e.path, 'path', path)
        .having((e) => e.port, 'port', port);

/*
      _feature('Uri', 'path', path, (i) => i.path),
      _feature('Uri', 'port', port, (i) => i.port),
      _feature(
          'Uri', 'queryParameters', queryParameters, (i) => i.queryParameters),
      _feature('Uri', 'scheme', scheme, (i) => i.scheme),
      _feature('Uri', 'userInfo', userInfo, (i) => userInfo)
    ]);
*/

/// Matches the parts of a [Uri] against [expected], all of which must equal for
/// the match to pass.
Matcher equalsUri(Uri expected) => matchesUri(
      fragment: expected.fragment,
      host: expected.host,
      path: expected.path,
      port: expected.port,
      queryParameters: expected.queryParameters,
      scheme: expected.scheme,
      userInfo: expected.userInfo,
    );

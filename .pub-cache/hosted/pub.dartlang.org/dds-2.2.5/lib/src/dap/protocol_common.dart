// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

/// A base class for (spec-generated) classes that represent the `body` of a an
/// event.
abstract class EventBody {
  static bool canParse(Object? obj) => obj is Map<String, Object?>?;
}

/// A generic event body class that just supplies an object directly.
///
/// Used to support custom events sent by the debug adapter such as 'dart.log'.
///
/// The supplied [body] must be convertable to JSON.
class RawEventBody extends EventBody {
  final Object body;

  RawEventBody(this.body)
      : assert(() {
          try {
            jsonEncode(body);
            return true;
          } catch (e) {
            return false;
          }
        }(), 'body should be JSON encodable');

  Object toJson() => body;
}

/// A generic arguments class that just supplies the arguments map directly.
///
/// Used to support custom requests that may be provided by other implementing
/// adapters that are not known at compile time by DDS/base DAP.
class RawRequestArguments extends RequestArguments {
  final Map<String, Object?> args;

  RawRequestArguments.fromMap(this.args);

  static RawRequestArguments fromJson(Map<String, Object?> obj) =>
      RawRequestArguments.fromMap(obj);
}

/// A base class for (spec-generated) classes that represent the `arguments` of
/// a request.
abstract class RequestArguments {
  static bool canParse(Object? obj) => obj is Map<String, Object?>?;
}

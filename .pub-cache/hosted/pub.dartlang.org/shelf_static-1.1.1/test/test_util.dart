// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_static/src/util.dart';
import 'package:test/test.dart';

final p.Context _ctx = p.url;

/// Makes a simple GET request to [handler] and returns the result.
Future<Response> makeRequest(
  Handler handler,
  String path, {
  String? handlerPath,
  Map<String, String>? headers,
  String method = 'GET',
}) async {
  final rootedHandler = _rootHandler(handlerPath, handler);
  return rootedHandler(_fromPath(path, headers, method: method));
}

Request _fromPath(
  String path,
  Map<String, String>? headers, {
  required String method,
}) =>
    Request(method, Uri.parse('http://localhost$path'), headers: headers);

Handler _rootHandler(String? path, Handler handler) {
  if (path == null || path.isEmpty) {
    return handler;
  }

  return (Request request) {
    if (!_ctx.isWithin('/$path', request.requestedUri.path)) {
      return Response.notFound('not found');
    }
    assert(request.handlerPath == '/');

    final relativeRequest = request.change(path: path);

    return handler(relativeRequest);
  };
}

Matcher atSameTimeToSecond(DateTime value) =>
    _SecondResolutionDateTimeMatcher(value);

class _SecondResolutionDateTimeMatcher extends Matcher {
  final DateTime _target;

  _SecondResolutionDateTimeMatcher(DateTime target)
      : _target = toSecondResolution(target);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! DateTime) return false;

    return _datesEqualToSecond(_target, item);
  }

  @override
  Description describe(Description description) =>
      description.add('Must be at the same moment as $_target with resolution '
          'to the second.');
}

bool _datesEqualToSecond(DateTime d1, DateTime d2) =>
    toSecondResolution(d1).isAtSameMomentAs(toSecondResolution(d2));

// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';

class MockSource implements Source {
  final String? _path;
  final Uri? _uri;

  MockSource({String? path, Uri? uri})
      : _path = path,
        _uri = uri;

  @override
  String get fullName => _path!;

  @override
  Uri get uri => _uri!;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

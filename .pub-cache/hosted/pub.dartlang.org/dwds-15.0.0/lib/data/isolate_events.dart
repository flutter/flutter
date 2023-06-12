// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'isolate_events.g.dart';

/// An event that signifies the main isolate has exited.
abstract class IsolateExit implements Built<IsolateExit, IsolateExitBuilder> {
  static Serializer<IsolateExit> get serializer => _$isolateExitSerializer;

  factory IsolateExit([Function(IsolateExitBuilder) updates]) = _$IsolateExit;

  IsolateExit._();
}

/// An event that signifies the main isolate has started.
abstract class IsolateStart
    implements Built<IsolateStart, IsolateStartBuilder> {
  static Serializer<IsolateStart> get serializer => _$isolateStartSerializer;

  factory IsolateStart([Function(IsolateStartBuilder) updates]) =
      _$IsolateStart;

  IsolateStart._();
}

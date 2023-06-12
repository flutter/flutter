// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'debug_event.g.dart';

abstract class DebugEvent implements Built<DebugEvent, DebugEventBuilder> {
  static Serializer<DebugEvent> get serializer => _$debugEventSerializer;

  factory DebugEvent([Function(DebugEventBuilder) updates]) = _$DebugEvent;

  DebugEvent._();

  String get kind;

  String get eventData;

  int get timestamp;
}

/// A batched group of events, currently always Debugger.scriptParsed
abstract class BatchedDebugEvents
    implements Built<BatchedDebugEvents, BatchedDebugEventsBuilder> {
  static Serializer<BatchedDebugEvents> get serializer =>
      _$batchedDebugEventsSerializer;

  factory BatchedDebugEvents([Function(BatchedDebugEventsBuilder) updates]) =
      _$BatchedDebugEvents;

  BatchedDebugEvents._();

  BuiltList<DebugEvent> get events;
}

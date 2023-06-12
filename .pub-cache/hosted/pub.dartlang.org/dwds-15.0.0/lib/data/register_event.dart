// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_event.g.dart';

abstract class RegisterEvent
    implements Built<RegisterEvent, RegisterEventBuilder> {
  static Serializer<RegisterEvent> get serializer => _$registerEventSerializer;

  factory RegisterEvent([Function(RegisterEventBuilder) updates]) =
      _$RegisterEvent;

  RegisterEvent._();

  String get eventData;

  int get timestamp;
}

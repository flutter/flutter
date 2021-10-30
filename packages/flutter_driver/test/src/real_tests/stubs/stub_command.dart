// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';

class StubNestedCommand extends CommandWithTarget {
  StubNestedCommand(SerializableFinder finder, this.times, {Duration? timeout})
      : super(finder, timeout: timeout);

  StubNestedCommand.deserialize(
      Map<String, String> json, DeserializeFinderFactory finderFactory)
      : times = int.parse(json['times']!),
        super.deserialize(json, finderFactory);

  @override
  Map<String, String> serialize() {
    return super.serialize()..addAll(<String, String>{'times': '$times'});
  }

  @override
  String get kind => 'StubNestedCommand';

  final int times;
}

class StubProberCommand extends CommandWithTarget {
  StubProberCommand(SerializableFinder finder, this.times, {Duration? timeout})
      : super(finder, timeout: timeout);

  StubProberCommand.deserialize(Map<String, String> json, DeserializeFinderFactory finderFactory)
      : times = int.parse(json['times']!),
        super.deserialize(json, finderFactory);

  @override
  Map<String, String> serialize() {
    return super.serialize()..addAll(<String, String>{'times': '$times'});
  }

  @override
  String get kind => 'StubProberCommand';

  final int times;
}

class StubCommandResult extends Result {
  const StubCommandResult(this.resultParam);

  final String resultParam;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'resultParam': resultParam,
    };
  }
}

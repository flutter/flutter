// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';

class StubCommand extends CommandWithTarget {
  StubCommand(SerializableFinder finder, this.times) : super(finder);

  StubCommand.deserialize(Map<String, String> json, DeserializeFinderFactory finderFactory)
      : times = int.parse(json['times']!),
        super.deserialize(json, finderFactory);

  @override
  String get kind => 'StubCommand';

  final int times;
}

class StubCommandResult extends Result {
  const StubCommandResult(this.resultParam);

  final String resultParam;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'resultParam': resultParam,
  };
}
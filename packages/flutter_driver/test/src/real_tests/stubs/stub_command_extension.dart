// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/common/factory.dart';
import 'package:flutter_driver/src/common/message.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stub_command.dart';

class StubCommandExtension extends CommandExtension {
  @override
  String get commandKind => 'StubCommand';

  @override
  Future<Result> call(Command command, CreateFinderFactory finderFactory, CommandHandlerFactory handlerFactory) async {
    final StubCommand stubCommand = command as StubCommand;
    for (int i = 0; i < stubCommand.times; i++) {
      await handlerFactory.handleCommand(Tap(stubCommand.finder, timeout: stubCommand.timeout), finderFactory);
    }
    return const StubCommandResult('stub response');
  }

  @override
  Command deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory, DeserializeCommandFactory commandFactory) {
    return StubCommand.deserialize(params, finderFactory);
  }
}

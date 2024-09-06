// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart';

const CommandExtension nativeDriverExtension = _NativeDriverExtension();

final class _NativeDriverExtension implements CommandExtension {
  const _NativeDriverExtension();

  @override
  Future<Result> call(
    Command command,
    WidgetController prober,
    CreateFinderFactory finderFactory,
    CommandHandlerFactory handlerFactory,
  ) {
    throw UnimplementedError();
  }

  @override
  String get commandKind => 'native_driver';

  @override
  Command deserialize(
    Map<String, String> params,
    DeserializeFinderFactory finderFactory,
    DeserializeCommandFactory commandFactory,
  ) {
    throw UnimplementedError();
  }
}

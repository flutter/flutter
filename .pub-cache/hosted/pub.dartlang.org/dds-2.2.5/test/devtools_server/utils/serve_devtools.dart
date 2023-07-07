// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/devtools_server.dart';

import '../../common/test_helper.dart';

void main(List<String> args) async {
  unawaited(
    DevToolsServer().serveDevToolsWithArgs(
      args,
      customDevToolsPath:
          devtoolsAppUri(prefix: '../../../../../').toFilePath(),
    ),
  );
}

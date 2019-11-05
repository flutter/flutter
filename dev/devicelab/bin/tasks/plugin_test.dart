// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/tasks/plugin_tests.dart';
import 'package:flutter_devicelab/framework/framework.dart';

Future<void> main() async {
  await task(combine(<TaskFunction>[
    PluginTest('apk', <String>['-a', 'java']),
    PluginTest('apk', <String>['-a', 'kotlin']),
    // These create the plugins using the new v2 plugin templates but create the
    // apps using the old v1 embedding app templates to make sure new plugins
    // are by default backward compatible.
    PluginTest('apk', <String>['-a', 'java'], pluginCreateEnvironment:
        <String, String>{'ENABLE_ANDROID_EMBEDDING_V2': 'true'}),
    PluginTest('apk', <String>['-a', 'kotlin'], pluginCreateEnvironment:
        <String, String>{'ENABLE_ANDROID_EMBEDDING_V2': 'true'}),
  ]));
}

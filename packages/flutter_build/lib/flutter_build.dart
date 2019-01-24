// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:build/build.dart';

import 'src/kernel_builder.dart';

Builder flutterKernelBuilder(BuilderOptions builderOptions) {
  final Map<String, Object> config = builderOptions.config;
  final List<Object> extraFrontEndOptions = config['extraFrontEndOptions'];
  return FlutterKernelBuilder(
    aot: config['aot'],
    disabled: config['disabled'],
    engineDartBinaryPath: config['engineDartBinaryPath'],
    frontendServerPath: config['frontendServerPath'],
    incrementalCompilerByteStorePath: config['incrementalCompilerByteStorePath'],
    linkPlatformKernelIn: config['linkPlatformKernelIn'],
    mainPath: config['mainPath'],
    packagesPath: config['packagesPath'],
    sdkRoot: config['sdkRoot'],
    targetProductVm: config['targetProductVm'],
    trackWidgetCreation: config['trackWidgetCreation'],
    extraFrontEndOptions: extraFrontEndOptions.cast<String>(),
  );
}

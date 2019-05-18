// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as path;

import 'src/dev_compiler_builder.dart';

const String _kFlutterSdkConfig = 'flutter_sdk_dir';

Builder webEntrypointBuilder(BuilderOptions options) =>
    WebEntrypointBuilder.fromOptions(options);

Builder ddcMetaModuleBuilder(BuilderOptions options) =>
    MetaModuleBuilder.forOptions(flutterDdcPlatform, options);

Builder ddcMetaModuleCleanBuilder(_) => MetaModuleCleanBuilder(flutterDdcPlatform);

Builder ddcModuleBuilder([_]) => ModuleBuilder(flutterDdcPlatform);

Builder ddcBuilder(BuilderOptions options) {
  return DevCompilerBuilder(
    options.config[_kFlutterSdkConfig],
  );
}

Builder ddcKernelBuilder(BuilderOptions options) => KernelBuilder(
  summaryOnly: true,
  sdkKernelPath: path.url.join('lib', '_internal', 'ddc_sdk.dill'),
  outputExtension: ddcKernelExtension,
  platform: flutterDdcPlatform,
  useIncrementalCompiler: true,
  platformSdk: options.config[_kFlutterSdkConfig],
);

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_cli/native_assets_cli_internal.dart';

import '../../../globals.dart' as globals;
import '../../../windows/visual_studio.dart';

Future<CCompilerConfigImpl> cCompilerConfigWindows() async {
  final VisualStudio visualStudio = VisualStudio(
    fileSystem: globals.fs,
    platform: globals.platform,
    logger: globals.logger,
    processManager: globals.processManager,
    osUtils: globals.os,
  );

  return CCompilerConfigImpl(
    compiler: _toOptionalFileUri(visualStudio.clPath),
    linker: _toOptionalFileUri(visualStudio.linkPath),
    archiver: _toOptionalFileUri(visualStudio.libPath),
    envScript: _toOptionalFileUri(visualStudio.vcvarsPath),
    envScriptArgs: <String>[],
  );
}

Uri? _toOptionalFileUri(String? string) {
  if (string == null) {
    return null;
  }
  return Uri.file(string);
}

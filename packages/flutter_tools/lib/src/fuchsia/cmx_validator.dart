// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import '../base/common.dart';
import '../base/file_system.dart';
import '../project.dart';

Future<void> validateCmxFile(FuchsiaProject fuchsiaProject) async {
  final String appName = fuchsiaProject.project.manifest.appName;
  final String cmxPath = fs.path.join(fuchsiaProject.meta.path, '$appName.cmx');
  final File cmxFile = fs.file(cmxPath);
  if (!await cmxFile.exists()) {
    throwToolExit('The Fuchsia build requires a .cmx file at $cmxPath for the app: $appName.');
  }
}

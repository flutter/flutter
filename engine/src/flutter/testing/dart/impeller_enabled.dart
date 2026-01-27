// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

bool get impellerEnabled => Platform.executableArguments.contains('--enable-impeller');

String? get impellerBackend {
  if (!impellerEnabled) {
    return null;
  }
  const backendFlag = '--impeller-backend=';
  for (final String arg in Platform.executableArguments) {
    if (arg.startsWith(backendFlag)) {
      return arg.substring(backendFlag.length);
    }
  }
  if (Platform.isMacOS || Platform.isIOS) {
    return 'metal';
  }
  return 'vulkan';
}

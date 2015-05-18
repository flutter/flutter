// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
* This script should be invoked via 'pub run' after 'pub get':
* $ pub run sky:init
* NOTE: The 'dart' executable must be on your $PATH for this script to work.
*/

import 'dart:io';

main(List<String> arguments) {
  ProcessResult result = Process.runSync('dart', ['-p', 'packages', 'packages/mojom/generate.dart']);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
}

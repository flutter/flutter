// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Updates a Dart executable with a manifest.

import 'dart:io';

import 'package:win32/win32.dart';

void main(List<String> args) {
  if (args.length != 2) {
    print('update_resource <executable> <manifest>');
    print('\nUpdates an executable with the specified manifest.');
    print('Example: update_resource myApp.exe myApp.manifest');
  }

  final manifest = File(args[1]).readAsStringSync();
  final manifestPtr = TEXT(manifest);
  final filenamePtr = TEXT(args[0]);

  final handle = BeginUpdateResource(filenamePtr, FALSE);
  if (handle == NULL) {
    print("Error: couldn't get handle to executable to be updated.");
    return;
  }

  var result = UpdateResource(
      handle, RT_MANIFEST, RT_MANIFEST, 0, manifestPtr, manifest.length * 2);
  if (result == FALSE) {
    print('Error: failed to create update resource.');
  }

  result = EndUpdateResource(handle, FALSE);
  if (result == FALSE) {
    print('Error: failed to write updated resources to executable.');
  }

  print('Update succeeded.');
}

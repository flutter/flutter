// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

LoadBundleTaskState convertToTaskState(String state) {
  switch (state) {
    case 'running':
      return LoadBundleTaskState.running;
    case 'success':
      return LoadBundleTaskState.success;
    case 'error':
      return LoadBundleTaskState.error;
    default:
      throw UnsupportedError('Unknown LoadBundleTaskState value: $state.');
  }
}

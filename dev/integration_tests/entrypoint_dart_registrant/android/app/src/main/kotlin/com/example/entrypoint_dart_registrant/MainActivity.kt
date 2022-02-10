// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.entrypoint_dart_registrant

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
  override fun getDartEntrypointFunctionName(): String {
    return "entrypoint"
  }
}

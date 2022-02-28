// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void passMessage(String message) native 'PassMessage';

bool didCallRegistrantBeforeEntrypoint = false;

// Test the Dart plugin registrant.
@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (didCallRegistrantBeforeEntrypoint) {
      throw '_registerPlugins is being called twice';
    }
    didCallRegistrantBeforeEntrypoint = true;
  }

}


@pragma('vm:entry-point')
void mainForPluginRegistrantTest() {
  if (didCallRegistrantBeforeEntrypoint) {
    passMessage('_PluginRegistrant.register() was called');
  } else {
    passMessage('_PluginRegistrant.register() was not called');
  }
}

void main() {}

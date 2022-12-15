// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'system_channels.dart';

/// Utility methods for interacting with the system's live text.
class LiveText {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  LiveText._();

  /// Get this device live text input availability.
  static Future<bool> isLiveTextInputAvailable() async {
    final bool supportLiveTextInput =
        await SystemChannels.platform.invokeMethod('LiveText.isLiveTextInputAvailable') ?? false;
    return supportLiveTextInput;
  }
}

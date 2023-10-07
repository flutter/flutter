// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'system_channels.dart';

/// Utility methods for interacting with the system's Live Text.
///
/// For example, the Live Text input feature of iOS turns the keyboard into a camera view for
/// directly inserting text obtained through OCR into the active field.
///
/// See also:
///  * <https://developer.apple.com/documentation/uikit/uiresponder/3778577-capturetextfromcamera>
///  * <https://support.apple.com/guide/iphone/use-live-text-iphcf0b71b0e/ios>
class LiveText {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  LiveText._();

  /// Returns true if the Live Text input feature is available on the current device.
  static Future<bool> isLiveTextInputAvailable() async {
    final bool supportLiveTextInput =
        await SystemChannels.platform.invokeMethod('LiveText.isLiveTextInputAvailable') ?? false;
    return supportLiveTextInput;
  }

  /// Start Live Text input.
  ///
  /// If any [TextInputConnection] is currently active, calling this method will tell the text field
  /// to start Live Text input. If the current device doesn't support Live Text input,
  /// nothing will happen.
  static void startLiveTextInput() {
    SystemChannels.textInput.invokeMethod('TextInput.startLiveTextInput');
  }
}

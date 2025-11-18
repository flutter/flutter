// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';

String _accessibilityPlaceholderMessage = 'Enable accessibility';

/// The message in the label for the placeholder element used to enable accessibility.
///
/// This uses US English as the default message. Set this value at any time to update the label
/// in the placeholder element.
String get accessibilityPlaceholderMessage => _accessibilityPlaceholderMessage;
set accessibilityPlaceholderMessage(String message) {
  if (message == _accessibilityPlaceholderMessage) {
    return;
  }

  _accessibilityPlaceholderMessage = message;
  EngineSemantics.instance.semanticsHelper.updatePlaceholderLabel(message);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view.accessibility.configurator;

import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.view.AccessibilityBridge;

public interface AccessibilityNodeConfigurator {
  void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node);
}

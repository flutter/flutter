// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view.accessibility;

import android.view.accessibility.AccessibilityNodeInfo;

public interface AccessibilityNodeConfigurator {
  void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TEXT_INPUT_PLUGIN_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TEXT_INPUT_PLUGIN_DELEGATE_H_

#include "flutter/shell/platform/common/geometry.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class TextInputPluginDelegate {
 public:
  // Notifies the delegate of the updated the cursor rect in Flutter root view
  // coordinates.
  virtual void OnCursorRectUpdated(const Rect& rect) = 0;

  // Notifies the delegate that the system IME composing state should be reset.
  virtual void OnResetImeComposing() = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TEXT_INPUT_PLUGIN_DELEGATE_H_

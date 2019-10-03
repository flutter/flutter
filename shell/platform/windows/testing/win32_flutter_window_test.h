// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windowsx.h>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/win32_flutter_window.h"

namespace flutter {
namespace testing {

class Win32FlutterWindowTest : public Win32FlutterWindow {
 public:
  Win32FlutterWindowTest(int width, int height);

  ~Win32FlutterWindowTest();

  // |Win32Window|
  void OnFontChange() override;

  bool OnFontChangeWasCalled();

 private:
  bool on_font_change_called_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Win32FlutterWindowTest);
};

}  // namespace testing
}  // namespace flutter

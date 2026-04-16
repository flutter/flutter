// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_WINDOW_HIT_TEST_RESPONSE_H_
#define FLUTTER_LIB_UI_WINDOW_HIT_TEST_RESPONSE_H_

namespace flutter {

// Represents a hit test response.
struct HitTestResponse {
  // Whether the hit test result contains a platform view.
  bool has_platform_view;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_WINDOW_HIT_TEST_RESPONSE_H_

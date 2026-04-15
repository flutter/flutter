// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_WINDOW_HIT_TEST_RESPONSE_H_
#define FLUTTER_LIB_UI_WINDOW_HIT_TEST_RESPONSE_H_

namespace flutter {

// Represents a hit test response.
struct HitTestResponse {
  // Whether the first hit test entry is a platform view.
  //
  // The first hit test entry is typically the child that is
  // visually "on top" (i.e., paints later).
  bool is_platform_view;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_WINDOW_HIT_TEST_RESPONSE_H_

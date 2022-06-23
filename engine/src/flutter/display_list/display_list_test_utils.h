// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_COMPLEXITY_UNITTESTS_H_
#define FLUTTER_FLOW_DISPLAY_LIST_COMPLEXITY_UNITTESTS_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"

#include "third_party/skia/include/core/SkPicture.h"

namespace flutter {
namespace testing {

sk_sp<DisplayList> GetSampleDisplayList();
sk_sp<DisplayList> GetSampleDisplayList(int ops);
sk_sp<DisplayList> GetSampleNestedDisplayList();

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_COMPLEXITY_UNITTESTS_H_

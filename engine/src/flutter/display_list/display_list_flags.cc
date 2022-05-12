// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_flags.h"
#include "flutter/display_list/display_list_path_effect.h"
namespace flutter {

const DisplayListSpecialGeometryFlags DisplayListAttributeFlags::WithPathEffect(
    const DlPathEffect* effect) const {
  if (is_geometric() && effect) {
    if (effect->asDash()) {
      // A dash effect has a very simple impact. It cannot introduce any
      // miter joins that weren't already present in the original path
      // and it does not grow the bounds of the path, but it can add
      // end caps to areas that might not have had them before so all
      // we need to do is to indicate the potential for diagonal
      // end caps and move on.
      return special_flags_.with(kMayHaveCaps_ | kMayHaveDiagonalCaps_);
    } else {
      // An arbitrary path effect can introduce joins at an arbitrary
      // angle and may change the geometry of the end caps
      return special_flags_.with(kMayHaveCaps_ | kMayHaveDiagonalCaps_ |
                                 kMayHaveJoins_ | kMayHaveAcuteJoins_);
    }
  }
  return special_flags_;
}

}  // namespace flutter

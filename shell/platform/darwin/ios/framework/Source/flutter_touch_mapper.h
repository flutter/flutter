// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_TOUCH_MAPPER_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_TOUCH_MAPPER_H_

#include <UIKit/UIKit.h>

#include "lib/fxl/macros.h"

#include <map>

namespace shell {

/// UITouch pointers cannot be used as touch ids (even though they remain
/// constant throughout the multitouch sequence) because internal components
/// assume that ids are < 16. This class maps touch pointers to ids
class TouchMapper {
 public:
  TouchMapper();
  ~TouchMapper();

  int registerTouch(UITouch* touch);

  int unregisterTouch(UITouch* touch);

  int identifierOf(UITouch* touch) const;

 private:
  using BitSet = long long int;
  BitSet free_spots_;
  std::map<UITouch*, int> touch_map_;

  FXL_DISALLOW_COPY_AND_ASSIGN(TouchMapper);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_TOUCH_MAPPER_H_

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/critical_closure.h"

#import <UIKit/UIKit.h>

namespace base {
namespace internal {

bool IsMultiTaskingSupported() {
  return [[UIDevice currentDevice] isMultitaskingSupported];
}

}  // namespace internal
}  // namespace base

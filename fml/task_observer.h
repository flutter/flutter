// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_TASK_OBSERVER_H_
#define FLUTTER_FML_TASK_OBSERVER_H_

#include "lib/fxl/macros.h"

namespace fml {

class TaskObserver {
 public:
  virtual ~TaskObserver() = default;

  virtual void DidProcessTask() = 0;
};

}  // namespace fml

#endif  // FLUTTER_FML_TASK_OBSERVER_H_

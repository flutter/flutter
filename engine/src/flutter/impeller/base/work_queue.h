// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"

namespace impeller {

class WorkQueue : public std::enable_shared_from_this<WorkQueue> {
 public:
  virtual ~WorkQueue();

  virtual void PostTask(fml::closure task) = 0;

 protected:
  WorkQueue();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(WorkQueue);
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_SKIA_CONCURRENT_EXECUTOR_H_
#define FLUTTER_RUNTIME_SKIA_CONCURRENT_EXECUTOR_H_

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkExecutor.h"

namespace flutter {

class SkiaConcurrentExecutor : public SkExecutor {
 public:
  using OnWorkCallback = std::function<void(fml::closure work)>;
  SkiaConcurrentExecutor(OnWorkCallback on_work);

  ~SkiaConcurrentExecutor() override;

  void add(fml::closure work) override;

 private:
  OnWorkCallback on_work_;

  FML_DISALLOW_COPY_AND_ASSIGN(SkiaConcurrentExecutor);
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_SKIA_CONCURRENT_EXECUTOR_H_

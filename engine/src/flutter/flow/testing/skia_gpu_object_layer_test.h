// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TESTING_SKIA_GPU_OBJECT_LAYER_TEST_H_
#define FLOW_TESTING_SKIA_GPU_OBJECT_LAYER_TEST_H_

#include "flutter/flow/skia_gpu_object.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/testing/thread_test.h"

namespace flutter {
namespace testing {

// This fixture allows generating tests that create |SkiaGPUObject|'s which
// are destroyed on a |SkiaUnrefQueue|.
class SkiaGPUObjectLayerTest : public LayerTestBase<ThreadTest> {
 public:
  SkiaGPUObjectLayerTest();

  fml::RefPtr<SkiaUnrefQueue> unref_queue() { return unref_queue_; }

 private:
  fml::RefPtr<SkiaUnrefQueue> unref_queue_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLOW_TESTING_SKIA_GPU_OBJECT_LAYER_TEST_H_

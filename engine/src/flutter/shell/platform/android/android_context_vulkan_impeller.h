// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_VULKAN_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_VULKAN_IMPELLER_H_

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"

namespace flutter {

class AndroidContextVulkanImpeller : public AndroidContext {
 public:
  AndroidContextVulkanImpeller(
      bool enable_validation,
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner);

  ~AndroidContextVulkanImpeller();

  // |AndroidContext|
  bool IsValid() const override;

 private:
  fml::RefPtr<vulkan::VulkanProcTable> proc_table_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContextVulkanImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_VULKAN_IMPELLER_H_

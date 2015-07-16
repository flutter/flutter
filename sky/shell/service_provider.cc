// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/service_provider.h"

#include "base/single_thread_task_runner.h"

namespace sky {
namespace shell {

ServiceProviderContext::ServiceProviderContext(
    scoped_refptr<base::SingleThreadTaskRunner> runner)
      : platform_task_runner(runner.Pass()) {}

ServiceProviderContext::~ServiceProviderContext() {
}

}  // namespace shell
}  // namespace sky

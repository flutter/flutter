// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_CONFIG_GPU_INFO_COLLECTOR_LINUX_H_
#define GPU_CONFIG_GPU_INFO_COLLECTOR_LINUX_H_

#include <string>

namespace gpu {

// Queries for the driver version. Returns an empty string on failure.
std::string CollectDriverVersionNVidia();

}  // namespace gpu

#endif  // GPU_CONFIG_GPU_INFO_COLLECTOR_LINUX_H_

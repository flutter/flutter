// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/cpu_affinity.h"

namespace fml {

/// @brief Request the given affinity for the current thread.
///
///        Returns true if successfull, or if it was a no-op. This function is
///        only supported on Android devices.
///
///        Affinity requests are based on documented CPU speed. This speed data
///        is parsed from cpuinfo_max_freq files, see also:
///        https://www.kernel.org/doc/Documentation/cpu-freq/user-guide.txt
bool RequestAffinity(CpuAffinity affinity);

}  // namespace fml

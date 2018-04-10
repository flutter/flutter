// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_RUNTIME_INIT_H_
#define FLUTTER_RUNTIME_RUNTIME_INIT_H_

#include <inttypes.h>
#include <string>

namespace blink {

void InitRuntime(const uint8_t* vm_snapshot_data,
                 const uint8_t* vm_snapshot_instructions,
                 const uint8_t* default_isolate_snapshot_data,
                 const uint8_t* default_isolate_snapshot_instructions,
                 const std::string& bundle_path);

}  // namespace blink

#endif  // FLUTTER_RUNTIME_RUNTIME_INIT_H_

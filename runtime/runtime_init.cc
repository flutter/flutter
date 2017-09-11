// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/runtime_init.h"

#include "flutter/glue/trace_event.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/runtime/platform_impl.h"
#include "flutter/sky/engine/public/web/Sky.h"
#include "lib/fxl/logging.h"

namespace blink {
namespace {

PlatformImpl* g_platform_impl = nullptr;

}  // namespace

void InitRuntime(const uint8_t* vm_snapshot_data,
                 const uint8_t* vm_snapshot_instructions,
                 const uint8_t* default_isolate_snapshot_data,
                 const uint8_t* default_isolate_snapshot_instructions) {
  TRACE_EVENT0("flutter", "InitRuntime");

  FXL_CHECK(!g_platform_impl);
  g_platform_impl = new PlatformImpl();
  InitEngine(g_platform_impl);
  InitDartVM(vm_snapshot_data, vm_snapshot_instructions,
             default_isolate_snapshot_data,
             default_isolate_snapshot_instructions);
}

}  // namespace blink

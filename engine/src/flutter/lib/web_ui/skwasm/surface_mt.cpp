// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "surface.h"

#include "skwasm_support.h"
#include <emscripten/wasm_worker.h>

using namespace Skwasm;

Surface::Surface() {
  assert(emscripten_is_main_browser_thread());

  _thread = emscripten_malloc_wasm_worker(1024);
  skwasm_initThread(_thread, this);

  // Listen to messages from the worker
  skwasm_connectThread(_thread);
}

SKWASM_EXPORT bool skwasm_isMultiThreaded() {
  return true;
}

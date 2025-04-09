// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/metal/allocator_mtl.h"
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/pass_bindings_cache_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/capabilities.h"

#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.h>
#include <memory>
#include <thread>

#include "gtest/gtest.h"

namespace impeller {
namespace testing {

using PassBindingsCacheMTLUnitTests = PlaygroundTest;
INSTANTIATE_METAL_PLAYGROUND_SUITE(PassBindingsCacheMTLUnitTests);

TEST_P(PassBindingsCacheMTLUnitTests, CanCreatePassBindingsCache) {
  id<MTLDevice> device = ::MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> command_queue = device.newCommandQueue;
  id<MTLCommandBuffer> command_buffer = [command_queue commandBuffer];
  MTLRenderPassDescriptor* render_pass_descriptor =
      [MTLRenderPassDescriptor renderPassDescriptor];
  id<MTLRenderCommandEncoder> encoder = [command_buffer
      renderCommandEncoderWithDescriptor:render_pass_descriptor];

  PassBindingsCacheMTL pass_bindings_cache;
  pass_bindings_cache.SetEncoder(encoder);
  pass_bindings_cache.SetStencilRef(1);

  [encoder endEncoding];
}

}  // namespace testing
}  // namespace impeller

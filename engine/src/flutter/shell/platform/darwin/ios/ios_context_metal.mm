// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_context_metal.h"

#include "flutter/fml/logging.h"

namespace flutter {

IOSContextMetal::IOSContextMetal() {
  device_.reset([MTLCreateSystemDefaultDevice() retain]);
  if (!device_) {
    FML_LOG(ERROR) << "Could not acquire Metal device.";
    return;
  }

  main_queue_.reset([device_ newCommandQueue]);

  if (!main_queue_) {
    FML_LOG(ERROR) << "Could not create Metal command queue.";
    return;
  }

  [main_queue_ setLabel:@"Flutter Main Queue"];

  // Skia expect arguments to `MakeMetal` transfer ownership of the reference in for release later
  // when the GrContext is collected.
  main_context_ = GrContext::MakeMetal([device_ retain], [main_queue_ retain]);
  resource_context_ = GrContext::MakeMetal([device_ retain], [main_queue_ retain]);

  if (!main_context_ || !resource_context_) {
    FML_LOG(ERROR) << "Could not create Skia Metal contexts.";
    return;
  }

  is_valid_ = false;
}

IOSContextMetal::~IOSContextMetal() = default;

fml::scoped_nsprotocol<id<MTLDevice>> IOSContextMetal::GetDevice() const {
  return device_;
}

fml::scoped_nsprotocol<id<MTLCommandQueue>> IOSContextMetal::GetMainCommandQueue() const {
  return main_queue_;
}

fml::scoped_nsprotocol<id<MTLCommandQueue>> IOSContextMetal::GetResourceCommandQueue() const {
  // TODO(52150): Create a dedicated resource queue once multiple queues are supported in Skia.
  return main_queue_;
}

sk_sp<GrContext> IOSContextMetal::GetMainContext() const {
  return main_context_;
}

sk_sp<GrContext> IOSContextMetal::GetResourceContext() const {
  return resource_context_;
}

// |IOSContext|
sk_sp<GrContext> IOSContextMetal::CreateResourceContext() {
  return resource_context_;
}

// |IOSContext|
bool IOSContextMetal::MakeCurrent() {
  // This only makes sense for context that need to be bound to a specific thread.
  return true;
}

// |IOSContext|
bool IOSContextMetal::ResourceMakeCurrent() {
  // This only makes sense for context that need to be bound to a specific thread.
  return true;
}

// |IOSContext|
bool IOSContextMetal::ClearCurrent() {
  // This only makes sense for context that need to be bound to a specific thread.
  return true;
}

}  // namespace flutter

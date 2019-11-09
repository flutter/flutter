// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios_gl_context_switch_manager.h"

namespace flutter {

IOSGLContextSwitchManager::IOSGLContextSwitchManager() {
  resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3]);
  stored_ = fml::scoped_nsobject<NSMutableArray>([[NSMutableArray new] retain]);
  resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3]);
  if (resource_context_ != nullptr) {
    context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3
                                         sharegroup:resource_context_.get().sharegroup]);
  } else {
    resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]);
    context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                         sharegroup:resource_context_.get().sharegroup]);
  }
};

IOSGLContextSwitchManager::~IOSGLContextSwitchManager() = default;

std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
IOSGLContextSwitchManager::MakeCurrent() {
  return std::make_unique<IOSGLContextSwitchManager::IOSGLContextSwitch>(*this, context_);
}

std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
IOSGLContextSwitchManager::ResourceMakeCurrent() {
  return std::make_unique<IOSGLContextSwitchManager::IOSGLContextSwitch>(*this, resource_context_);
}

fml::scoped_nsobject<EAGLContext> IOSGLContextSwitchManager::GetContext() {
  return context_;
}

bool IOSGLContextSwitchManager::PushContext(fml::scoped_nsobject<EAGLContext> context) {
  EAGLContext* current = [EAGLContext currentContext];
  if (current == nil) {
    [stored_.get() addObject:[NSNull null]];
  } else {
    [stored_.get() addObject:current];
  }
  bool result = [EAGLContext setCurrentContext:context.get()];
  return result;
}

void IOSGLContextSwitchManager::PopContext() {
  EAGLContext* last = [stored_.get() lastObject];
  [stored_.get() removeLastObject];
  if ([last isEqual:[NSNull null]]) {
    [EAGLContext setCurrentContext:nil];
    return;
  }
  [EAGLContext setCurrentContext:last];
}

IOSGLContextSwitchManager::IOSGLContextSwitch::IOSGLContextSwitch(
    IOSGLContextSwitchManager& manager,
    fml::scoped_nsobject<EAGLContext> context)
    : manager_(manager) {
  bool result = manager_.PushContext(context);
  has_pushed_context_ = true;
  switch_result_ = result;
}

IOSGLContextSwitchManager::IOSGLContextSwitch::~IOSGLContextSwitch() {
  if (!has_pushed_context_) {
    return;
  }
  manager_.PopContext();
}

bool IOSGLContextSwitchManager::IOSGLContextSwitch::GetSwitchResult() {
  return switch_result_;
}
}

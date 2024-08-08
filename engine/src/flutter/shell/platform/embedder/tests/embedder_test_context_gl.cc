// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_context_gl.h"

#include <utility>

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/paths.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor_gl.h"
#include "flutter/testing/testing.h"
#include "tests/embedder_test.h"
#include "third_party/dart/runtime/bin/elf_loader.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

EmbedderTestContextGL::EmbedderTestContextGL(std::string assets_path)
    : EmbedderTestContext(std::move(assets_path)) {
  egl_context_ = std::make_shared<TestEGLContext>();
}

EmbedderTestContextGL::~EmbedderTestContextGL() {
  SetGLGetFBOCallback(nullptr);
}

void EmbedderTestContextGL::SetupSurface(SkISize surface_size) {
  FML_CHECK(!gl_surface_);
  gl_surface_ = std::make_unique<TestGLSurface>(egl_context_, surface_size);
}

bool EmbedderTestContextGL::GLMakeCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->MakeCurrent();
}

bool EmbedderTestContextGL::GLClearCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->ClearCurrent();
}

bool EmbedderTestContextGL::GLPresent(FlutterPresentInfo present_info) {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  gl_surface_present_count_++;

  GLPresentCallback callback;
  {
    std::scoped_lock lock(gl_callback_mutex_);
    callback = gl_present_callback_;
  }

  if (callback) {
    callback(present_info);
  }

  FireRootSurfacePresentCallbackIfPresent(
      [&]() { return gl_surface_->GetRasterSurfaceSnapshot(); });

  return gl_surface_->Present();
}

void EmbedderTestContextGL::SetGLGetFBOCallback(GLGetFBOCallback callback) {
  std::scoped_lock lock(gl_callback_mutex_);
  gl_get_fbo_callback_ = std::move(callback);
}

void EmbedderTestContextGL::SetGLPopulateExistingDamageCallback(
    GLPopulateExistingDamageCallback callback) {
  std::scoped_lock lock(gl_callback_mutex_);
  gl_populate_existing_damage_callback_ = std::move(callback);
}

void EmbedderTestContextGL::SetGLPresentCallback(GLPresentCallback callback) {
  std::scoped_lock lock(gl_callback_mutex_);
  gl_present_callback_ = std::move(callback);
}

uint32_t EmbedderTestContextGL::GLGetFramebuffer(FlutterFrameInfo frame_info) {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";

  GLGetFBOCallback callback;
  {
    std::scoped_lock lock(gl_callback_mutex_);
    callback = gl_get_fbo_callback_;
  }

  if (callback) {
    callback(frame_info);
  }

  const auto size = frame_info.size;
  return gl_surface_->GetFramebuffer(size.width, size.height);
}

void EmbedderTestContextGL::GLPopulateExistingDamage(
    const intptr_t id,
    FlutterDamage* existing_damage) {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";

  GLPopulateExistingDamageCallback callback;
  {
    std::scoped_lock lock(gl_callback_mutex_);
    callback = gl_populate_existing_damage_callback_;
  }

  if (callback) {
    callback(id, existing_damage);
  }
}

bool EmbedderTestContextGL::GLMakeResourceCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->MakeResourceCurrent();
}

void* EmbedderTestContextGL::GLGetProcAddress(const char* name) {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->GetProcAddress(name);
}

size_t EmbedderTestContextGL::GetSurfacePresentCount() const {
  return gl_surface_present_count_;
}

EmbedderTestContextType EmbedderTestContextGL::GetContextType() const {
  return EmbedderTestContextType::kOpenGLContext;
}

uint32_t EmbedderTestContextGL::GetWindowFBOId() const {
  FML_CHECK(gl_surface_);
  return gl_surface_->GetWindowFBOId();
}

void EmbedderTestContextGL::SetupCompositor() {
  FML_CHECK(!compositor_) << "Already set up a compositor in this context.";
  FML_CHECK(gl_surface_)
      << "Set up the GL surface before setting up a compositor.";
  compositor_ = std::make_unique<EmbedderTestCompositorGL>(
      gl_surface_->GetSurfaceSize(), gl_surface_->GetGrContext());
  GLClearCurrent();
}

}  // namespace testing
}  // namespace flutter

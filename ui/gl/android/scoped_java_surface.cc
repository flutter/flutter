// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/android/scoped_java_surface.h"

#include "base/logging.h"
#include "jni/Surface_jni.h"
#include "ui/gl/android/surface_texture.h"

namespace {

bool g_jni_initialized = false;

void RegisterNativesIfNeeded(JNIEnv* env) {
  if (!g_jni_initialized) {
    JNI_Surface::RegisterNativesImpl(env);
    g_jni_initialized = true;
  }
}

}  // anonymous namespace

namespace gfx {

ScopedJavaSurface::ScopedJavaSurface() {
}

ScopedJavaSurface::ScopedJavaSurface(
    const base::android::JavaRef<jobject>& surface)
    : auto_release_(true),
      is_protected_(false) {
  JNIEnv* env = base::android::AttachCurrentThread();
  RegisterNativesIfNeeded(env);
  DCHECK(env->IsInstanceOf(surface.obj(), Surface_clazz(env)));
  j_surface_.Reset(surface);
}

ScopedJavaSurface::ScopedJavaSurface(
    const SurfaceTexture* surface_texture)
    : auto_release_(true),
      is_protected_(false) {
  JNIEnv* env = base::android::AttachCurrentThread();
  RegisterNativesIfNeeded(env);
  ScopedJavaLocalRef<jobject> tmp(JNI_Surface::Java_Surface_Constructor(
      env, surface_texture->j_surface_texture().obj()));
  DCHECK(!tmp.is_null());
  j_surface_.Reset(tmp);
}

ScopedJavaSurface::ScopedJavaSurface(RValue rvalue) {
  MoveFrom(*rvalue.object);
}

ScopedJavaSurface& ScopedJavaSurface::operator=(RValue rhs) {
  MoveFrom(*rhs.object);
  return *this;
}

ScopedJavaSurface::~ScopedJavaSurface() {
  if (auto_release_ && !j_surface_.is_null()) {
    JNIEnv* env = base::android::AttachCurrentThread();
    JNI_Surface::Java_Surface_release(env, j_surface_.obj());
  }
}

void ScopedJavaSurface::MoveFrom(ScopedJavaSurface& other) {
  JNIEnv* env = base::android::AttachCurrentThread();
  j_surface_.Reset(env, other.j_surface_.Release());
  auto_release_ = other.auto_release_;
  is_protected_ = other.is_protected_;
}

bool ScopedJavaSurface::IsEmpty() const {
  return j_surface_.is_null();
}

// static
ScopedJavaSurface ScopedJavaSurface::AcquireExternalSurface(jobject surface) {
  JNIEnv* env = base::android::AttachCurrentThread();
  ScopedJavaLocalRef<jobject> surface_ref;
  surface_ref.Reset(env, surface);
  gfx::ScopedJavaSurface scoped_surface(surface_ref);
  scoped_surface.auto_release_ = false;
  scoped_surface.is_protected_ = true;
  return scoped_surface;
}

}  // namespace gfx

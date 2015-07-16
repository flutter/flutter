// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_osmesa_api_implementation.h"

namespace gfx {

RealOSMESAApi* g_real_osmesa;

void InitializeStaticGLBindingsOSMESA() {
  g_driver_osmesa.InitializeStaticBindings();
  if (!g_real_osmesa) {
    g_real_osmesa = new RealOSMESAApi();
  }
  g_real_osmesa->Initialize(&g_driver_osmesa);
  g_current_osmesa_context = g_real_osmesa;
}

void InitializeDebugGLBindingsOSMESA() {
  g_driver_osmesa.InitializeDebugBindings();
}

void ClearGLBindingsOSMESA() {
  if (g_real_osmesa) {
    delete g_real_osmesa;
    g_real_osmesa = NULL;
  }
  g_current_osmesa_context = NULL;
  g_driver_osmesa.ClearBindings();
}

OSMESAApi::OSMESAApi() {
}

OSMESAApi::~OSMESAApi() {
}

OSMESAApiBase::OSMESAApiBase()
    : driver_(NULL) {
}

OSMESAApiBase::~OSMESAApiBase() {
}

void OSMESAApiBase::InitializeBase(DriverOSMESA* driver) {
  driver_ = driver;
}

RealOSMESAApi::RealOSMESAApi() {
}

RealOSMESAApi::~RealOSMESAApi() {
}

void RealOSMESAApi::Initialize(DriverOSMESA* driver) {
  InitializeBase(driver);
}

TraceOSMESAApi::~TraceOSMESAApi() {
}

}  // namespace gfx



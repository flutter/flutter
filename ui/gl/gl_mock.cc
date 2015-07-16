// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_mock.h"

namespace gfx {

MockGLInterface::MockGLInterface() {
}

MockGLInterface::~MockGLInterface() {
}

MockGLInterface* MockGLInterface::interface_;

void MockGLInterface::SetGLInterface(MockGLInterface* gl_interface) {
  interface_ = gl_interface;
}

}  // namespace gfx

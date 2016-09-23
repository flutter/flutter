// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "glfw_service_provider.h"

namespace shell {

GLFWServiceProvider::GLFWServiceProvider(
    mojo::InterfaceRequest<mojo::ServiceProvider> request)
    : binding_(this, request.Pass()) {}

GLFWServiceProvider::~GLFWServiceProvider() {}

void GLFWServiceProvider::ConnectToService(
    const mojo::String& service_name,
    mojo::ScopedMessagePipeHandle client_handle) {}

}  // namespace shell

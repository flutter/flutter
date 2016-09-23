// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_GLFW_SERVICE_PROVIDER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_GLFW_SERVICE_PROVIDER_H_

#include "lib/ftl/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"

namespace shell {

class GLFWServiceProvider : public mojo::ServiceProvider {
 public:
  GLFWServiceProvider(mojo::InterfaceRequest<mojo::ServiceProvider> request);

  ~GLFWServiceProvider() override;

  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override;

 private:
  mojo::StrongBinding<mojo::ServiceProvider> binding_;

  FTL_DISALLOW_COPY_AND_ASSIGN(GLFWServiceProvider);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_GLFW_SERVICE_PROVIDER_H_

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_GLFW_WINDOW_IMPL_H_
#define SKY_SHELL_PLATFORM_GLFW_WINDOW_IMPL_H_

#include <memory>
#include <string>

#include "mojo/common/binding_set.h"
#include "flutter/services/engine/sky_engine.mojom.h"
#include "flutter/services/raw_keyboard/raw_keyboard.mojom.h"
#include "flutter/sky/shell/platform_view.h"
#include "flutter/sky/shell/shell_view.h"

namespace sky {
namespace shell {

class WindowImpl : public mojo::ServiceProvider,
                   public raw_keyboard::RawKeyboardService {
 public:
  explicit WindowImpl(GLFWwindow* window);
  ~WindowImpl() override;

  void RunFromBundle(const std::string& script_uri,
                     const std::string& bundle_path);

  void RunFromFile(const std::string& file);

  void UpdateViewportMetrics(int width, int height);
  void DispatchMouseButtonEvent(int button, int action, int mods);
  void DispatchMouseMoveEvent(double x, double y);
  void DispatchKeyEvent(sky::InputEventPtr event);

  // mojo::ServiceProvider
  void ConnectToService(const mojo::String& service_name,
      mojo::ScopedMessagePipeHandle client_handle) override;

  // raw_keyboard::RawKeyboardService
  void AddListener(
      mojo::InterfaceHandle<raw_keyboard::RawKeyboardListener> listener)
      override;

 private:
  GLFWwindow* window_;
  std::unique_ptr<ShellView> shell_view_;
  sky::SkyEnginePtr engine_;
  int buttons_;

  mojo::Binding<mojo::ServiceProvider> view_services_binding_;
  mojo::BindingSet<raw_keyboard::RawKeyboardService> raw_keyboard_bindings_;
  std::vector<raw_keyboard::RawKeyboardListenerPtr> raw_keyboard_listeners_;

  FTL_DISALLOW_COPY_AND_ASSIGN(WindowImpl);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_GLFW_WINDOW_IMPL_H_

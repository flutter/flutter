// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/platform_view_glfw.h"

#include "flutter/common/threads.h"
#include "flutter/shell/platform/linux/glfw_service_provider.h"

#include <GLFW/glfw3.h>

namespace shell {

inline PlatformViewGLFW* ToPlatformView(GLFWwindow* window) {
  return static_cast<PlatformViewGLFW*>(glfwGetWindowUserPointer(window));
}

PlatformViewGLFW::PlatformViewGLFW()
    : valid_(false), glfw_window_(nullptr), buttons_(0), weak_factory_(this) {
  if (!glfwInit()) {
    return;
  }

  glfw_window_ = glfwCreateWindow(640, 480, "Flutter", NULL, NULL);
  if (glfw_window_ == nullptr) {
    return;
  }

  glfwSetWindowUserPointer(glfw_window_, this);

  glfwSetWindowSizeCallback(
      glfw_window_, [](GLFWwindow* window, int width, int height) {
        ToPlatformView(window)->OnWindowSizeChanged(width, height);
      });

  glfwSetMouseButtonCallback(
      glfw_window_, [](GLFWwindow* window, int button, int action, int mods) {
        ToPlatformView(window)->OnMouseButtonChanged(button, action, mods);
      });

  glfwSetKeyCallback(glfw_window_, [](GLFWwindow* window, int key, int scancode,
                                      int action, int mods) {
    ToPlatformView(window)->OnKeyEvent(key, scancode, action, mods);
  });

  valid_ = true;
}

PlatformViewGLFW::~PlatformViewGLFW() {
  if (glfw_window_ != nullptr) {
    glfwSetWindowUserPointer(glfw_window_, nullptr);
    glfwDestroyWindow(glfw_window_);
    glfw_window_ = nullptr;
  }

  glfwTerminate();
}

void PlatformViewGLFW::ConnectToEngineAndSetupServices() {
  ConnectToEngine(mojo::GetProxy(&engine_));

  mojo::ServiceProviderPtr platform_service_provider;
  new GLFWServiceProvider(mojo::GetProxy(&platform_service_provider));

  sky::ServicesDataPtr services = sky::ServicesData::New();
  services->incoming_services = platform_service_provider.Pass();
  engine_->SetServices(services.Pass());
}

sky::SkyEnginePtr& PlatformViewGLFW::EngineProxy() {
  return engine_;
}

bool PlatformViewGLFW::IsValid() const {
  return valid_;
}

ftl::WeakPtr<PlatformView> PlatformViewGLFW::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewGLFW::DefaultFramebuffer() const {
  // The default window bound FBO.
  return 0;
}

bool PlatformViewGLFW::ContextMakeCurrent() {
  glfwMakeContextCurrent(glfw_window_);
  return true;
}

bool PlatformViewGLFW::ResourceContextMakeCurrent() {
  // Resource loading contexts are not supported on this platform.
  return false;
}

bool PlatformViewGLFW::SwapBuffers() {
  glfwSwapBuffers(glfw_window_);
  return true;
}

void PlatformViewGLFW::RunFromSource(const std::string& main,
                                     const std::string& packages,
                                     const std::string& assets_directory) {}

void PlatformViewGLFW::OnWindowSizeChanged(int width, int height) {
  auto metrics = sky::ViewportMetrics::New();
  metrics->physical_width = width;
  metrics->physical_height = height;
  metrics->device_pixel_ratio = 1.0;
  engine_->OnViewportMetricsChanged(metrics.Pass());
}

void PlatformViewGLFW::OnMouseButtonChanged(int button, int action, int mods) {
  blink::PointerData::Change change = blink::PointerData::Change::kCancel;
  if (action == GLFW_PRESS) {
    if (!buttons_) {
      change = blink::PointerData::Change::kDown;
      glfwSetCursorPosCallback(
          glfw_window_, [](GLFWwindow* window, double x, double y) {
            ToPlatformView(window)->OnCursorPosChanged(x, y);
          });
    } else {
      change = blink::PointerData::Change::kMove;
    }
    // GLFW's button order matches what we want:
    // https://github.com/flutter/engine/blob/master/sky/specs/pointer.md
    // http://www.glfw.org/docs/3.2/group__buttons.html
    buttons_ |= 1 << button;
  } else if (action == GLFW_RELEASE) {
    buttons_ &= ~(1 << button);
    if (!buttons_) {
      change = blink::PointerData::Change::kUp;
      glfwSetCursorPosCallback(glfw_window_, nullptr);
    } else {
      change = blink::PointerData::Change::kMove;
    }
  } else {
    DLOG(INFO) << "Unknown mouse action: " << action;
    return;
  }

  double x = 0.0;
  double y = 0.0;
  glfwGetCursorPos(glfw_window_, &x, &y);

  base::TimeDelta time_stamp = base::TimeTicks::Now() - base::TimeTicks();

  blink::PointerData pointer_data;
  pointer_data.Clear();
  pointer_data.time_stamp = time_stamp.InMicroseconds();
  pointer_data.change = change;
  pointer_data.kind = blink::PointerData::DeviceKind::kMouse;
  pointer_data.physical_x = x;
  pointer_data.physical_y = y;
  pointer_data.buttons = buttons_;
  pointer_data.pressure = 1.0;
  pointer_data.pressure_max = 1.0;

  blink::Threads::UI()->PostTask(
      [ engine = engine().GetWeakPtr(), pointer_data ] {
        if (engine.get()) {
          blink::PointerDataPacket packet(1);
          packet.SetPointerData(0, pointer_data);
          engine->DispatchPointerDataPacket(packet);
        }
      });
}

void PlatformViewGLFW::OnCursorPosChanged(double x, double y) {
  base::TimeDelta time_stamp = base::TimeTicks::Now() - base::TimeTicks();

  blink::PointerData pointer_data;
  pointer_data.Clear();
  pointer_data.time_stamp = time_stamp.InMicroseconds();
  pointer_data.change = blink::PointerData::Change::kMove;
  pointer_data.kind = blink::PointerData::DeviceKind::kMouse;
  pointer_data.physical_x = x;
  pointer_data.physical_y = y;
  pointer_data.buttons = buttons_;
  pointer_data.pressure = 1.0;
  pointer_data.pressure_max = 1.0;

  blink::Threads::UI()->PostTask(
      [ engine = engine().GetWeakPtr(), pointer_data ] {
        if (engine.get()) {
          blink::PointerDataPacket packet(1);
          packet.SetPointerData(0, pointer_data);
          engine->DispatchPointerDataPacket(packet);
        }
      });
}

void PlatformViewGLFW::OnKeyEvent(int key, int scancode, int action, int mods) {
}

}  // namespace shell

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/glfw/window_impl.h"

#include <GLFW/glfw3.h>

#include "sky/shell/platform/glfw/platform_view_glfw.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {
namespace {

WindowImpl* ToImpl(GLFWwindow* window) {
  return static_cast<WindowImpl*>(glfwGetWindowUserPointer(window));
}

void OnWindowSizeChanged(GLFWwindow* window, int width, int height) {
  ToImpl(window)->UpdateViewportMetrics(width, height);
}

void OnMouseButtonChanged(GLFWwindow* window, int button, int action, int mods) {
  ToImpl(window)->DispatchMouseButtonEvent(button, action, mods);
}

void OnCursorPosChanged(GLFWwindow* window, double x, double y) {
  ToImpl(window)->DispatchMouseMoveEvent(x, y);
}

void OnKeyEvent(GLFWwindow* window, int key, int scancode, int action,
                int mods) {
  sky::InputEventPtr result = sky::InputEvent::New();
  result->time_stamp = base::TimeTicks::Now().ToInternalValue();
  switch (action) {
    case GLFW_PRESS:
    case GLFW_REPEAT:
      result->type = sky::EventType::KEY_PRESSED;
      break;
    case GLFW_RELEASE:
      result->type = sky::EventType::KEY_RELEASED;
      break;
    default:
      LOG(WARNING) << "Unknown key action: " << action;
      return;
  }
  result->key_data = sky::KeyData::New();
  result->key_data->key_code = key;
  result->key_data->scan_code = scancode;

  if (mods & GLFW_MOD_SHIFT)
    result->key_data->meta_state |= 0x00000001;
  if (mods & GLFW_MOD_CONTROL)
    result->key_data->meta_state |= 0x00001000;
  if (mods & GLFW_MOD_ALT)
    result->key_data->meta_state |= 0x00000002;

  ToImpl(window)->DispatchKeyEvent(result.Pass());
}

}  // namespace

WindowImpl::WindowImpl(GLFWwindow* window)
    : window_(window),
      shell_view_(new ShellView(Shell::Shared())),
      buttons_(0),
      view_services_binding_(this) {
  glfwSetWindowUserPointer(window_, this);
  auto platform_view =
      static_cast<sky::shell::PlatformViewGLFW*>(shell_view_->view());
  platform_view->SurfaceCreated(window);
  platform_view->ConnectToEngine(mojo::GetProxy(&engine_));

  int width = 0;
  int height = 0;
  glfwGetWindowSize(window_, &width, &height);
  UpdateViewportMetrics(width, height);

  glfwSetWindowSizeCallback(window_, OnWindowSizeChanged);
  glfwSetMouseButtonCallback(window_, OnMouseButtonChanged);
  glfwSetKeyCallback(window_, OnKeyEvent);
}

WindowImpl::~WindowImpl() {
  shell_view_.reset();
  glfwDestroyWindow(window_);
  window_ = nullptr;
}

void WindowImpl::RunFromBundle(const std::string& script_uri,
                               const std::string& bundle_path) {
  mojo::ServiceProviderPtr view_services;
  view_services_binding_.Bind(mojo::GetProxy(&view_services));

  ServicesDataPtr services = ServicesData::New();
  services->view_services = view_services.Pass();
  engine_->SetServices(services.Pass());
  engine_->RunFromBundle(script_uri, bundle_path);
}

void WindowImpl::UpdateViewportMetrics(int width, int height) {
  auto metrics = sky::ViewportMetrics::New();
  metrics->physical_width = width;
  metrics->physical_height = height;
  // TODO(abarth): There doesn't appear to be a way to get the device pixel
  // ratio from GLFW.
  metrics->device_pixel_ratio = 1.0;
  engine_->OnViewportMetricsChanged(metrics.Pass());
}

void WindowImpl::DispatchMouseButtonEvent(int button, int action, int mods) {
  pointer::PointerType type;
  if (action == GLFW_PRESS) {
    if (!buttons_) {
      type = pointer::PointerType::DOWN;
      glfwSetCursorPosCallback(window_, OnCursorPosChanged);
    } else {
      type = pointer::PointerType::MOVE;
    }
    // GLFW's button order matches what we want:
    // https://github.com/flutter/engine/blob/master/sky/specs/pointer.md
    // http://www.glfw.org/docs/3.2/group__buttons.html
    buttons_ |= 1 << button;
  } else if (action == GLFW_RELEASE) {
    buttons_ &= ~(1 << button);
    if (!buttons_) {
      type = pointer::PointerType::UP;
      glfwSetCursorPosCallback(window_, nullptr);
    } else {
      type = pointer::PointerType::MOVE;
    }
  } else {
    DLOG(INFO) << "Unknown mouse action: " << action;
    return;
  }

  double x = 0.f, y = 0.f;
  glfwGetCursorPos(window_, &x, &y);

  base::TimeDelta time_stamp = base::TimeTicks::Now() - base::TimeTicks();

  auto pointer_data = pointer::Pointer::New();
  pointer_data->time_stamp = time_stamp.InMicroseconds();
  pointer_data->type = type;
  pointer_data->kind = pointer::PointerKind::MOUSE;
  pointer_data->x = x;
  pointer_data->y = y;
  pointer_data->buttons = buttons_;
  pointer_data->pressure = 1.0;
  pointer_data->pressure_max = 1.0;

  auto pointer_packet = pointer::PointerPacket::New();
  pointer_packet->pointers.push_back(pointer_data.Pass());
  engine_->OnPointerPacket(pointer_packet.Pass());
}

void WindowImpl::DispatchMouseMoveEvent(double x, double y) {
  base::TimeDelta time_stamp = base::TimeTicks::Now() - base::TimeTicks();

  auto pointer_data = pointer::Pointer::New();
  pointer_data->time_stamp = time_stamp.InMicroseconds();
  pointer_data->type = pointer::PointerType::MOVE;
  pointer_data->kind = pointer::PointerKind::MOUSE;
  pointer_data->x = x;
  pointer_data->y = y;
  pointer_data->buttons = buttons_;
  pointer_data->pressure = 1.0;
  pointer_data->pressure_max = 1.0;

  auto pointer_packet = pointer::PointerPacket::New();
  pointer_packet->pointers.push_back(pointer_data.Pass());
  engine_->OnPointerPacket(pointer_packet.Pass());
}

void WindowImpl::DispatchKeyEvent(sky::InputEventPtr sky_event) {
  for (auto& listener : raw_keyboard_listeners_) {
    listener->OnKey(sky_event.Clone());
  }
}

void WindowImpl::ConnectToService(const mojo::String& service_name,
                                  mojo::ScopedMessagePipeHandle handle) {
  if (service_name == raw_keyboard::RawKeyboardService::Name_) {
    raw_keyboard_bindings_.AddBinding(
        this,
        mojo::MakeRequest<raw_keyboard::RawKeyboardService>(handle.Pass()));
  }
}

void WindowImpl::AddListener(
    mojo::InterfaceHandle<raw_keyboard::RawKeyboardListener> listener) {
  raw_keyboard_listeners_.push_back(
      raw_keyboard::RawKeyboardListenerPtr::Create(listener.Pass()));
}

}  // namespace shell
}  // namespace sky

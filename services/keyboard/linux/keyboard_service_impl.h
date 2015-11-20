// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_KEYBOARD_LINUX_KEYBOARD_SERVICE_IMPL_H_
#define SERVICES_KEYBOARD_LINUX_KEYBOARD_SERVICE_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/keyboard/interfaces/keyboard.mojom.h"
#include "mojo/services/native_viewport/interfaces/native_viewport.mojom.h"

namespace keyboard {

class LinuxKeyboardServiceImpl : public keyboard::KeyboardService,
                                 public mojo::NativeViewportEventDispatcher {
 public:
  LinuxKeyboardServiceImpl(
      mojo::InterfaceRequest<keyboard::KeyboardService> request,
      mojo::InterfaceRequest<NativeViewportEventDispatcher> dispatcher);
  ~LinuxKeyboardServiceImpl() override;

  // |KeyboardService| overrides:
  void Show(keyboard::KeyboardClientPtr client,
            keyboard::KeyboardType type) override;
  void ShowByRequest() override;
  void Hide() override;
  void SetText(const mojo::String& text) override;
  void SetSelection(int32_t start, int32_t end) override;

  // |NativeViewportEventDispatcher| overrides:
  void OnEvent(mojo::EventPtr event,
               const OnEventCallback& callback) override;

 private:
  mojo::Binding<mojo::NativeViewportEventDispatcher> event_dispatcher_binding_;
  mojo::StrongBinding<keyboard::KeyboardService> binding_;

  keyboard::KeyboardClientPtr client_;
  std::string text_;

  DISALLOW_COPY_AND_ASSIGN(LinuxKeyboardServiceImpl);
};

}  // namespace keyboard

#endif // defined(SERVICES_KEYBOARD_LINUX_KEYBOARD_SERVICE_IMPL_H_)

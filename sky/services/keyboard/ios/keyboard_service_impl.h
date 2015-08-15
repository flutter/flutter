// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_KEYBOARD_IOS_KEYBOARD_SERVICE_IMPL_H_
#define SKY_SERVICES_KEYBOARD_IOS_KEYBOARD_SERVICE_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/keyboard/public/interfaces/keyboard.mojom.h"

#if __OBJC__
@class KeyboardClient;
#else   // __OBJC__
class KeyboardClient;
#endif  // __OBJC__

namespace sky {
namespace services {
namespace keyboard {

class KeyboardServiceImpl : public ::keyboard::KeyboardService {
 public:
  explicit KeyboardServiceImpl(
      mojo::InterfaceRequest<::keyboard::KeyboardService> request);
  ~KeyboardServiceImpl() override;
  void Show(::keyboard::KeyboardClientPtr client,
            ::keyboard::KeyboardType type) override;
  void ShowByRequest() override;
  void Hide() override;

 private:
  mojo::StrongBinding<::keyboard::KeyboardService> binding_;
  KeyboardClient* client_;

  DISALLOW_COPY_AND_ASSIGN(KeyboardServiceImpl);
};

class KeyboardServiceFactory
    : public mojo::InterfaceFactory<::keyboard::KeyboardService> {
 public:
  void Create(
      mojo::ApplicationConnection* connection,
      mojo::InterfaceRequest<::keyboard::KeyboardService> request) override;
};

}  // namespace keyboard
}  // namespace services
}  // namespace sky

#endif /* defined(SKY_SERVICES_KEYBOARD_IOS_KEYBOARD_SERVICE_IMPL_H__) */

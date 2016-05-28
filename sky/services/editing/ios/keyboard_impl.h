// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_KEYBOARD_IOS_KEYBOARD_SERVICE_IMPL_H_
#define SKY_SERVICES_KEYBOARD_IOS_KEYBOARD_SERVICE_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/editing/editing.mojom.h"

#if __OBJC__
@class KeyboardClient;
#else   // __OBJC__
class KeyboardClient;
#endif  // __OBJC__

namespace sky {
namespace services {
namespace editing {

class KeyboardImpl : public ::editing::Keyboard {
 public:
  explicit KeyboardImpl(mojo::InterfaceRequest<::editing::Keyboard> request);
  ~KeyboardImpl() override;
  void SetClient(mojo::InterfaceHandle<::editing::KeyboardClient> client,
                 ::editing::KeyboardConfigurationPtr configuration) override;
  void SetEditingState(::editing::EditingStatePtr state) override;
  void Show() override;
  void Hide() override;

 private:
  mojo::StrongBinding<::editing::Keyboard> binding_;
  KeyboardClient* client_;

  DISALLOW_COPY_AND_ASSIGN(KeyboardImpl);
};

}  // namespace editing
}  // namespace services
}  // namespace sky

#endif /* defined(SKY_SERVICES_KEYBOARD_IOS_KEYBOARD_SERVICE_IMPL_H__) */

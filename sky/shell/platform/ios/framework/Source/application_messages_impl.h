// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_APPLICATION_MESSAGES_IMPL_H_
#define SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_APPLICATION_MESSAGES_IMPL_H_

#include <unordered_map>

#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/binding_set.h"
#include "sky/services/platform/app_messages.mojom.h"
#include "sky/shell/platform/ios/framework/Headers/FlutterAsyncMessageListener.h"
#include "sky/shell/platform/ios/framework/Headers/FlutterMessageListener.h"

namespace sky {
namespace shell {

class ApplicationMessagesImpl : public flutter::platform::ApplicationMessages {
 public:
  ApplicationMessagesImpl();
  ~ApplicationMessagesImpl() override;

  base::WeakPtr<ApplicationMessagesImpl> GetWeakPtr();
  void AddBinding(mojo::InterfaceRequest<flutter::platform::ApplicationMessages> request);

  void SetMessageListener(
      const std::string& message_name,
      NSObject<FlutterMessageListener>* listener);

  void SetAsyncMessageListener(
      const std::string& message_name,
      NSObject<FlutterAsyncMessageListener>* listener);

 private:
  void SendString(const mojo::String& message_name,
                  const mojo::String& message,
                  const SendStringCallback& callback) override;

  mojo::BindingSet<flutter::platform::ApplicationMessages> binding_;
  std::unordered_map<
      std::string, NSObject<FlutterMessageListener>*> listeners_;
  std::unordered_map<
      std::string, NSObject<FlutterAsyncMessageListener>*> async_listeners_;

  base::WeakPtrFactory<ApplicationMessagesImpl> weak_factory_;
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_

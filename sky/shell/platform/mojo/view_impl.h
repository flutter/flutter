// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MOJO_VIEW_IMPL_H_
#define SKY_SHELL_PLATFORM_MOJO_VIEW_IMPL_H_

#include <vector>

#include "base/macros.h"
#include "mojo/common/binding_set.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/application_connector.mojom.h"
#include "mojo/services/gfx/composition/interfaces/scenes.mojom.h"
#include "mojo/services/ui/input/interfaces/input_connection.mojom.h"
#include "mojo/services/ui/views/interfaces/view_manager.mojom.h"
#include "mojo/services/ui/views/interfaces/view_provider.mojom.h"
#include "mojo/services/ui/views/interfaces/views.mojom.h"
#include "sky/services/raw_keyboard/raw_keyboard.mojom.h"
#include "sky/shell/platform/mojo/platform_view_mojo.h"
#include "sky/shell/platform/mojo/pointer_converter_mojo.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {

class ViewImpl : public mojo::ui::ViewListener,
                 public mojo::ui::InputListener,
                 public mojo::ServiceProvider,
                 public raw_keyboard::RawKeyboardService {
 public:
  ViewImpl(mojo::InterfaceRequest<mojo::ui::ViewOwner> view_owner,
           ServicesDataPtr services,
           const std::string& url);
  ~ViewImpl() override;

  void Run(base::FilePath bundle_path);

 private:
  // mojo::ui::ViewListener
  void OnPropertiesChanged(uint32_t scene_version,
                           mojo::ui::ViewPropertiesPtr properties,
                           const OnPropertiesChangedCallback& callback) override;

  // mojo::ui::InputListener
  void OnEvent(mojo::EventPtr event, const OnEventCallback& callback) override;

  // mojo::ServiceProvider
  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override;

  // raw_keyboard::RawKeyboardService
  void AddListener(
      mojo::InterfaceHandle<raw_keyboard::RawKeyboardListener> listener)
      override;

  PlatformViewMojo* platform_view() {
    return static_cast<PlatformViewMojo*>(shell_view_->view());
  }

  mojo::StrongBinding<mojo::ui::ViewListener> binding_;
  std::string url_;
  mojo::ui::ViewManagerPtr view_manager_;
  mojo::ServiceProviderPtr view_service_provider_;
  mojo::ui::InputConnectionPtr input_connection_;
  mojo::Binding<mojo::ui::InputListener> listener_binding_;
  mojo::Binding<mojo::ServiceProvider> view_services_binding_;
  mojo::BindingSet<raw_keyboard::RawKeyboardService> raw_keyboard_bindings_;
  std::vector<raw_keyboard::RawKeyboardListenerPtr> raw_keyboard_listeners_;

  std::unique_ptr<ShellView> shell_view_;
  SkyEnginePtr engine_;
  ViewportMetrics viewport_metrics_;

  PointerConverterMojo pointer_converter_;

  DISALLOW_COPY_AND_ASSIGN(ViewImpl);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MOJO_VIEW_IMPL_H_

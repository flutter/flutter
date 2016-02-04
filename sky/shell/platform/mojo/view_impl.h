// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MOJO_VIEW_IMPL_H_
#define SKY_SHELL_PLATFORM_MOJO_VIEW_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/application_connector.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "mojo/services/gfx/composition/interfaces/scenes.mojom.h"
#include "mojo/services/ui/input/interfaces/input_connection.mojom.h"
#include "mojo/services/ui/views/interfaces/view_manager.mojom.h"
#include "mojo/services/ui/views/interfaces/view_provider.mojom.h"
#include "mojo/services/ui/views/interfaces/views.mojom.h"
#include "sky/shell/platform/mojo/platform_view_mojo.h"
#include "sky/shell/platform/mojo/pointer_converter_mojo.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {

class ViewImpl : public mojo::ui::View,
                 public mojo::ui::InputListener {
 public:
  ViewImpl(ServicesDataPtr services,
           const std::string& url,
           const mojo::ui::ViewProvider::CreateViewCallback& callback);
  ~ViewImpl() override;

  void Run(mojo::asset_bundle::AssetBundlePtr bundle);

 private:
  // mojo::ui::View
  void OnLayout(mojo::ui::ViewLayoutParamsPtr layout_params,
                mojo::Array<uint32_t> children_needing_layout,
                const OnLayoutCallback& callback) override;
  void OnChildUnavailable(uint32_t child_key,
                          const OnChildUnavailableCallback& callback) override;

  // mojo::ui::InputListener
  void OnEvent(mojo::EventPtr event, const OnEventCallback& callback) override;

  PlatformViewMojo* platform_view() {
    return static_cast<PlatformViewMojo*>(shell_view_->view());
  }

  mojo::StrongBinding<mojo::ui::View> binding_;
  std::string url_;
  mojo::ui::ViewManagerPtr view_manager_;
  mojo::ServiceProviderPtr view_service_provider_;
  mojo::ui::InputConnectionPtr input_connection_;
  mojo::Binding<mojo::ui::InputListener> listener_binding_;

  std::unique_ptr<ShellView> shell_view_;
  SkyEnginePtr engine_;
  ViewportMetrics viewport_metrics_;

  PointerConverterMojo pointer_converter_;

  DISALLOW_COPY_AND_ASSIGN(ViewImpl);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MOJO_VIEW_IMPL_H_

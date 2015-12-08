// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MOJO_PLATFORM_VIEW_MOJO_H_
#define SKY_SHELL_PLATFORM_MOJO_PLATFORM_VIEW_MOJO_H_

#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "mojo/services/keyboard/interfaces/keyboard.mojom.h"
#include "mojo/services/native_viewport/interfaces/native_viewport.mojom.h"
#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class PlatformViewMojo : public PlatformView,
                         public mojo::NativeViewportEventDispatcher,
                         public mojo::InterfaceFactory<::keyboard::KeyboardService> {
 public:
  explicit PlatformViewMojo(const Config& config);
  ~PlatformViewMojo() override;

  void Init(mojo::Shell* shell);

  void Run(const mojo::String& url,
           ServicesDataPtr services,
           mojo::asset_bundle::AssetBundlePtr bundle);

 private:
  void OnMetricsChanged(mojo::ViewportMetricsPtr metrics);

  // mojo::NativeViewportEventDispatcher
  void OnEvent(mojo::EventPtr event,
               const mojo::Callback<void()>& callback) override;

  pointer::PointerPtr CreateEvent(pointer::PointerType type, mojo::Event* event, mojo::PointerData* data);

  // |mojo::InterfaceFactory<mojo::asset_bundle::AssetUnpacker>| implementation:
  void Create(
      mojo::ApplicationConnection* connection,
      mojo::InterfaceRequest<::keyboard::KeyboardService>) override;

  mojo::ApplicationConnectorPtr connector_;

  mojo::NativeViewportPtr viewport_;
  mojo::Binding<NativeViewportEventDispatcher> dispatcher_binding_;

  sky::SkyEnginePtr sky_engine_;

  mojo::ServiceProviderImpl service_provider_;

  mojo::NativeViewportEventDispatcherPtr key_event_dispatcher_;

  std::map<int, std::pair<float, float>> pointer_positions_;

  DISALLOW_COPY_AND_ASSIGN(PlatformViewMojo);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MOJO_PLATFORM_VIEW_MOJO_H_

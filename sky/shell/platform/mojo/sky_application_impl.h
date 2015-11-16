// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MOJO_SKY_APPLICATION_IMPL_H_
#define SKY_SHELL_PLATFORM_MOJO_SKY_APPLICATION_IMPL_H_

#include "base/message_loop/message_loop.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/application.mojom.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "mojo/services/content_handler/interfaces/content_handler.mojom.h"
#include "sky/shell/platform/mojo/platform_view_mojo.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {

class SkyApplicationImpl : public mojo::Application {
 public:
  SkyApplicationImpl(mojo::InterfaceRequest<mojo::Application> application,
                     mojo::URLResponsePtr response);
  ~SkyApplicationImpl() override;

 private:
  // mojo::Application
  void Initialize(mojo::ShellPtr shell,
                  mojo::Array<mojo::String> args,
                  const mojo::String& url) override;
  void AcceptConnection(const mojo::String& requestor_url,
                        mojo::InterfaceRequest<mojo::ServiceProvider> services,
                        mojo::ServiceProviderPtr exposed_services,
                        const mojo::String& resolved_url) override;
  void RequestQuit() override;

  PlatformViewMojo* platform_view() {
    return static_cast<PlatformViewMojo*>(shell_view_->view());
  }

  void UnpackInitialResponse(mojo::Shell* shell);

  mojo::StrongBinding<mojo::Application> binding_;
  mojo::URLResponsePtr initial_response_;
  mojo::asset_bundle::AssetBundlePtr bundle_;
  scoped_ptr<ShellView> shell_view_;
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MOJO_SKY_APPLICATION_IMPL_H_

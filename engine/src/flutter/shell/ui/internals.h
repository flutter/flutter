// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_INTERNALS_H_
#define SKY_SHELL_UI_INTERNALS_H_

#include "base/supports_user_data.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/asset_bundle/public/interfaces/asset_bundle.mojom.h"

namespace mojo {
class ApplicationConnection;
}

namespace sky {
namespace shell {

class Internals
  : public base::SupportsUserData::Data,
    public mojo::InterfaceFactory<mojo::asset_bundle::AssetUnpacker> {
 public:
  virtual ~Internals();

  static void Create(Dart_Isolate isolate,
                     mojo::ServiceProviderPtr platform_service_provider);

  mojo::Handle TakeServicesProvidedByEmbedder();

 private:
  explicit Internals(mojo::ServiceProviderPtr platform_service_provider);

  // |mojo::InterfaceFactory<mojo::asset_bundle::AssetUnpacker>| implementation:
  void Create(
      mojo::ApplicationConnection* connection,
      mojo::InterfaceRequest<mojo::asset_bundle::AssetUnpacker>) override;

  mojo::ServiceProviderPtr service_provider_;
  mojo::ServiceProviderImpl service_provider_impl_;
  mojo::ServiceProviderPtr platform_service_provider_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Internals);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_INTERNALS_H_

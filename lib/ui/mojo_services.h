// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_MOJO_SERVICES_H_
#define SKY_ENGINE_BINDINGS_MOJO_SERVICES_H_

#include "dart/runtime/include/dart_api.h"
#include "lib/ftl/macros.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "flutter/services/engine/sky_engine.mojom.h"

namespace mojo {
class ApplicationConnection;
}

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class MojoServices {
 public:
  ~MojoServices();

  static void Create(Dart_Isolate isolate,
                     sky::ServicesDataPtr services,
                     mojo::ServiceProviderPtr incoming_services,
                     mojo::asset_bundle::AssetBundlePtr root_bundle);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

  int TakeRootBundle();
  int TakeIncomingServices();
  int TakeOutgoingServices();
  int TakeShell();
  int TakeView();
  int TakeViewServices();

 private:
  explicit MojoServices(sky::ServicesDataPtr services,
                        mojo::ServiceProviderPtr incoming_services,
                        mojo::asset_bundle::AssetBundlePtr root_bundle);

  sky::ServicesDataPtr services_;

  mojo::asset_bundle::AssetBundlePtr root_bundle_;
  mojo::ServiceProviderPtr incoming_services_;
  mojo::InterfaceRequest<mojo::ServiceProvider> outgoing_services_;

  // We need to hold this object to work around
  // https://github.com/domokit/mojo/issues/536
  mojo::ServiceProviderPtr services_from_dart_;

  FTL_DISALLOW_COPY_AND_ASSIGN(MojoServices);
};

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_MOJO_SERVICES_H_

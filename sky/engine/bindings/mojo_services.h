// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_MOJO_SERVICES_H_
#define SKY_ENGINE_BINDINGS_MOJO_SERVICES_H_

#include "dart/runtime/include/dart_api.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "sky/services/engine/sky_engine.mojom.h"

namespace mojo {
class ApplicationConnection;
}

namespace blink {
class DartLibraryNatives;

class MojoServices {
 public:
  ~MojoServices();

  static void Create(Dart_Isolate isolate,
                     sky::ServicesDataPtr services,
                     mojo::ServiceProviderPtr services_from_embedder,
                     mojo::asset_bundle::AssetBundlePtr root_bundle);

  static void RegisterNatives(DartLibraryNatives* natives);

  mojo::Handle TakeShellProxy();
  mojo::Handle TakeServicesProvidedByEmbedder();
  mojo::Handle TakeServicesProvidedToEmbedder();
  mojo::Handle TakeRootBundleHandle();
  mojo::Handle TakeViewHostHandle();

 private:
  explicit MojoServices(sky::ServicesDataPtr services,
                        mojo::ServiceProviderPtr services_from_embedder,
                        mojo::asset_bundle::AssetBundlePtr root_bundle);

  sky::ServicesDataPtr services_;
  mojo::ServiceProviderPtr services_from_embedder_;
  mojo::asset_bundle::AssetBundlePtr root_bundle_;

  // We need to hold this object to work around
  // https://github.com/domokit/mojo/issues/536
  mojo::ServiceProviderPtr services_from_dart_;

  // A ServiceProvider supplied by the application that exposes services to
  // the embedder.
  mojo::InterfaceRequest<mojo::ServiceProvider>
      services_provided_to_embedder_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MojoServices);
};

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_MOJO_SERVICES_H_

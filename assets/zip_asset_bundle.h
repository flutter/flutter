// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_ZIP_ASSET_BUNDLE_H_
#define FLUTTER_ASSETS_ZIP_ASSET_BUNDLE_H_

#include "flutter/assets/zip_asset_store.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"

namespace blink {

class ZipAssetBundle : public mojo::asset_bundle::AssetBundle {
 public:
  ZipAssetBundle(
      mojo::InterfaceRequest<mojo::asset_bundle::AssetBundle> request,
      ftl::RefPtr<ZipAssetStore> store);
  ~ZipAssetBundle() override;

  // mojo::assert_bundle::AssetBundle implementation:
  void GetAsStream(
      const mojo::String& asset_name,
      const mojo::Callback<void(mojo::ScopedDataPipeConsumerHandle)>& callback)
      override;

 private:
  mojo::Binding<mojo::asset_bundle::AssetBundle> binding_;
  ftl::RefPtr<ZipAssetStore> store_;
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_ZIP_ASSET_BUNDLE_H_

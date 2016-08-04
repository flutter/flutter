// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path.h"
#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/environment/async_waiter.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"

namespace blink {

// A mojo service that serves assets out of a directory.
class DirectoryAssetBundleService : public mojo::asset_bundle::AssetBundle {
 public:
  static void Create(
      mojo::InterfaceRequest<mojo::asset_bundle::AssetBundle> request,
      const base::FilePath& directory);

 public:
  void GetAsStream(
      const mojo::String& asset_name,
      const mojo::Callback<
          void(mojo::ScopedDataPipeConsumerHandle)>& callback) override;

  ~DirectoryAssetBundleService() override;

 private:
  DirectoryAssetBundleService(mojo::InterfaceRequest<AssetBundle> request,
                              const base::FilePath& directory);

  mojo::StrongBinding<AssetBundle> binding_;
  const base::FilePath directory_;
};

}  // namespace blink

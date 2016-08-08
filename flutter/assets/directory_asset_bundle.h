// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_
#define FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_

#include "lib/ftl/macros.h"
#include "lib/ftl/tasks/task_runner.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/environment/async_waiter.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"

namespace blink {

// A mojo service that serves assets out of a directory.
class DirectoryAssetBundle : public mojo::asset_bundle::AssetBundle {
 public:
  DirectoryAssetBundle(mojo::InterfaceRequest<AssetBundle> request,
                       std::string directory,
                       ftl::RefPtr<ftl::TaskRunner> task_runner);

  // mojo::assert_bundle::AssetBundle implementation:
  void GetAsStream(
      const mojo::String& asset_name,
      const mojo::Callback<void(mojo::ScopedDataPipeConsumerHandle)>& callback)
      override;

 private:
  ~DirectoryAssetBundle() override;

  mojo::StrongBinding<mojo::asset_bundle::AssetBundle> binding_;
  const std::string directory_;
  ftl::RefPtr<ftl::TaskRunner> task_runner_;

  FTL_DISALLOW_COPY_AND_ASSIGN(DirectoryAssetBundle);
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_

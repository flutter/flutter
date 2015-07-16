// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_ASSET_BUNDLE_ASSET_BUNDLE_IMPL_H_
#define SERVICES_ASSET_BUNDLE_ASSET_BUNDLE_IMPL_H_

#include "base/files/scoped_temp_dir.h"
#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/task_runner.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/services/asset_bundle/public/interfaces/asset_bundle.mojom.h"

namespace mojo {
namespace asset_bundle {

class AssetBundleImpl : public AssetBundle {
 public:
  AssetBundleImpl(InterfaceRequest<AssetBundle> request,
                  scoped_ptr<base::ScopedTempDir> asset_dir,
                  scoped_refptr<base::TaskRunner> worker_runner);
  ~AssetBundleImpl() override;

  // AssetBundle implementation
  void GetAsStream(
      const String& asset_name,
      const Callback<void(ScopedDataPipeConsumerHandle)>& callback) override;

 private:
  StrongBinding<AssetBundle> binding_;
  scoped_ptr<base::ScopedTempDir> asset_dir_;
  scoped_refptr<base::TaskRunner> worker_runner_;

  DISALLOW_COPY_AND_ASSIGN(AssetBundleImpl);
};

}  // namespace asset_bundle
}  // namespace mojo

#endif  // SERVICES_ASSET_BUNDLE_ASSET_BUNDLE_IMPL_H_

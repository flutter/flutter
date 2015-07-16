// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_ASSET_BUNDLE_ASSET_UNPACKER_IMPL_H_
#define SERVICES_ASSET_BUNDLE_ASSET_UNPACKER_IMPL_H_

#include "base/macros.h"
#include "base/task_runner.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/services/asset_bundle/public/interfaces/asset_bundle.mojom.h"

namespace mojo {
namespace asset_bundle {

class AssetUnpackerImpl : public AssetUnpacker {
 public:
  AssetUnpackerImpl(InterfaceRequest<AssetUnpacker> request,
                    scoped_refptr<base::TaskRunner> worker_runner);
  ~AssetUnpackerImpl() override;

  // AssetUnpacker implementation
  void UnpackZipStream(ScopedDataPipeConsumerHandle zipped_assets,
                       InterfaceRequest<AssetBundle> asset_bundle) override;

 private:
  StrongBinding<AssetUnpacker> binding_;

  scoped_refptr<base::TaskRunner> worker_runner_;

  DISALLOW_COPY_AND_ASSIGN(AssetUnpackerImpl);
};

}  // namespace asset_bundle
}  // namespace mojo

#endif  // SERVICES_ASSET_BUNDLE_ASSET_UNPACKER_IMPL_H_

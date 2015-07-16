// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_ASSET_BUNDLE_ASSET_UNPACKER_JOB_H_
#define SERVICES_ASSET_BUNDLE_ASSET_UNPACKER_JOB_H_

#include "base/files/scoped_temp_dir.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "base/task_runner.h"
#include "mojo/common/data_pipe_utils.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/services/asset_bundle/public/interfaces/asset_bundle.mojom.h"

namespace mojo {
namespace asset_bundle {

class AssetUnpackerJob {
 public:
  AssetUnpackerJob(InterfaceRequest<AssetBundle> asset_bundle,
                   scoped_refptr<base::TaskRunner> worker_runner);
  ~AssetUnpackerJob();

  void Unpack(ScopedDataPipeConsumerHandle zipped_assets);

 private:
  void OnZippedAssetsAvailable(const base::FilePath& zip_path, bool success);
  void OnUnzippedAssetsAvailable(scoped_ptr<base::ScopedTempDir> temp_dir);

  InterfaceRequest<AssetBundle> asset_bundle_;
  scoped_refptr<base::TaskRunner> worker_runner_;
  base::WeakPtrFactory<AssetUnpackerJob> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(AssetUnpackerJob);
};

}  // namespace asset_bundle
}  // namespace mojo

#endif  // SERVICES_ASSET_BUNDLE_ASSET_UNPACKER_JOB_H_

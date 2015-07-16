// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/asset_bundle/asset_unpacker_job.h"

#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "services/asset_bundle/asset_bundle_impl.h"
#include "third_party/zlib/google/zip.h"

namespace mojo {
namespace asset_bundle {
namespace {

void UnzipAssets(
    const base::FilePath& zip_path,
    scoped_ptr<base::ScopedTempDir> asset_dir,
    scoped_refptr<base::TaskRunner> task_runner,
    base::Callback<void(scoped_ptr<base::ScopedTempDir>)> callback) {
  if (!zip::Unzip(zip_path, asset_dir->path())) {
    task_runner->PostTask(FROM_HERE, base::Bind(callback, nullptr));
  } else {
    task_runner->PostTask(FROM_HERE,
                          base::Bind(callback, base::Passed(asset_dir.Pass())));
  }
  base::DeleteFile(zip_path, false);
}

}  // namespace

AssetUnpackerJob::AssetUnpackerJob(
    InterfaceRequest<AssetBundle> asset_bundle,
    scoped_refptr<base::TaskRunner> worker_runner)
    : asset_bundle_(asset_bundle.Pass()),
      worker_runner_(worker_runner.Pass()),
      weak_factory_(this) {
}

AssetUnpackerJob::~AssetUnpackerJob() {
}

void AssetUnpackerJob::Unpack(ScopedDataPipeConsumerHandle zipped_assets) {
  base::FilePath zip_path;
  if (!CreateTemporaryFile(&zip_path)) {
    delete this;
    return;
  }
  common::CopyToFile(zipped_assets.Pass(), zip_path, worker_runner_.get(),
                     base::Bind(&AssetUnpackerJob::OnZippedAssetsAvailable,
                                weak_factory_.GetWeakPtr(), zip_path));
}

void AssetUnpackerJob::OnZippedAssetsAvailable(const base::FilePath& zip_path,
                                               bool success) {
  if (!success) {
    delete this;
    return;
  }
  scoped_ptr<base::ScopedTempDir> asset_dir(new base::ScopedTempDir());
  if (!asset_dir->CreateUniqueTempDir()) {
    delete this;
    return;
  }
  worker_runner_->PostTask(
      FROM_HERE,
      base::Bind(&UnzipAssets, zip_path, base::Passed(asset_dir.Pass()),
                 base::MessageLoop::current()->task_runner(),
                 base::Bind(&AssetUnpackerJob::OnUnzippedAssetsAvailable,
                            weak_factory_.GetWeakPtr())));
}

void AssetUnpackerJob::OnUnzippedAssetsAvailable(
    scoped_ptr<base::ScopedTempDir> asset_dir) {
  if (asset_dir)
    new AssetBundleImpl(asset_bundle_.Pass(), asset_dir.Pass(), worker_runner_);

  delete this;
}

}  // namespace asset_bundle
}  // namespace mojo

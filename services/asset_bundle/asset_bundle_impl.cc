// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/asset_bundle/asset_bundle_impl.h"

#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "mojo/common/data_pipe_utils.h"

namespace mojo {
namespace asset_bundle {
namespace {

void Ignored(bool) {
}

}  // namespace

AssetBundleImpl::AssetBundleImpl(InterfaceRequest<AssetBundle> request,
                                 scoped_ptr<base::ScopedTempDir> asset_dir,
                                 scoped_refptr<base::TaskRunner> worker_runner)
    : binding_(this, request.Pass()),
      asset_dir_(asset_dir.Pass()),
      worker_runner_(worker_runner.Pass()) {
}

AssetBundleImpl::~AssetBundleImpl() {
}

void AssetBundleImpl::GetAsStream(
    const String& asset_name,
    const Callback<void(ScopedDataPipeConsumerHandle)>& callback) {
  DataPipe pipe;
  callback.Run(pipe.consumer_handle.Pass());

  std::string asset_string = asset_name.To<std::string>();
  base::FilePath asset_path =
      base::MakeAbsoluteFilePath(asset_dir_->path().Append(asset_string));

  if (!asset_dir_->path().IsParent(asset_path)) {
    LOG(WARNING) << "Requested asset '" << asset_string << "' does not exist.";
    return;
  }

  common::CopyFromFile(asset_path, pipe.producer_handle.Pass(), 0,
                       worker_runner_.get(), base::Bind(&Ignored));
}

}  // namespace asset_bundle
}  // namespace mojo

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/directory_asset_bundle.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/task_runner.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/worker_pool.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"

namespace blink {

namespace {

void Ignored(bool) {
}

}  // namespace

void DirectoryAssetBundleService::Create(
    mojo::InterfaceRequest<mojo::asset_bundle::AssetBundle> request,
    const base::FilePath& directory) {
  new DirectoryAssetBundleService(request.Pass(), directory);
}

void DirectoryAssetBundleService::GetAsStream(
    const mojo::String& asset_name,
    const mojo::Callback<void(mojo::ScopedDataPipeConsumerHandle)>& callback) {
  mojo::DataPipe pipe;
  callback.Run(pipe.consumer_handle.Pass());
  base::FilePath asset_path(asset_name.data());
  base::FilePath file_path = directory_.Append(asset_path);
  scoped_refptr<base::TaskRunner> worker_runner =
      base::WorkerPool::GetTaskRunner(true);
  mojo::common::CopyFromFile(file_path,
                             pipe.producer_handle.Pass(),
                             0,
                             worker_runner.get(),
                             base::Bind(&Ignored));
}

DirectoryAssetBundleService::~DirectoryAssetBundleService() {
}

DirectoryAssetBundleService::DirectoryAssetBundleService(
    mojo::InterfaceRequest<AssetBundle> request,
    const base::FilePath& directory)
        : binding_(this, request.Pass()),
          directory_(directory) {
}

}  // namespace blink

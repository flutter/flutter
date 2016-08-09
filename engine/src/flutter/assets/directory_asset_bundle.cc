// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/directory_asset_bundle.h"

#include <fcntl.h>
#include <unistd.h>

#include <utility>

#include "flutter/glue/data_pipe_utils.h"
#include "lib/ftl/files/eintr_wrapper.h"
#include "lib/ftl/files/path.h"
#include "lib/ftl/files/unique_fd.h"

namespace blink {

void DirectoryAssetBundle::GetAsStream(
    const mojo::String& asset_name,
    const mojo::Callback<void(mojo::ScopedDataPipeConsumerHandle)>& callback) {
  mojo::DataPipe pipe;
  callback.Run(std::move(pipe.consumer_handle));

  std::string asset_path =
      files::SimplifyPath(directory_ + "/" + asset_name.get());
  if (asset_path.find(directory_) != 0u) {
    FTL_LOG(ERROR) << "Asset name '" << asset_name
                   << "' attempted to traverse outside asset bundle.";
    return;
  }

  // TODO(abarth): Consider moving the |open| call to task_runner_.
  ftl::UniqueFD fd(HANDLE_EINTR(open(asset_path.c_str(), O_RDONLY)));
  if (fd.get() < 0)
    return;
  glue::CopyFromFileDescriptor(std::move(fd), std::move(pipe.producer_handle),
                               task_runner_.get(), [](bool ignored) {});
}

DirectoryAssetBundle::~DirectoryAssetBundle() {}

DirectoryAssetBundle::DirectoryAssetBundle(
    mojo::InterfaceRequest<AssetBundle> request,
    std::string directory,
    ftl::RefPtr<ftl::TaskRunner> task_runner)
    : binding_(this, std::move(request)),
      directory_(std::move(directory)),
      task_runner_(std::move(task_runner)) {}

}  // namespace blink

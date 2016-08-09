// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/unzip_job.h"

#include <utility>

#include "mojo/public/cpp/environment/environment.h"
#include "third_party/zlib/contrib/minizip/unzip.h"

namespace blink {

UnzipJob::UnzipJob(std::string zip_path,
                   std::string asset_name,
                   mojo::ScopedDataPipeProducerHandle producer,
                   ftl::RefPtr<ftl::TaskRunner> task_runner)
    : zip_path_(std::move(zip_path)),
      asset_name_(std::move(asset_name)),
      producer_(std::move(producer)),
      task_runner_(std::move(task_runner)),
      waiter_(mojo::Environment::GetDefaultAsyncWaiter()),
      wait_id_(0) {
  task_runner_->PostTask([this]() { Start(); });
}

UnzipJob::~UnzipJob() {}

void UnzipJob::Start() {
  zip_file_.reset(unzOpen2(zip_path_.c_str(), nullptr));

  if (!zip_file_.is_valid()) {
    FTL_LOG(ERROR) << "Unable to open ZIP file: " << zip_path_;
    delete this;
    return;
  }

  int result = unzLocateFile(zip_file_.get(), asset_name_.c_str(), 0);
  if (result != UNZ_OK) {
    FTL_LOG(WARNING) << "Requested asset '" << asset_name_
                     << "' does not exist.";
    delete this;
    return;
  }

  result = unzOpenCurrentFile(zip_file_.get());
  if (result != UNZ_OK) {
    FTL_LOG(WARNING) << "unzOpenCurrentFile failed, error=" << result;
    delete this;
    return;
  }

  OnHandleReady(MOJO_RESULT_OK);
}

void UnzipJob::OnHandleReady(MojoResult result) {
  if (result == MOJO_RESULT_OK) {
    void* buffer = nullptr;
    uint32_t size = 0;
    result = mojo::BeginWriteDataRaw(producer_.get(), &buffer, &size,
                                     MOJO_WRITE_DATA_FLAG_NONE);
    if (result == MOJO_RESULT_OK) {
      FTL_DCHECK(size < static_cast<uint32_t>(std::numeric_limits<int>::max()));
      ssize_t bytes_read = unzReadCurrentFile(zip_file_.get(), buffer, size);
      result = mojo::EndWriteDataRaw(producer_.get(),
                                     std::max<ssize_t>(0l, bytes_read));
      if (bytes_read < 0) {
        FTL_LOG(WARNING) << "Asset unzip failed, error=" << bytes_read;
        delete this;
      } else if (result != MOJO_RESULT_OK) {
        FTL_LOG(WARNING) << "Mojo EndWrite failed, error=" << result;
        delete this;
      } else if (bytes_read < size) {
        // Reached EOF. Stop the process.
        delete this;
      } else {
        task_runner_->PostTask([this]() { OnHandleReady(MOJO_RESULT_OK); });
      }
      return;
    }
  }
  if (result == MOJO_RESULT_SHOULD_WAIT) {
    wait_id_ =
        waiter_->AsyncWait(producer_.get().value(), MOJO_HANDLE_SIGNAL_WRITABLE,
                           MOJO_DEADLINE_INDEFINITE, &WaitComplete, this);
    return;
  }
  delete this;
}

void UnzipJob::WaitComplete(void* context, MojoResult result) {
  UnzipJob* job = static_cast<UnzipJob*>(context);
  job->wait_id_ = 0;
  job->OnHandleReady(result);
}

}  // namespace blink

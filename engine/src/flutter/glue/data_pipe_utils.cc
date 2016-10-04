// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/glue/data_pipe_utils.h"

#include <stdio.h>
#include <unistd.h>

#include <algorithm>
#include <limits>
#include <utility>

#include "lib/ftl/files/file_descriptor.h"
#include "mojo/public/cpp/environment/async_waiter.h"
#include "mojo/public/cpp/environment/environment.h"

namespace glue {
namespace {

// CopyToFileHandler -----------------------------------------------------------

class CopyToFileHandler {
 public:
  CopyToFileHandler(mojo::ScopedDataPipeConsumerHandle source,
                    ftl::UniqueFD destination,
                    ftl::RefPtr<ftl::TaskRunner> task_runner,
                    const std::function<void(bool)>& callback);

 private:
  ~CopyToFileHandler();

  void SendCallback(bool value);
  void OnHandleReady(MojoResult result);
  static void WaitComplete(void* context, MojoResult result);

  mojo::ScopedDataPipeConsumerHandle source_;
  ftl::UniqueFD destination_;
  ftl::RefPtr<ftl::TaskRunner> task_runner_;
  std::function<void(bool)> callback_;
  const MojoAsyncWaiter* waiter_;
  MojoAsyncWaitID wait_id_;

  FTL_DISALLOW_COPY_AND_ASSIGN(CopyToFileHandler);
};

CopyToFileHandler::CopyToFileHandler(mojo::ScopedDataPipeConsumerHandle source,
                                     ftl::UniqueFD destination,
                                     ftl::RefPtr<ftl::TaskRunner> task_runner,
                                     const std::function<void(bool)>& callback)
    : source_(std::move(source)),
      destination_(std::move(destination)),
      task_runner_(std::move(task_runner)),
      callback_(callback),
      waiter_(mojo::Environment::GetDefaultAsyncWaiter()),
      wait_id_(0) {
  task_runner_->PostTask([this]() { OnHandleReady(MOJO_RESULT_OK); });
}

CopyToFileHandler::~CopyToFileHandler() {}

void CopyToFileHandler::SendCallback(bool value) {
  FTL_DCHECK(!wait_id_);
  auto callback = callback_;
  delete this;
  callback(value);
}

void CopyToFileHandler::OnHandleReady(MojoResult result) {
  if (result == MOJO_RESULT_OK) {
    const void* buffer = nullptr;
    uint32_t size = 0;
    result = BeginReadDataRaw(source_.get(), &buffer, &size,
                              MOJO_READ_DATA_FLAG_NONE);
    if (result == MOJO_RESULT_OK) {
      bool write_success = ftl::WriteFileDescriptor(
          destination_.get(), static_cast<const char*>(buffer), size);
      result = EndReadDataRaw(source_.get(), size);
      if (!write_success || result != MOJO_RESULT_OK) {
        SendCallback(false);
      } else {
        task_runner_->PostTask([this]() { OnHandleReady(MOJO_RESULT_OK); });
      }
      return;
    }
  }
  if (result == MOJO_RESULT_FAILED_PRECONDITION) {
    SendCallback(true);
    return;
  }
  if (result == MOJO_RESULT_SHOULD_WAIT) {
    wait_id_ =
        waiter_->AsyncWait(source_.get().value(), MOJO_HANDLE_SIGNAL_READABLE,
                           MOJO_DEADLINE_INDEFINITE, &WaitComplete, this);
    return;
  }
  SendCallback(false);
}

void CopyToFileHandler::WaitComplete(void* context, MojoResult result) {
  CopyToFileHandler* handler = static_cast<CopyToFileHandler*>(context);
  handler->wait_id_ = 0;
  handler->OnHandleReady(result);
}

// CopyFromFileHandler ---------------------------------------------------------

class CopyFromFileHandler {
 public:
  CopyFromFileHandler(ftl::UniqueFD source,
                      mojo::ScopedDataPipeProducerHandle destination,
                      ftl::RefPtr<ftl::TaskRunner> task_runner,
                      const std::function<void(bool)>& callback);

 private:
  ~CopyFromFileHandler();

  void SendCallback(bool value);
  void OnHandleReady(MojoResult result);
  static void WaitComplete(void* context, MojoResult result);

  ftl::UniqueFD source_;
  mojo::ScopedDataPipeProducerHandle destination_;
  ftl::RefPtr<ftl::TaskRunner> task_runner_;
  std::function<void(bool)> callback_;
  const MojoAsyncWaiter* waiter_;
  MojoAsyncWaitID wait_id_;

  FTL_DISALLOW_COPY_AND_ASSIGN(CopyFromFileHandler);
};

CopyFromFileHandler::CopyFromFileHandler(
    ftl::UniqueFD source,
    mojo::ScopedDataPipeProducerHandle destination,
    ftl::RefPtr<ftl::TaskRunner> task_runner,
    const std::function<void(bool)>& callback)
    : source_(std::move(source)),
      destination_(std::move(destination)),
      task_runner_(std::move(task_runner)),
      callback_(callback),
      waiter_(mojo::Environment::GetDefaultAsyncWaiter()),
      wait_id_(0) {
  task_runner_->PostTask([this]() { OnHandleReady(MOJO_RESULT_OK); });
}

CopyFromFileHandler::~CopyFromFileHandler() {}

void CopyFromFileHandler::SendCallback(bool value) {
  FTL_DCHECK(!wait_id_);
  auto callback = callback_;
  delete this;
  callback(value);
}

void CopyFromFileHandler::OnHandleReady(MojoResult result) {
  if (result == MOJO_RESULT_OK) {
    void* buffer = nullptr;
    uint32_t size = 0;
    result = BeginWriteDataRaw(destination_.get(), &buffer, &size,
                               MOJO_WRITE_DATA_FLAG_NONE);
    if (result == MOJO_RESULT_OK) {
      FTL_DCHECK(size < static_cast<uint32_t>(std::numeric_limits<int>::max()));
      ssize_t bytes_read = ftl::ReadFileDescriptor(
          source_.get(), static_cast<char*>(buffer), size);
      result = EndWriteDataRaw(destination_.get(),
                               std::max<ssize_t>(0l, bytes_read));
      if (bytes_read == -1 || result != MOJO_RESULT_OK) {
        SendCallback(false);
      } else if (bytes_read < size) {
        // Reached EOF. Stop the process.
        SendCallback(true);
      } else {
        task_runner_->PostTask([this]() { OnHandleReady(MOJO_RESULT_OK); });
      }
      return;
    }
  }
  if (result == MOJO_RESULT_SHOULD_WAIT) {
    wait_id_ = waiter_->AsyncWait(
        destination_.get().value(), MOJO_HANDLE_SIGNAL_WRITABLE,
        MOJO_DEADLINE_INDEFINITE, &WaitComplete, this);
    return;
  }
  SendCallback(false);
}

void CopyFromFileHandler::WaitComplete(void* context, MojoResult result) {
  CopyFromFileHandler* handler = static_cast<CopyFromFileHandler*>(context);
  handler->wait_id_ = 0;
  handler->OnHandleReady(result);
}

}  // namespace

void CopyToFileDescriptor(mojo::ScopedDataPipeConsumerHandle source,
                          ftl::UniqueFD destination,
                          ftl::RefPtr<ftl::TaskRunner> task_runner,
                          const std::function<void(bool)>& callback) {
  new CopyToFileHandler(std::move(source), std::move(destination),
                        std::move(task_runner), callback);
}

void CopyFromFileDescriptor(ftl::UniqueFD source,
                            mojo::ScopedDataPipeProducerHandle destination,
                            ftl::RefPtr<ftl::TaskRunner> task_runner,
                            const std::function<void(bool)>& callback) {
  new CopyFromFileHandler(std::move(source), std::move(destination),
                          std::move(task_runner), callback);
}

}  // namespace glue

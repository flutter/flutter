// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/data_pipe_utils/data_pipe_utils.h"

#include <stdio.h>

#include <limits>
#include <memory>

#include "base/files/file.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/location.h"
#include "base/trace_event/trace_event.h"
#include "mojo/data_pipe_utils/data_pipe_utils_internal.h"
#include "mojo/public/cpp/environment/async_waiter.h"

namespace mojo {
namespace common {
namespace {

class CopyToFileHandler {
 public:
  CopyToFileHandler(ScopedDataPipeConsumerHandle source,
                    const base::FilePath& destination,
                    base::TaskRunner* task_runner,
                    const base::Callback<void(bool)>& callback);

 private:
  ~CopyToFileHandler();

  void SendCallback(bool value);
  void OpenFile();
  void OnHandleReady(MojoResult result);
  void WriteToFile();

  ScopedDataPipeConsumerHandle source_;
  const base::FilePath destination_;
  base::TaskRunner* file_task_runner_;
  base::Callback<void(bool)> callback_;
  base::File file_;
  std::unique_ptr<AsyncWaiter> waiter_;
  const void* buffer_;
  uint32_t buffer_size_;
  scoped_refptr<base::SingleThreadTaskRunner> main_runner_;

  DISALLOW_COPY_AND_ASSIGN(CopyToFileHandler);
};

CopyToFileHandler::CopyToFileHandler(ScopedDataPipeConsumerHandle source,
                                     const base::FilePath& destination,
                                     base::TaskRunner* task_runner,
                                     const base::Callback<void(bool)>& callback)
    : source_(source.Pass()),
      destination_(destination),
      file_task_runner_(task_runner),
      callback_(callback),
      buffer_(nullptr),
      buffer_size_(0u),
      main_runner_(base::MessageLoop::current()->task_runner()) {
  TRACE_EVENT_ASYNC_BEGIN1("data_pipe_utils", "CopyToFile", this, "destination",
                           destination.MaybeAsASCII());
  file_task_runner_->PostTask(
      FROM_HERE,
      base::Bind(&CopyToFileHandler::OpenFile, base::Unretained(this)));
}

CopyToFileHandler::~CopyToFileHandler() {
  TRACE_EVENT_ASYNC_END0("data_pipe_utils", "CopyToFile", this);
}

void CopyToFileHandler::SendCallback(bool value) {
  DCHECK(main_runner_->RunsTasksOnCurrentThread());
  if (file_.IsValid()) {
    // Need to close the file before calling the callback.
    file_task_runner_->PostTaskAndReply(
        FROM_HERE, base::Bind(&base::File::Close, base::Unretained(&file_)),
        base::Bind(&CopyToFileHandler::SendCallback, base::Unretained(this),
                   value));
    return;
  }
  base::Callback<void(bool)> callback = callback_;
  delete this;
  callback.Run(value);
}

void CopyToFileHandler::OpenFile() {
  DCHECK(file_task_runner_->RunsTasksOnCurrentThread());
  file_.Initialize(destination_,
                   base::File::FLAG_CREATE_ALWAYS | base::File::FLAG_WRITE);
  if (!file_.IsValid()) {
    LOG(ERROR) << "Opening file '" << destination_.value()
               << "' failed in CopyToFileHandler::OpenFile";
    main_runner_->PostTask(FROM_HERE,
                           base::Bind(&CopyToFileHandler::SendCallback,
                                      base::Unretained(this), false));
    return;
  }
  main_runner_->PostTask(FROM_HERE,
                         base::Bind(&CopyToFileHandler::OnHandleReady,
                                    base::Unretained(this), MOJO_RESULT_OK));
}

void CopyToFileHandler::OnHandleReady(MojoResult result) {
  DCHECK(main_runner_->RunsTasksOnCurrentThread());
  if (result == MOJO_RESULT_OK) {
    result = BeginReadDataRaw(source_.get(), &buffer_, &buffer_size_,
                              MOJO_READ_DATA_FLAG_NONE);
    if (result == MOJO_RESULT_OK) {
      file_task_runner_->PostTask(
          FROM_HERE,
          base::Bind(&CopyToFileHandler::WriteToFile, base::Unretained(this)));
      return;
    }
  }
  if (result == MOJO_RESULT_FAILED_PRECONDITION) {
    SendCallback(true);
    return;
  }
  if (result == MOJO_RESULT_SHOULD_WAIT) {
    waiter_.reset(new AsyncWaiter(
        source_.get(), MOJO_HANDLE_SIGNAL_READABLE,
        base::Bind(&CopyToFileHandler::OnHandleReady, base::Unretained(this))));
    return;
  }
  SendCallback(false);
}

void CopyToFileHandler::WriteToFile() {
  DCHECK(file_task_runner_->RunsTasksOnCurrentThread());
  uint32_t num_bytes = buffer_size_;
  size_t num_bytes_written =
      file_.WriteAtCurrentPos(static_cast<const char*>(buffer_), num_bytes);
  MojoResult result = EndReadDataRaw(source_.get(), num_bytes);
  buffer_ = nullptr;
  buffer_size_ = 0;
  if (num_bytes_written != num_bytes) {
    LOG(ERROR) << "Wrote fewer bytes (" << num_bytes_written
               << ") than expected (" << num_bytes
               << "), (pipe closed? out of disk space?)";
    main_runner_->PostTask(FROM_HERE,
                           base::Bind(&CopyToFileHandler::SendCallback,
                                      base::Unretained(this), false));
    return;
  }
  if (result != MOJO_RESULT_OK) {
    LOG(ERROR) << "EndReadDataRaw error (" << result << ")";
    main_runner_->PostTask(FROM_HERE,
                           base::Bind(&CopyToFileHandler::SendCallback,
                                      base::Unretained(this), false));
  }
  main_runner_->PostTask(FROM_HERE,
                         base::Bind(&CopyToFileHandler::OnHandleReady,
                                    base::Unretained(this), result));
}

class CopyFromFileHandler {
 public:
  CopyFromFileHandler(const base::FilePath& source,
                      ScopedDataPipeProducerHandle destination,
                      uint32_t skip,
                      base::TaskRunner* task_runner,
                      const base::Callback<void(bool)>& callback);

 private:
  ~CopyFromFileHandler();

  void SendCallback(bool value);
  void OpenFile();
  void OnHandleReady(MojoResult result);
  void ReadFromFile();

  const base::FilePath source_;
  ScopedDataPipeProducerHandle destination_;
  uint32_t skip_;
  base::TaskRunner* file_task_runner_;
  base::Callback<void(bool)> callback_;
  base::File file_;
  std::unique_ptr<AsyncWaiter> waiter_;
  void* buffer_;
  uint32_t buffer_size_;
  scoped_refptr<base::SingleThreadTaskRunner> main_runner_;

  DISALLOW_COPY_AND_ASSIGN(CopyFromFileHandler);
};

CopyFromFileHandler::CopyFromFileHandler(
    const base::FilePath& source,
    ScopedDataPipeProducerHandle destination,
    uint32_t skip,
    base::TaskRunner* task_runner,
    const base::Callback<void(bool)>& callback)
    : source_(source),
      destination_(destination.Pass()),
      skip_(skip),
      file_task_runner_(task_runner),
      callback_(callback),
      buffer_(nullptr),
      buffer_size_(0u),
      main_runner_(base::MessageLoop::current()->task_runner()) {
  TRACE_EVENT_ASYNC_BEGIN1("data_pipe_utils", "CopyFromFile", this, "source",
                           source.MaybeAsASCII());
  file_task_runner_->PostTask(
      FROM_HERE,
      base::Bind(&CopyFromFileHandler::OpenFile, base::Unretained(this)));
}

CopyFromFileHandler::~CopyFromFileHandler() {
  TRACE_EVENT_ASYNC_END0("data_pipe_utils", "CopyFromFile", this);
}

void CopyFromFileHandler::SendCallback(bool value) {
  DCHECK(main_runner_->RunsTasksOnCurrentThread());
  if (file_.IsValid()) {
    // Need to close the file before calling the callback.
    file_task_runner_->PostTaskAndReply(
        FROM_HERE, base::Bind(&base::File::Close, base::Unretained(&file_)),
        base::Bind(&CopyFromFileHandler::SendCallback, base::Unretained(this),
                   value));
    return;
  }
  base::Callback<void(bool)> callback = callback_;
  delete this;
  callback.Run(value);
}

void CopyFromFileHandler::OpenFile() {
  DCHECK(file_task_runner_->RunsTasksOnCurrentThread());
  file_.Initialize(source_, base::File::FLAG_OPEN | base::File::FLAG_READ);
  if (!file_.IsValid()) {
    LOG(ERROR) << "Opening file '" << source_.value()
               << "' failed in CopyFromFileHandler::OpenFile";
    main_runner_->PostTask(FROM_HERE,
                           base::Bind(&CopyFromFileHandler::SendCallback,
                                      base::Unretained(this), false));
    return;
  }
  if (file_.Seek(base::File::FROM_BEGIN, skip_) != skip_) {
    LOG(ERROR) << "Seek of " << skip_ << " failed";
    main_runner_->PostTask(FROM_HERE,
                           base::Bind(&CopyFromFileHandler::SendCallback,
                                      base::Unretained(this), false));
    return;
  }
  main_runner_->PostTask(FROM_HERE,
                         base::Bind(&CopyFromFileHandler::OnHandleReady,
                                    base::Unretained(this), MOJO_RESULT_OK));
}

void CopyFromFileHandler::OnHandleReady(MojoResult result) {
  DCHECK(main_runner_->RunsTasksOnCurrentThread());
  if (result == MOJO_RESULT_OK) {
    result = BeginWriteDataRaw(destination_.get(), &buffer_, &buffer_size_,
                               MOJO_READ_DATA_FLAG_NONE);
    if (result == MOJO_RESULT_OK) {
      file_task_runner_->PostTask(FROM_HERE,
                                  base::Bind(&CopyFromFileHandler::ReadFromFile,
                                             base::Unretained(this)));

      return;
    }
  }
  if (result == MOJO_RESULT_SHOULD_WAIT) {
    waiter_.reset(
        new AsyncWaiter(destination_.get(), MOJO_HANDLE_SIGNAL_WRITABLE,
                        base::Bind(&CopyFromFileHandler::OnHandleReady,
                                   base::Unretained(this))));
    return;
  }
  SendCallback(false);
}

void CopyFromFileHandler::ReadFromFile() {
  DCHECK(file_task_runner_->RunsTasksOnCurrentThread());
  DCHECK_LT(buffer_size_,
            static_cast<uint32_t>(std::numeric_limits<int>::max()));
  int num_bytes = buffer_size_;
  int num_bytes_read =
      file_.ReadAtCurrentPos(static_cast<char*>(buffer_), num_bytes);
  MojoResult result =
      EndWriteDataRaw(destination_.get(), std::max(0, num_bytes_read));
  buffer_ = nullptr;
  buffer_size_ = 0;
  if (num_bytes_read == -1) {
    LOG(ERROR) << "Error while reading from file.";
    main_runner_->PostTask(FROM_HERE,
                           base::Bind(&CopyFromFileHandler::SendCallback,
                                      base::Unretained(this), false));
    return;
  }
  if (result != MOJO_RESULT_OK) {
    LOG(ERROR) << "EndWriteDataRaw error (" << result << ")";
    main_runner_->PostTask(FROM_HERE,
                           base::Bind(&CopyFromFileHandler::SendCallback,
                                      base::Unretained(this), false));
    return;
  }
  if (num_bytes_read != num_bytes) {
    // Reached EOF. Stop the process.
    main_runner_->PostTask(FROM_HERE,
                           base::Bind(&CopyFromFileHandler::SendCallback,
                                      base::Unretained(this), true));
    return;
  }
  main_runner_->PostTask(FROM_HERE,
                         base::Bind(&CopyFromFileHandler::OnHandleReady,
                                    base::Unretained(this), result));
}

size_t CopyToFileHelper(FILE* fp, const void* buffer, uint32_t num_bytes) {
  return fwrite(buffer, 1, num_bytes, fp);
}

}  // namespace

base::ScopedFILE BlockingCopyToTempFile(ScopedDataPipeConsumerHandle source) {
  base::FilePath path;
  base::ScopedFILE fp(CreateAndOpenTemporaryFile(&path));
  if (!fp) {
    LOG(ERROR) << "CreateAndOpenTemporaryFile failed in"
               << "BlockingCopyToTempFile";
    return nullptr;
  }
  if (unlink(path.value().c_str())) {
    LOG(ERROR) << "Failed to unlink temporary file";
    return nullptr;
  }
  if (!BlockingCopyHelper(source.Pass(),
                          base::Bind(&CopyToFileHelper, fp.get()))) {
    LOG(ERROR) << "Could not copy source to temporary file";
    return nullptr;
  }
  return fp;
}

bool BlockingCopyToFile(ScopedDataPipeConsumerHandle source, FILE* fp) {
  if (!BlockingCopyHelper(source.Pass(),
                          base::Bind(&CopyToFileHelper, fp))) {
    LOG(ERROR) << "Could not copy source to file";
    return false;
  }
  return true;
}

void CopyToFile(ScopedDataPipeConsumerHandle source,
                const base::FilePath& destination,
                base::TaskRunner* task_runner,
                const base::Callback<void(bool)>& callback) {
  new CopyToFileHandler(source.Pass(), destination, task_runner, callback);
}

void CopyFromFile(const base::FilePath& source,
                  ScopedDataPipeProducerHandle destination,
                  uint32_t skip,
                  base::TaskRunner* task_runner,
                  const base::Callback<void(bool)>& callback) {
  new CopyFromFileHandler(source, destination.Pass(), skip, task_runner,
                          callback);
}

}  // namespace common
}  // namespace mojo

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DATA_PIPE_UTILS_DATA_PIPE_UTILS_H_
#define MOJO_DATA_PIPE_UTILS_DATA_PIPE_UTILS_H_

#include <stdio.h>
#include <string>

#include "base/callback_forward.h"
#include "base/files/scoped_file.h"
#include "base/threading/platform_thread.h"
#include "mojo/public/cpp/system/data_pipe.h"

namespace base {
class FilePath;
class TaskRunner;
}

namespace mojo {
namespace common {

// Asynchronously copies data from source to the destination file. The given
// |callback| is run upon completion. File writes will be scheduled to the
// given |task_runner|.
void CopyToFile(ScopedDataPipeConsumerHandle source,
                const base::FilePath& destination,
                base::TaskRunner* task_runner,
                const base::Callback<void(bool /*success*/)>& callback);

void CopyFromFile(const base::FilePath& source,
                  ScopedDataPipeProducerHandle destination,
                  uint32_t skip,
                  base::TaskRunner* task_runner,
                  const base::Callback<void(bool /*success*/)>& callback);

// Copies the data from |source| into |contents| and returns true on success and
// false on error.  In case of I/O error, |contents| holds the data that could
// be read from source before the error occurred.
bool BlockingCopyToString(ScopedDataPipeConsumerHandle source,
                          std::string* contents);

bool BlockingCopyFromString(const std::string& source,
                            const ScopedDataPipeProducerHandle& destination);

// Synchronously copies source data to a temporary file, returning a file
// pointer on success and NULL on error. The temporary file is unlinked
// immediately so that it is only accessible by file pointer (and removed once
// closed or the creating process dies).
base::ScopedFILE BlockingCopyToTempFile(ScopedDataPipeConsumerHandle source);

// Similar to BlockingCopyToTempFile, but use a pre-defined file pointer
// (rather than a newly created temp file) and do not unlink the file.
// Returns true on success, false on failure.
bool BlockingCopyToFile(ScopedDataPipeConsumerHandle source, FILE* fp);

// Copies the string |contents| to a temporary data pipe and returns the
// consumer handle.
ScopedDataPipeConsumerHandle WriteStringToConsumerHandle(
    const std::string& source);

}  // namespace common
}  // namespace mojo

#endif  // MOJO_DATA_PIPE_UTILS_DATA_PIPE_UTILS_H_

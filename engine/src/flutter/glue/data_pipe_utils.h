// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GLUE_DATA_PIPE_FILES_H_
#define GLUE_DATA_PIPE_FILES_H_

#include <stdio.h>

#include <string>

#include "lib/ftl/files/unique_fd.h"
#include "lib/ftl/tasks/task_runner.h"
#include "mojo/public/cpp/system/data_pipe.h"

namespace glue {

// Asynchronously copies data from source to the destination file descriptor.
// The given |callback| is run upon completion. File writes and |callback| will
// be scheduled on the given |task_runner|.
void CopyToFileDescriptor(
    mojo::ScopedDataPipeConsumerHandle source,
    ftl::UniqueFD destination,
    ftl::TaskRunner* task_runner,
    const std::function<void(bool /*success*/)>& callback);

// Asynchronously copies data from source file to the destination. The given
// |callback| is run upon completion. File reads and |callback| will be
// scheduled to the given |task_runner|.
void CopyFromFileDescriptor(
    ftl::UniqueFD source,
    mojo::ScopedDataPipeProducerHandle destination,
    ftl::TaskRunner* task_runner,
    const std::function<void(bool /*success*/)>& callback);

}  // namespace glue

#endif  // GLUE_DATA_PIPE_FILES_H_

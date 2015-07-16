// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/data_pipe_utils.h"

#include "base/bind.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/message_loop/message_loop.h"
#include "base/synchronization/condition_variable.h"
#include "base/threading/sequenced_worker_pool.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace common {
namespace {

void TransferBooleanValueAndExecute(const base::Closure& closure,
                                    bool* to_write,
                                    bool value) {
  *to_write = value;
  if (!closure.is_null()) {
    closure.Run();
  }
}

TEST(DataPipeUtilsTest, AsyncFileTransfer) {
  const char kData[] = "Hello world.";
  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  base::FilePath input;
  base::FilePath output;
  ASSERT_TRUE(base::CreateTemporaryFileInDir(temp_dir.path(), &input));
  ASSERT_TRUE(base::CreateTemporaryFileInDir(temp_dir.path(), &output));
  ASSERT_TRUE(base::WriteFile(input, kData, arraysize(kData)));
  base::MessageLoop loop;
  scoped_refptr<base::SequencedWorkerPool> blocking_pool =
      new base::SequencedWorkerPool(2, "blocking_pool");

  bool write_succeded = false;
  bool read_succeded = false;

  DataPipe pipes;
  CopyFromFile(input, pipes.producer_handle.Pass(), 0, blocking_pool.get(),
               base::Bind(&TransferBooleanValueAndExecute, base::Closure(),
                          base::Unretained(&write_succeded)));
  CopyToFile(pipes.consumer_handle.Pass(), output, blocking_pool.get(),
             base::Bind(&TransferBooleanValueAndExecute,
                        base::MessageLoop::QuitClosure(),
                        base::Unretained(&read_succeded)));
  loop.Run();

  EXPECT_TRUE(write_succeded);
  EXPECT_TRUE(read_succeded);
  EXPECT_TRUE(base::ContentsEqual(input, output));

  blocking_pool->Shutdown();
}

}  // namespace
}  // namespace common
}  // namespace mojo

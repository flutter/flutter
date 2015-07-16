// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/important_file_writer.h"

#include "base/bind.h"
#include "base/compiler_specific.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/run_loop.h"
#include "base/single_thread_task_runner.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/thread.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

std::string GetFileContent(const FilePath& path) {
  std::string content;
  if (!ReadFileToString(path, &content)) {
    NOTREACHED();
  }
  return content;
}

class DataSerializer : public ImportantFileWriter::DataSerializer {
 public:
  explicit DataSerializer(const std::string& data) : data_(data) {
  }

  bool SerializeData(std::string* output) override {
    output->assign(data_);
    return true;
  }

 private:
  const std::string data_;
};

class SuccessfulWriteObserver {
 public:
  SuccessfulWriteObserver() : successful_write_observed_(false) {}

  // Register on_successful_write() to be called on the next successful write
  // of |writer|.
  void ObserveNextSuccessfulWrite(ImportantFileWriter* writer);

  // Returns true if a successful write was observed via on_successful_write()
  // and resets the observation state to false regardless.
  bool GetAndResetObservationState();

 private:
  void on_successful_write() {
    EXPECT_FALSE(successful_write_observed_);
    successful_write_observed_ = true;
  }

  bool successful_write_observed_;

  DISALLOW_COPY_AND_ASSIGN(SuccessfulWriteObserver);
};

void SuccessfulWriteObserver::ObserveNextSuccessfulWrite(
    ImportantFileWriter* writer) {
  writer->RegisterOnNextSuccessfulWriteCallback(base::Bind(
      &SuccessfulWriteObserver::on_successful_write, base::Unretained(this)));
}

bool SuccessfulWriteObserver::GetAndResetObservationState() {
  bool was_successful_write_observed = successful_write_observed_;
  successful_write_observed_ = false;
  return was_successful_write_observed;
}

}  // namespace

class ImportantFileWriterTest : public testing::Test {
 public:
  ImportantFileWriterTest() { }
  void SetUp() override {
    ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
    file_ = temp_dir_.path().AppendASCII("test-file");
  }

 protected:
  SuccessfulWriteObserver successful_write_observer_;
  FilePath file_;
  MessageLoop loop_;

 private:
  ScopedTempDir temp_dir_;
};

TEST_F(ImportantFileWriterTest, Basic) {
  ImportantFileWriter writer(file_, ThreadTaskRunnerHandle::Get());
  EXPECT_FALSE(PathExists(writer.path()));
  EXPECT_FALSE(successful_write_observer_.GetAndResetObservationState());
  writer.WriteNow(make_scoped_ptr(new std::string("foo")));
  RunLoop().RunUntilIdle();

  EXPECT_FALSE(successful_write_observer_.GetAndResetObservationState());
  ASSERT_TRUE(PathExists(writer.path()));
  EXPECT_EQ("foo", GetFileContent(writer.path()));
}

TEST_F(ImportantFileWriterTest, BasicWithSuccessfulWriteObserver) {
  ImportantFileWriter writer(file_, ThreadTaskRunnerHandle::Get());
  EXPECT_FALSE(PathExists(writer.path()));
  EXPECT_FALSE(successful_write_observer_.GetAndResetObservationState());
  successful_write_observer_.ObserveNextSuccessfulWrite(&writer);
  writer.WriteNow(make_scoped_ptr(new std::string("foo")));
  RunLoop().RunUntilIdle();

  // Confirm that the observer is invoked.
  EXPECT_TRUE(successful_write_observer_.GetAndResetObservationState());
  ASSERT_TRUE(PathExists(writer.path()));
  EXPECT_EQ("foo", GetFileContent(writer.path()));

  // Confirm that re-installing the observer works for another write.
  EXPECT_FALSE(successful_write_observer_.GetAndResetObservationState());
  successful_write_observer_.ObserveNextSuccessfulWrite(&writer);
  writer.WriteNow(make_scoped_ptr(new std::string("bar")));
  RunLoop().RunUntilIdle();

  EXPECT_TRUE(successful_write_observer_.GetAndResetObservationState());
  ASSERT_TRUE(PathExists(writer.path()));
  EXPECT_EQ("bar", GetFileContent(writer.path()));

  // Confirm that writing again without re-installing the observer doesn't
  // result in a notification.
  EXPECT_FALSE(successful_write_observer_.GetAndResetObservationState());
  writer.WriteNow(make_scoped_ptr(new std::string("baz")));
  RunLoop().RunUntilIdle();

  EXPECT_FALSE(successful_write_observer_.GetAndResetObservationState());
  ASSERT_TRUE(PathExists(writer.path()));
  EXPECT_EQ("baz", GetFileContent(writer.path()));
}

TEST_F(ImportantFileWriterTest, ScheduleWrite) {
  ImportantFileWriter writer(file_, ThreadTaskRunnerHandle::Get());
  writer.set_commit_interval(TimeDelta::FromMilliseconds(25));
  EXPECT_FALSE(writer.HasPendingWrite());
  DataSerializer serializer("foo");
  writer.ScheduleWrite(&serializer);
  EXPECT_TRUE(writer.HasPendingWrite());
  ThreadTaskRunnerHandle::Get()->PostDelayedTask(
      FROM_HERE, MessageLoop::QuitWhenIdleClosure(),
      TimeDelta::FromMilliseconds(100));
  MessageLoop::current()->Run();
  EXPECT_FALSE(writer.HasPendingWrite());
  ASSERT_TRUE(PathExists(writer.path()));
  EXPECT_EQ("foo", GetFileContent(writer.path()));
}

TEST_F(ImportantFileWriterTest, DoScheduledWrite) {
  ImportantFileWriter writer(file_, ThreadTaskRunnerHandle::Get());
  EXPECT_FALSE(writer.HasPendingWrite());
  DataSerializer serializer("foo");
  writer.ScheduleWrite(&serializer);
  EXPECT_TRUE(writer.HasPendingWrite());
  writer.DoScheduledWrite();
  ThreadTaskRunnerHandle::Get()->PostDelayedTask(
      FROM_HERE, MessageLoop::QuitWhenIdleClosure(),
      TimeDelta::FromMilliseconds(100));
  MessageLoop::current()->Run();
  EXPECT_FALSE(writer.HasPendingWrite());
  ASSERT_TRUE(PathExists(writer.path()));
  EXPECT_EQ("foo", GetFileContent(writer.path()));
}

TEST_F(ImportantFileWriterTest, BatchingWrites) {
  ImportantFileWriter writer(file_, ThreadTaskRunnerHandle::Get());
  writer.set_commit_interval(TimeDelta::FromMilliseconds(25));
  DataSerializer foo("foo"), bar("bar"), baz("baz");
  writer.ScheduleWrite(&foo);
  writer.ScheduleWrite(&bar);
  writer.ScheduleWrite(&baz);
  ThreadTaskRunnerHandle::Get()->PostDelayedTask(
      FROM_HERE, MessageLoop::QuitWhenIdleClosure(),
      TimeDelta::FromMilliseconds(100));
  MessageLoop::current()->Run();
  ASSERT_TRUE(PathExists(writer.path()));
  EXPECT_EQ("baz", GetFileContent(writer.path()));
}

}  // namespace base

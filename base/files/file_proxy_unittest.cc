// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_proxy.h"

#include "base/bind.h"
#include "base/files/file.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/memory/weak_ptr.h"
#include "base/threading/thread.h"
#include "base/threading/thread_restrictions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class FileProxyTest : public testing::Test {
 public:
  FileProxyTest()
      : file_thread_("FileProxyTestFileThread"),
        error_(File::FILE_OK),
        bytes_written_(-1),
        weak_factory_(this) {}

  void SetUp() override {
    ASSERT_TRUE(dir_.CreateUniqueTempDir());
    ASSERT_TRUE(file_thread_.Start());
  }

  void DidFinish(File::Error error) {
    error_ = error;
    MessageLoop::current()->QuitWhenIdle();
  }

  void DidCreateOrOpen(File::Error error) {
    error_ = error;
    MessageLoop::current()->QuitWhenIdle();
  }

  void DidCreateTemporary(File::Error error,
                          const FilePath& path) {
    error_ = error;
    path_ = path;
    MessageLoop::current()->QuitWhenIdle();
  }

  void DidGetFileInfo(File::Error error,
                      const File::Info& file_info) {
    error_ = error;
    file_info_ = file_info;
    MessageLoop::current()->QuitWhenIdle();
  }

  void DidRead(File::Error error,
               const char* data,
               int bytes_read) {
    error_ = error;
    buffer_.resize(bytes_read);
    memcpy(&buffer_[0], data, bytes_read);
    MessageLoop::current()->QuitWhenIdle();
  }

  void DidWrite(File::Error error,
                int bytes_written) {
    error_ = error;
    bytes_written_ = bytes_written;
    MessageLoop::current()->QuitWhenIdle();
  }

 protected:
  void CreateProxy(uint32 flags, FileProxy* proxy) {
    proxy->CreateOrOpen(
        test_path(), flags,
        Bind(&FileProxyTest::DidCreateOrOpen, weak_factory_.GetWeakPtr()));
    MessageLoop::current()->Run();
    EXPECT_TRUE(proxy->IsValid());
  }

  TaskRunner* file_task_runner() const {
    return file_thread_.task_runner().get();
  }
  const FilePath& test_dir_path() const { return dir_.path(); }
  const FilePath test_path() const { return dir_.path().AppendASCII("test"); }

  MessageLoopForIO message_loop_;
  Thread file_thread_;

  ScopedTempDir dir_;
  File::Error error_;
  FilePath path_;
  File::Info file_info_;
  std::vector<char> buffer_;
  int bytes_written_;
  WeakPtrFactory<FileProxyTest> weak_factory_;
};

TEST_F(FileProxyTest, CreateOrOpen_Create) {
  FileProxy proxy(file_task_runner());
  proxy.CreateOrOpen(
      test_path(),
      File::FLAG_CREATE | File::FLAG_READ,
      Bind(&FileProxyTest::DidCreateOrOpen, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();

  EXPECT_EQ(File::FILE_OK, error_);
  EXPECT_TRUE(proxy.IsValid());
  EXPECT_TRUE(proxy.created());
  EXPECT_TRUE(PathExists(test_path()));
}

TEST_F(FileProxyTest, CreateOrOpen_Open) {
  // Creates a file.
  base::WriteFile(test_path(), NULL, 0);
  ASSERT_TRUE(PathExists(test_path()));

  // Opens the created file.
  FileProxy proxy(file_task_runner());
  proxy.CreateOrOpen(
      test_path(),
      File::FLAG_OPEN | File::FLAG_READ,
      Bind(&FileProxyTest::DidCreateOrOpen, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();

  EXPECT_EQ(File::FILE_OK, error_);
  EXPECT_TRUE(proxy.IsValid());
  EXPECT_FALSE(proxy.created());
}

TEST_F(FileProxyTest, CreateOrOpen_OpenNonExistent) {
  FileProxy proxy(file_task_runner());
  proxy.CreateOrOpen(
      test_path(),
      File::FLAG_OPEN | File::FLAG_READ,
      Bind(&FileProxyTest::DidCreateOrOpen, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();
  EXPECT_EQ(File::FILE_ERROR_NOT_FOUND, error_);
  EXPECT_FALSE(proxy.IsValid());
  EXPECT_FALSE(proxy.created());
  EXPECT_FALSE(PathExists(test_path()));
}

TEST_F(FileProxyTest, CreateOrOpen_AbandonedCreate) {
  bool prev = ThreadRestrictions::SetIOAllowed(false);
  {
    FileProxy proxy(file_task_runner());
    proxy.CreateOrOpen(
        test_path(),
        File::FLAG_CREATE | File::FLAG_READ,
        Bind(&FileProxyTest::DidCreateOrOpen, weak_factory_.GetWeakPtr()));
  }
  MessageLoop::current()->Run();
  ThreadRestrictions::SetIOAllowed(prev);

  EXPECT_TRUE(PathExists(test_path()));
}

TEST_F(FileProxyTest, Close) {
  // Creates a file.
  FileProxy proxy(file_task_runner());
  CreateProxy(File::FLAG_CREATE | File::FLAG_WRITE, &proxy);

#if defined(OS_WIN)
  // This fails on Windows if the file is not closed.
  EXPECT_FALSE(base::Move(test_path(), test_dir_path().AppendASCII("new")));
#endif

  proxy.Close(Bind(&FileProxyTest::DidFinish, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();
  EXPECT_EQ(File::FILE_OK, error_);
  EXPECT_FALSE(proxy.IsValid());

  // Now it should pass on all platforms.
  EXPECT_TRUE(base::Move(test_path(), test_dir_path().AppendASCII("new")));
}

TEST_F(FileProxyTest, CreateTemporary) {
  {
    FileProxy proxy(file_task_runner());
    proxy.CreateTemporary(
        0 /* additional_file_flags */,
        Bind(&FileProxyTest::DidCreateTemporary, weak_factory_.GetWeakPtr()));
    MessageLoop::current()->Run();

    EXPECT_TRUE(proxy.IsValid());
    EXPECT_EQ(File::FILE_OK, error_);
    EXPECT_TRUE(PathExists(path_));

    // The file should be writable.
    proxy.Write(0, "test", 4,
                Bind(&FileProxyTest::DidWrite, weak_factory_.GetWeakPtr()));
    MessageLoop::current()->Run();
    EXPECT_EQ(File::FILE_OK, error_);
    EXPECT_EQ(4, bytes_written_);
  }

  // Make sure the written data can be read from the returned path.
  std::string data;
  EXPECT_TRUE(ReadFileToString(path_, &data));
  EXPECT_EQ("test", data);

  // Make sure we can & do delete the created file to prevent leaks on the bots.
  EXPECT_TRUE(base::DeleteFile(path_, false));
}

TEST_F(FileProxyTest, SetAndTake) {
  File file(test_path(), File::FLAG_CREATE | File::FLAG_READ);
  ASSERT_TRUE(file.IsValid());
  FileProxy proxy(file_task_runner());
  EXPECT_FALSE(proxy.IsValid());
  proxy.SetFile(file.Pass());
  EXPECT_TRUE(proxy.IsValid());
  EXPECT_FALSE(file.IsValid());

  file = proxy.TakeFile();
  EXPECT_FALSE(proxy.IsValid());
  EXPECT_TRUE(file.IsValid());
}

TEST_F(FileProxyTest, GetInfo) {
  // Setup.
  ASSERT_EQ(4, base::WriteFile(test_path(), "test", 4));
  File::Info expected_info;
  GetFileInfo(test_path(), &expected_info);

  // Run.
  FileProxy proxy(file_task_runner());
  CreateProxy(File::FLAG_OPEN | File::FLAG_READ, &proxy);
  proxy.GetInfo(
      Bind(&FileProxyTest::DidGetFileInfo, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();

  // Verify.
  EXPECT_EQ(File::FILE_OK, error_);
  EXPECT_EQ(expected_info.size, file_info_.size);
  EXPECT_EQ(expected_info.is_directory, file_info_.is_directory);
  EXPECT_EQ(expected_info.is_symbolic_link, file_info_.is_symbolic_link);
  EXPECT_EQ(expected_info.last_modified, file_info_.last_modified);
  EXPECT_EQ(expected_info.creation_time, file_info_.creation_time);
}

TEST_F(FileProxyTest, Read) {
  // Setup.
  const char expected_data[] = "bleh";
  int expected_bytes = arraysize(expected_data);
  ASSERT_EQ(expected_bytes,
            base::WriteFile(test_path(), expected_data, expected_bytes));

  // Run.
  FileProxy proxy(file_task_runner());
  CreateProxy(File::FLAG_OPEN | File::FLAG_READ, &proxy);

  proxy.Read(0, 128, Bind(&FileProxyTest::DidRead, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();

  // Verify.
  EXPECT_EQ(File::FILE_OK, error_);
  EXPECT_EQ(expected_bytes, static_cast<int>(buffer_.size()));
  for (size_t i = 0; i < buffer_.size(); ++i) {
    EXPECT_EQ(expected_data[i], buffer_[i]);
  }
}

TEST_F(FileProxyTest, WriteAndFlush) {
  FileProxy proxy(file_task_runner());
  CreateProxy(File::FLAG_CREATE | File::FLAG_WRITE, &proxy);

  const char data[] = "foo!";
  int data_bytes = arraysize(data);
  proxy.Write(0, data, data_bytes,
              Bind(&FileProxyTest::DidWrite, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();
  EXPECT_EQ(File::FILE_OK, error_);
  EXPECT_EQ(data_bytes, bytes_written_);

  // Flush the written data.  (So that the following read should always
  // succeed.  On some platforms it may work with or without this flush.)
  proxy.Flush(Bind(&FileProxyTest::DidFinish, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();
  EXPECT_EQ(File::FILE_OK, error_);

  // Verify the written data.
  char buffer[10];
  EXPECT_EQ(data_bytes, base::ReadFile(test_path(), buffer, data_bytes));
  for (int i = 0; i < data_bytes; ++i) {
    EXPECT_EQ(data[i], buffer[i]);
  }
}

TEST_F(FileProxyTest, SetTimes) {
  FileProxy proxy(file_task_runner());
  CreateProxy(
      File::FLAG_CREATE | File::FLAG_WRITE | File::FLAG_WRITE_ATTRIBUTES,
      &proxy);

  Time last_accessed_time = Time::Now() - TimeDelta::FromDays(12345);
  Time last_modified_time = Time::Now() - TimeDelta::FromHours(98765);

  proxy.SetTimes(last_accessed_time, last_modified_time,
                 Bind(&FileProxyTest::DidFinish, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();
  EXPECT_EQ(File::FILE_OK, error_);

  File::Info info;
  GetFileInfo(test_path(), &info);

  // The returned values may only have the seconds precision, so we cast
  // the double values to int here.
  EXPECT_EQ(static_cast<int>(last_modified_time.ToDoubleT()),
            static_cast<int>(info.last_modified.ToDoubleT()));
  EXPECT_EQ(static_cast<int>(last_accessed_time.ToDoubleT()),
            static_cast<int>(info.last_accessed.ToDoubleT()));
}

TEST_F(FileProxyTest, SetLength_Shrink) {
  // Setup.
  const char kTestData[] = "0123456789";
  ASSERT_EQ(10, base::WriteFile(test_path(), kTestData, 10));
  File::Info info;
  GetFileInfo(test_path(), &info);
  ASSERT_EQ(10, info.size);

  // Run.
  FileProxy proxy(file_task_runner());
  CreateProxy(File::FLAG_OPEN | File::FLAG_WRITE, &proxy);
  proxy.SetLength(7,
                  Bind(&FileProxyTest::DidFinish, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();

  // Verify.
  GetFileInfo(test_path(), &info);
  ASSERT_EQ(7, info.size);

  char buffer[7];
  EXPECT_EQ(7, base::ReadFile(test_path(), buffer, 7));
  int i = 0;
  for (; i < 7; ++i)
    EXPECT_EQ(kTestData[i], buffer[i]);
}

TEST_F(FileProxyTest, SetLength_Expand) {
  // Setup.
  const char kTestData[] = "9876543210";
  ASSERT_EQ(10, base::WriteFile(test_path(), kTestData, 10));
  File::Info info;
  GetFileInfo(test_path(), &info);
  ASSERT_EQ(10, info.size);

  // Run.
  FileProxy proxy(file_task_runner());
  CreateProxy(File::FLAG_OPEN | File::FLAG_WRITE, &proxy);
  proxy.SetLength(53,
                  Bind(&FileProxyTest::DidFinish, weak_factory_.GetWeakPtr()));
  MessageLoop::current()->Run();

  // Verify.
  GetFileInfo(test_path(), &info);
  ASSERT_EQ(53, info.size);

  char buffer[53];
  EXPECT_EQ(53, base::ReadFile(test_path(), buffer, 53));
  int i = 0;
  for (; i < 10; ++i)
    EXPECT_EQ(kTestData[i], buffer[i]);
  for (; i < 53; ++i)
    EXPECT_EQ(0, buffer[i]);
}

}  // namespace base

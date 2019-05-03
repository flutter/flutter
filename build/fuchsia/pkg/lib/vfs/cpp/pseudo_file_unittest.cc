// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/async-loop/cpp/loop.h>
#include <lib/fdio/limits.h>
#include <lib/fdio/fd.h>
#include <lib/fdio/fdio.h>
#include <lib/fdio/directory.h>
#include <unistd.h>
#include <zircon/processargs.h>

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

#include "lib/gtest/real_loop_fixture.h"
#include "lib/vfs/cpp/pseudo_file.h"

namespace {

class FileWrapper {
 public:
  const std::string& buffer() { return buffer_; };

  vfs::BufferedPseudoFile* file() { return file_.get(); };

  static FileWrapper CreateReadWriteFile(std::string initial_str,
                                         size_t capacity,
                                         bool start_loop = true) {
    return FileWrapper(true, initial_str, capacity, start_loop);
  }

  static FileWrapper CreateReadOnlyFile(std::string initial_str,
                                        bool start_loop = true) {
    return FileWrapper(false, initial_str, initial_str.length(), start_loop);
  }

  async_dispatcher_t* dispatcher() { return loop_.dispatcher(); }

  async::Loop& loop() { return loop_; }

 private:
  FileWrapper(bool write_allowed, std::string initial_str, size_t capacity,
              bool start_loop)
      : buffer_(std::move(initial_str)),
        loop_(&kAsyncLoopConfigNoAttachToThread) {
    auto readFn = [this](std::vector<uint8_t>* output) {
      output->resize(buffer_.length());
      std::copy(buffer_.begin(), buffer_.end(), output->begin());
      return ZX_OK;
    };

    vfs::BufferedPseudoFile::WriteHandler writeFn;
    if (write_allowed) {
      writeFn = [this](std::vector<uint8_t> input) {
        std::string str(input.size(), 0);
        std::copy(input.begin(), input.begin() + input.size(), str.begin());
        buffer_ = std::move(str);
      };
    }

    file_ = std::make_unique<vfs::BufferedPseudoFile>(
        std::move(readFn), std::move(writeFn), capacity);
    if (start_loop) {
      loop_.StartThread("vfs test thread");
    }
  }

  std::unique_ptr<vfs::BufferedPseudoFile> file_;
  std::string buffer_;
  async::Loop loop_;
};

class BufferedPseudoFileTest : public gtest::RealLoopFixture {
 protected:
  void AssertOpen(vfs::Node* node, async_dispatcher_t* dispatcher,
                  uint32_t flags, zx_status_t expected_status,
                  bool test_on_open_event = true) {
    fuchsia::io::NodePtr node_ptr;
    if (test_on_open_event) {
      flags |= fuchsia::io::OPEN_FLAG_DESCRIBE;
    }
    EXPECT_EQ(
        expected_status,
        node->Serve(flags, node_ptr.NewRequest().TakeChannel(), dispatcher));

    if (test_on_open_event) {
      bool on_open_called = false;
      node_ptr.events().OnOpen =
          [&](zx_status_t status, std::unique_ptr<fuchsia::io::NodeInfo> info) {
            EXPECT_FALSE(on_open_called);  // should be called only once
            on_open_called = true;
            EXPECT_EQ(expected_status, status);
            if (expected_status == ZX_OK) {
              ASSERT_NE(info.get(), nullptr);
              EXPECT_TRUE(info->is_file());
            } else {
              EXPECT_EQ(info.get(), nullptr);
            }
          };

      ASSERT_TRUE(RunLoopUntil([&]() { return on_open_called; }));
    }
  }

  fuchsia::io::FileSyncPtr OpenReadWrite(vfs::Node* node,
                                         async_dispatcher_t* dispatcher) {
    return OpenFile(
        node,
        fuchsia::io::OPEN_RIGHT_READABLE | fuchsia::io::OPEN_RIGHT_WRITABLE,
        dispatcher);
  }

  fuchsia::io::FileSyncPtr OpenRead(vfs::Node* node,
                                    async_dispatcher_t* dispatcher) {
    return OpenFile(node, fuchsia::io::OPEN_RIGHT_READABLE, dispatcher);
  }

  fuchsia::io::FileSyncPtr OpenFile(vfs::Node* node, uint32_t flags,
                                    async_dispatcher_t* dispatcher) {
    fuchsia::io::FileSyncPtr ptr;
    node->Serve(flags, ptr.NewRequest().TakeChannel(), dispatcher);
    return ptr;
  }

  void AssertWriteAt(fuchsia::io::FileSyncPtr& file, const std::string& str,
                     int offset, zx_status_t expected_status = ZX_OK,
                     int expected_actual = -1) {
    zx_status_t status;
    uint64_t actual;
    std::vector<uint8_t> buffer;
    buffer.resize(str.length());
    std::copy(str.begin(), str.end(), buffer.begin());
    file->WriteAt(buffer, offset, &status, &actual);
    ASSERT_EQ(expected_status, status);
    ASSERT_EQ(expected_actual == -1 ? str.length() : expected_actual, actual);
  }

  void AssertWrite(fuchsia::io::FileSyncPtr& file, const std::string& str,
                   zx_status_t expected_status = ZX_OK,
                   int expected_actual = -1) {
    zx_status_t status;
    uint64_t actual;
    std::vector<uint8_t> buffer;
    buffer.resize(str.length());
    std::copy(str.begin(), str.end(), buffer.begin());
    file->Write(buffer, &status, &actual);
    ASSERT_EQ(expected_status, status);
    ASSERT_EQ(expected_actual == -1 ? str.length() : expected_actual, actual);
  }

  void AssertReadAt(fuchsia::io::FileSyncPtr& file, int offset, int count,
                    const std::string& expected_str,
                    zx_status_t expected_status = ZX_OK) {
    zx_status_t status;
    std::vector<uint8_t> buffer;
    file->ReadAt(count, offset, &status, &buffer);
    ASSERT_EQ(expected_status, status);
    std::string str(buffer.size(), 0);
    std::copy(buffer.begin(), buffer.end(), str.begin());
    ASSERT_EQ(expected_str, str);
  }

  void AssertRead(fuchsia::io::FileSyncPtr& file, int count,
                  const std::string& expected_str,
                  zx_status_t expected_status = ZX_OK) {
    zx_status_t status;
    std::vector<uint8_t> buffer;
    file->Read(count, &status, &buffer);
    ASSERT_EQ(expected_status, status);
    std::string str(buffer.size(), 0);
    std::copy(buffer.begin(), buffer.end(), str.begin());
    ASSERT_EQ(expected_str, str);
  }

  void AssertTruncate(fuchsia::io::FileSyncPtr& file, int count,
                      zx_status_t expected_status = ZX_OK) {
    zx_status_t status;
    file->Truncate(count, &status);
    ASSERT_EQ(expected_status, status);
  }

  void AssertSeek(fuchsia::io::FileSyncPtr& file, int64_t offest,
                  fuchsia::io::SeekOrigin seek, uint64_t expected_offset,
                  zx_status_t expected_status = ZX_OK) {
    zx_status_t status;
    uint64_t new_offset;
    file->Seek(offest, seek, &status, &new_offset);
    ASSERT_EQ(expected_status, status);
    ASSERT_EQ(expected_offset, new_offset);
  }

  void CloseFile(fuchsia::io::FileSyncPtr& file,
                 zx_status_t expected_status = ZX_OK) {
    zx_status_t status = 1;
    file->Close(&status);
    EXPECT_EQ(expected_status, status);
  }

  void AssertFileWrapperState(FileWrapper& file_wrapper,
                              const std::string& expected_str) {
    ASSERT_TRUE(RunLoopUntil([&]() {
      return file_wrapper.buffer() == expected_str;
    })) << file_wrapper.buffer();
  }

  int OpenAsFD(vfs::Node* node, async_dispatcher_t* dispatcher) {
    zx::channel local, remote;
    EXPECT_EQ(ZX_OK, zx::channel::create(0, &local, &remote));
    EXPECT_EQ(ZX_OK, node->Serve(fuchsia::io::OPEN_RIGHT_READABLE |
                                     fuchsia::io::OPEN_RIGHT_WRITABLE,
                                 std::move(remote), dispatcher));
    int fd = -1;
    EXPECT_EQ(ZX_OK, fdio_fd_create(local.release(), &fd));
    return fd;
  }
};

TEST_F(BufferedPseudoFileTest, ServeOnInValidFlagsForReadWriteFile) {
  auto file_wrapper = FileWrapper::CreateReadWriteFile("test_str", 100, false);
  {
    SCOPED_TRACE("OPEN_FLAG_DIRECTORY");
    AssertOpen(file_wrapper.file(), dispatcher(),
               fuchsia::io::OPEN_FLAG_DIRECTORY, ZX_ERR_NOT_DIR);
  }
  uint32_t not_allowed_flags[] = {fuchsia::io::OPEN_RIGHT_ADMIN,
                                  fuchsia::io::OPEN_FLAG_CREATE,
                                  fuchsia::io::OPEN_FLAG_CREATE_IF_ABSENT,
                                  fuchsia::io::OPEN_FLAG_NO_REMOTE};
  for (auto not_allowed_flag : not_allowed_flags) {
    SCOPED_TRACE(std::to_string(not_allowed_flag));
    AssertOpen(file_wrapper.file(), dispatcher(), not_allowed_flag,
               ZX_ERR_NOT_SUPPORTED);
  }

  {
    SCOPED_TRACE("OPEN_FLAG_APPEND");
    AssertOpen(file_wrapper.file(), dispatcher(), fuchsia::io::OPEN_FLAG_APPEND,
               ZX_ERR_INVALID_ARGS);
  }
}

TEST_F(BufferedPseudoFileTest, ServeOnInValidFlagsForReadOnlyFile) {
  auto file_wrapper = FileWrapper::CreateReadOnlyFile("test_str");
  {
    SCOPED_TRACE("OPEN_FLAG_DIRECTORY");
    AssertOpen(file_wrapper.file(), dispatcher(),
               fuchsia::io::OPEN_FLAG_DIRECTORY, ZX_ERR_NOT_DIR);
  }
  uint32_t not_allowed_flags[] = {
      fuchsia::io::OPEN_RIGHT_ADMIN,           fuchsia::io::OPEN_FLAG_CREATE,
      fuchsia::io::OPEN_FLAG_CREATE_IF_ABSENT, fuchsia::io::OPEN_FLAG_NO_REMOTE,
      fuchsia::io::OPEN_RIGHT_WRITABLE,        fuchsia::io::OPEN_FLAG_TRUNCATE};
  for (auto not_allowed_flag : not_allowed_flags) {
    SCOPED_TRACE(std::to_string(not_allowed_flag));
    AssertOpen(file_wrapper.file(), dispatcher(), not_allowed_flag,
               ZX_ERR_NOT_SUPPORTED);
  }

  {
    SCOPED_TRACE("OPEN_FLAG_APPEND");
    AssertOpen(file_wrapper.file(), dispatcher(), fuchsia::io::OPEN_FLAG_APPEND,
               ZX_ERR_INVALID_ARGS);
  }
}

TEST_F(BufferedPseudoFileTest, ServeOnValidFlagsForReadWriteFile) {
  auto file_wrapper = FileWrapper::CreateReadWriteFile("test_str", 100, false);
  uint32_t allowed_flags[] = {
      fuchsia::io::OPEN_RIGHT_READABLE, fuchsia::io::OPEN_RIGHT_WRITABLE,
      fuchsia::io::OPEN_FLAG_NODE_REFERENCE, fuchsia::io::OPEN_FLAG_TRUNCATE};
  for (auto allowed_flag : allowed_flags) {
    SCOPED_TRACE(std::to_string(allowed_flag));
    AssertOpen(file_wrapper.file(), dispatcher(), allowed_flag, ZX_OK);
  }
}

TEST_F(BufferedPseudoFileTest, ServeOnValidFlagsForReadOnlyFile) {
  auto file_wrapper = FileWrapper::CreateReadOnlyFile("test_str", false);
  uint32_t allowed_flags[] = {fuchsia::io::OPEN_RIGHT_READABLE,
                              fuchsia::io::OPEN_FLAG_NODE_REFERENCE};
  for (auto allowed_flag : allowed_flags) {
    SCOPED_TRACE(std::to_string(allowed_flag));
    AssertOpen(file_wrapper.file(), dispatcher(), allowed_flag, ZX_OK);
  }
}

TEST_F(BufferedPseudoFileTest, Simple) {
  auto file_wrapper = FileWrapper::CreateReadWriteFile("test_str", 100);

  int fd = OpenAsFD(file_wrapper.file(), file_wrapper.dispatcher());
  ASSERT_LE(0, fd);

  char buffer[1024];
  memset(buffer, 0, sizeof(buffer));
  ASSERT_EQ(5, pread(fd, buffer, 5, 0));
  EXPECT_STREQ("test_", buffer);

  ASSERT_EQ(4, write(fd, "abcd", 4));
  ASSERT_EQ(5, pread(fd, buffer, 5, 0));
  EXPECT_STREQ("abcd_", buffer);

  ASSERT_GE(0, close(fd));
  file_wrapper.loop().RunUntilIdle();

  AssertFileWrapperState(file_wrapper, "abcd_str");
}

TEST_F(BufferedPseudoFileTest, WriteAt) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenReadWrite(file_wrapper.file(), file_wrapper.dispatcher());

  AssertWriteAt(file, "was", 5);

  const std::string updated_str = "this wasa test string";
  // confirm by reading
  AssertRead(file, str.length(), updated_str);

  // make sure file was not updated before conenction was closed.
  ASSERT_EQ(file_wrapper.buffer(), str);

  CloseFile(file);

  AssertFileWrapperState(file_wrapper, updated_str);
}

TEST_F(BufferedPseudoFileTest, MultipleWriteAt) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenReadWrite(file_wrapper.file(), file_wrapper.dispatcher());

  AssertWriteAt(file, "was", 5);

  AssertWriteAt(file, "tests", 10);

  const std::string updated_str = "this wasa testsstring";
  // confirm by reading
  AssertRead(file, str.length(), updated_str);

  // make sure file was not updated before conenction was closed.
  ASSERT_EQ(file_wrapper.buffer(), str);

  CloseFile(file);

  AssertFileWrapperState(file_wrapper, updated_str);
}

TEST_F(BufferedPseudoFileTest, ReadAt) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenReadWrite(file_wrapper.file(), file_wrapper.dispatcher());

  AssertReadAt(file, 5, 10, str.substr(5, 10));

  // try one more
  AssertReadAt(file, 15, 5, str.substr(15, 5));
}

TEST_F(BufferedPseudoFileTest, Read) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenReadWrite(file_wrapper.file(), file_wrapper.dispatcher());

  AssertRead(file, 10, str.substr(0, 10));

  // offset should have moved
  AssertRead(file, 10, str.substr(10, 10));
}

TEST_F(BufferedPseudoFileTest, Write) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenReadWrite(file_wrapper.file(), file_wrapper.dispatcher());

  AssertWrite(file, "It");

  // offset should have moved
  AssertWrite(file, " is");

  const std::string updated_str = "It isis a test string";

  AssertReadAt(file, 0, 100, updated_str);

  // make sure file was not updated before conenction was closed.
  ASSERT_EQ(file_wrapper.buffer(), str);

  CloseFile(file);

  // make sure file was updated
  AssertFileWrapperState(file_wrapper, updated_str);
}

TEST_F(BufferedPseudoFileTest, Truncate) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenReadWrite(file_wrapper.file(), file_wrapper.dispatcher());

  AssertTruncate(file, 10);

  AssertRead(file, 100, str.substr(0, 10));

  // make sure file was not updated before conenction was closed.
  ASSERT_EQ(file_wrapper.buffer(), str);

  CloseFile(file);

  // make sure file was updated
  AssertFileWrapperState(file_wrapper, str.substr(0, 10));
}

TEST_F(BufferedPseudoFileTest, SeekFromStart) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadOnlyFile(str);
  auto file = OpenRead(file_wrapper.file(), file_wrapper.dispatcher());

  AssertSeek(file, 5, fuchsia::io::SeekOrigin::START, 5);

  AssertRead(file, 100, str.substr(5));
}

TEST_F(BufferedPseudoFileTest, SeekFromCurent) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadOnlyFile(str);
  auto file = OpenRead(file_wrapper.file(), file_wrapper.dispatcher());

  AssertSeek(file, 5, fuchsia::io::SeekOrigin::START, 5);

  AssertSeek(file, 10, fuchsia::io::SeekOrigin::CURRENT, 15);

  AssertRead(file, 100, str.substr(15));
}

TEST_F(BufferedPseudoFileTest, SeekFromEnd) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadOnlyFile(str);
  auto file = OpenRead(file_wrapper.file(), file_wrapper.dispatcher());

  AssertSeek(file, -2, fuchsia::io::SeekOrigin::END, str.length() - 2);

  AssertRead(file, 100, str.substr(str.length() - 2));
}

TEST_F(BufferedPseudoFileTest, SeekFromEndWith0Offset) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadOnlyFile(str);
  auto file = OpenRead(file_wrapper.file(), file_wrapper.dispatcher());

  AssertSeek(file, 0, fuchsia::io::SeekOrigin::END, str.length());

  AssertRead(file, 100, "");
}

TEST_F(BufferedPseudoFileTest, SeekFailsIfOffsetMoreThanCapacity) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadOnlyFile(str);
  auto file = OpenRead(file_wrapper.file(), file_wrapper.dispatcher());

  AssertSeek(file, 1, fuchsia::io::SeekOrigin::END, 0, ZX_ERR_OUT_OF_RANGE);

  // make sure offset didnot change
  AssertRead(file, 100, str);
}

TEST_F(BufferedPseudoFileTest, WriteafterEndOfFile) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenReadWrite(file_wrapper.file(), file_wrapper.dispatcher());

  AssertSeek(file, 5, fuchsia::io::SeekOrigin::END, str.length() + 5);

  AssertWrite(file, "is");

  auto updated_str = str;
  updated_str.append(5, 0).append("is");

  AssertReadAt(file, 0, 100, updated_str);

  // make sure file was not updated before conenction was closed.
  ASSERT_EQ(file_wrapper.buffer(), str);

  CloseFile(file);

  // make sure file was updated
  AssertFileWrapperState(file_wrapper, updated_str);
}

TEST_F(BufferedPseudoFileTest, WriteFailsForReadOnly) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenRead(file_wrapper.file(), file_wrapper.dispatcher());

  AssertWrite(file, "is", ZX_ERR_ACCESS_DENIED, 0);

  CloseFile(file);

  // make sure file was not updated
  AssertFileWrapperState(file_wrapper, str);
}

TEST_F(BufferedPseudoFileTest, WriteAtFailsForReadOnly) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenRead(file_wrapper.file(), file_wrapper.dispatcher());

  AssertWriteAt(file, "is", 0, ZX_ERR_ACCESS_DENIED, 0);

  CloseFile(file);

  // make sure file was not updated
  AssertFileWrapperState(file_wrapper, str);
}

TEST_F(BufferedPseudoFileTest, TruncateFailsForReadOnly) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenRead(file_wrapper.file(), file_wrapper.dispatcher());

  AssertTruncate(file, 10, ZX_ERR_ACCESS_DENIED);

  CloseFile(file);

  // make sure file was not updated
  AssertFileWrapperState(file_wrapper, str);
}

TEST_F(BufferedPseudoFileTest, ReadAtFailsForWriteOnly) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenFile(file_wrapper.file(), fuchsia::io::OPEN_RIGHT_WRITABLE,
                       file_wrapper.dispatcher());

  AssertReadAt(file, 0, 10, "", ZX_ERR_ACCESS_DENIED);
}

TEST_F(BufferedPseudoFileTest, ReadFailsForWriteOnly) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenFile(file_wrapper.file(), fuchsia::io::OPEN_RIGHT_WRITABLE,
                       file_wrapper.dispatcher());

  AssertRead(file, 10, "", ZX_ERR_ACCESS_DENIED);
}

TEST_F(BufferedPseudoFileTest, CantReadNodeReferenceFile) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file =
      OpenFile(file_wrapper.file(), fuchsia::io::OPEN_FLAG_NODE_REFERENCE,
               file_wrapper.dispatcher());
  // make sure node reference was opened
  zx_status_t status;
  fuchsia::io::NodeAttributes attr;
  ASSERT_EQ(ZX_OK, file->GetAttr(&status, &attr));
  ASSERT_EQ(ZX_OK, status);
  ASSERT_NE(0u, attr.mode | fuchsia::io::MODE_TYPE_FILE);

  std::vector<uint8_t> buffer;
  ASSERT_EQ(ZX_ERR_PEER_CLOSED, file->Read(100, &status, &buffer));
}

TEST_F(BufferedPseudoFileTest, CanCloneFileConnectionAndReadAndWrite) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file = OpenReadWrite(file_wrapper.file(), file_wrapper.dispatcher());

  fuchsia::io::FileSyncPtr cloned_file;
  file->Clone(0, fidl::InterfaceRequest<fuchsia::io::Node>(
                     cloned_file.NewRequest().TakeChannel()));

  CloseFile(file);

  AssertWrite(cloned_file, "It");

  const std::string updated_str = "Itis is a test string";

  AssertReadAt(cloned_file, 0, 100, updated_str);

  // make sure file was not updated before conenction was closed.
  ASSERT_EQ(file_wrapper.buffer(), str);

  CloseFile(cloned_file);

  // make sure file was updated
  AssertFileWrapperState(file_wrapper, updated_str);
}

TEST_F(BufferedPseudoFileTest, NodeReferenceIsClonedAsNodeReference) {
  const std::string str = "this is a test string";
  auto file_wrapper = FileWrapper::CreateReadWriteFile(str, 100);
  auto file =
      OpenFile(file_wrapper.file(), fuchsia::io::OPEN_FLAG_NODE_REFERENCE,
               file_wrapper.dispatcher());

  fuchsia::io::FileSyncPtr cloned_file;
  file->Clone(0, fidl::InterfaceRequest<fuchsia::io::Node>(
                     cloned_file.NewRequest().TakeChannel()));

  CloseFile(file);

  // make sure node reference was opened
  zx_status_t status;
  fuchsia::io::NodeAttributes attr;
  ASSERT_EQ(ZX_OK, cloned_file->GetAttr(&status, &attr));
  ASSERT_EQ(ZX_OK, status);
  ASSERT_NE(0u, attr.mode | fuchsia::io::MODE_TYPE_FILE);

  std::vector<uint8_t> buffer;
  ASSERT_EQ(ZX_ERR_PEER_CLOSED, cloned_file->Read(100, &status, &buffer));
}

}  // namespace

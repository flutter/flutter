// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/async-loop/cpp/loop.h>
#include <lib/fdio/directory.h>
#include <lib/fdio/fd.h>
#include <lib/fdio/fdio.h>
#include <lib/fdio/limits.h>
#include <unistd.h>
#include <zircon/processargs.h>

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

#include "gtest/gtest.h"
#include "lib/vfs/cpp/vmo_file.h"

namespace {

void FillBuffer(char* buf, size_t size) {
  for (size_t i = 0; i < size; i++) {
    buf[i] = i % 256;
  }
}

zx::vmo MakeTestVmo() {
  zx::vmo ret;
  EXPECT_EQ(ZX_OK, zx::vmo::create(4096, 0, &ret));

  char buf[4096];
  FillBuffer(buf, 4096);
  EXPECT_EQ(ZX_OK, ret.write(buf, 0, 4096));
  return ret;
}

fuchsia::io::FileSyncPtr OpenAsFile(vfs::Node* node,
                                    async_dispatcher_t* dispatcher,
                                    bool writable = false) {
  zx::channel local, remote;
  EXPECT_EQ(ZX_OK, zx::channel::create(0, &local, &remote));
  EXPECT_EQ(ZX_OK,
            node->Serve(fuchsia::io::OPEN_RIGHT_READABLE |
                            (writable ? fuchsia::io::OPEN_RIGHT_WRITABLE : 0),
                        std::move(remote), dispatcher));
  fuchsia::io::FileSyncPtr ret;
  ret.Bind(std::move(local));
  return ret;
}

std::vector<uint8_t> ReadVmo(const zx::vmo& vmo, size_t offset, size_t length) {
  std::vector<uint8_t> ret;
  ret.resize(length);
  EXPECT_EQ(ZX_OK, vmo.read(ret.data(), offset, length));
  return ret;
}

TEST(VmoFile, ConstructTransferOwnership) {
  vfs::VmoFile file(MakeTestVmo(), 24, 1000);
  std::vector<uint8_t> output;
  EXPECT_EQ(ZX_OK, file.ReadAt(1000, 0, &output));
  EXPECT_EQ(1000u, output.size());
}

TEST(VmoFile, Reading) {
  // Create a VmoFile wrapping 1000 bytes starting at offset 24 of the vmo.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 24, 1000,
                    vfs::VmoFile::WriteOption::READ_ONLY,
                    vfs::VmoFile::Sharing::NONE);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher());
  ASSERT_TRUE(file_ptr.is_bound());

  // Reading the VMO from offset 24 should match reading the file from offset 0.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 24, 1000);
  zx_status_t status;
  EXPECT_EQ(ZX_OK, file_ptr->Read(500, &status, &result));
  EXPECT_EQ(ZX_OK, status);
  EXPECT_EQ(ReadVmo(test_vmo, 24, 500), result);
  EXPECT_EQ(ZX_OK, file_ptr->Read(500, &status, &result));
  EXPECT_EQ(ZX_OK, status);
  EXPECT_EQ(ReadVmo(test_vmo, 524, 500), result);
}

TEST(VmoFile, GetAttrReadOnly) {
  // Create a VmoFile wrapping 1000 bytes starting at offset 24 of the vmo.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 24, 1000,
                    vfs::VmoFile::WriteOption::READ_ONLY,
                    vfs::VmoFile::Sharing::NONE);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher());
  ASSERT_TRUE(file_ptr.is_bound());

  fuchsia::io::NodeAttributes attr;
  zx_status_t status;
  EXPECT_EQ(ZX_OK, file_ptr->GetAttr(&status, &attr));
  EXPECT_EQ(ZX_OK, status);
  EXPECT_EQ(1000u, attr.content_size);
  EXPECT_EQ(1000u, attr.storage_size);
  EXPECT_EQ(fuchsia::io::MODE_TYPE_FILE | fuchsia::io::OPEN_RIGHT_READABLE,
            attr.mode);
}

TEST(VmoFile, GetAttrWritable) {
  // Create a VmoFile wrapping 1000 bytes starting at offset 24 of the vmo.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 24, 1000,
                    vfs::VmoFile::WriteOption::WRITABLE,
                    vfs::VmoFile::Sharing::NONE);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher());
  ASSERT_TRUE(file_ptr.is_bound());

  fuchsia::io::NodeAttributes attr;
  zx_status_t status;
  EXPECT_EQ(ZX_OK, file_ptr->GetAttr(&status, &attr));
  EXPECT_EQ(ZX_OK, status);
  EXPECT_EQ(1000u, attr.content_size);
  EXPECT_EQ(1000u, attr.storage_size);
  EXPECT_EQ(fuchsia::io::MODE_TYPE_FILE | fuchsia::io::OPEN_RIGHT_READABLE |
                fuchsia::io::OPEN_RIGHT_WRITABLE,
            attr.mode);
}

TEST(VmoFile, ReadOnlyNoSharing) {
  // Create a VmoFile wrapping 1000 bytes starting at offset 24 of the vmo.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 24, 1000,
                    vfs::VmoFile::WriteOption::READ_ONLY,
                    vfs::VmoFile::Sharing::NONE);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher());
  ASSERT_TRUE(file_ptr.is_bound());

  // Writes should fail, since the VMO is read-only.
  std::vector<uint8_t> value{'a', 'b', 'c', 'd'};
  zx_status_t status;
  size_t actual;
  EXPECT_EQ(ZX_OK, file_ptr->WriteAt(value, 0, &status, &actual));
  EXPECT_NE(ZX_OK, status);

  // Reading the VMO from offset 24 should match reading the file from offset 0.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 24, 1000);
  EXPECT_EQ(ZX_OK, file_ptr->ReadAt(1000, 0, &status, &result));
  EXPECT_EQ(vmo_result.size(), result.size());
  EXPECT_EQ(vmo_result, result);

  // The file should appear as a regular file, the fact that a VMO is backing it
  // is hidden.
  fuchsia::io::NodeInfo info;
  EXPECT_EQ(ZX_OK, file_ptr->Describe(&info));
  ASSERT_TRUE(info.is_file());
}

TEST(VmoFile, WritableNoSharing) {
  // Create a VmoFile wrapping 1000 bytes starting at offset 24 of the vmo.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 24, 1000,
                    vfs::VmoFile::WriteOption::WRITABLE,
                    vfs::VmoFile::Sharing::NONE);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher(), /*writable=*/true);
  ASSERT_TRUE(file_ptr.is_bound());

  // Writes should succeed.
  std::vector<uint8_t> value{'a', 'b', 'c', 'd'};
  zx_status_t status;
  size_t actual;
  EXPECT_EQ(ZX_OK, file_ptr->WriteAt(value, 0, &status, &actual));
  EXPECT_EQ(ZX_OK, status);
  EXPECT_EQ(4u, actual);

  // Reading the VMO from offset 24 should match reading the file from offset 0.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 24, 1000);
  EXPECT_EQ(ZX_OK, file_ptr->ReadAt(1000, 0, &status, &result));
  EXPECT_EQ(vmo_result.size(), result.size());
  EXPECT_EQ(vmo_result, result);
  EXPECT_EQ('a', result[0]);

  // The file should appear as a regular file, the fact that a VMO is backing it
  // is hidden.
  fuchsia::io::NodeInfo info;
  EXPECT_EQ(ZX_OK, file_ptr->Describe(&info));
  ASSERT_TRUE(info.is_file());
}

TEST(VmoFile, ReadOnlyDuplicate) {
  // Create a VmoFile wrapping 1000 bytes starting at offset 24 of the vmo.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 24, 1000);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher());
  ASSERT_TRUE(file_ptr.is_bound());

  // Writes should fail, since the VMO is read-only.
  std::vector<uint8_t> value{'a', 'b', 'c', 'd'};
  zx_status_t status;
  size_t actual;
  EXPECT_EQ(ZX_OK, file_ptr->WriteAt(value, 0, &status, &actual));
  EXPECT_NE(ZX_OK, status);

  // Reading the VMO from offset 24 should match reading the file from offset 0.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 24, 1000);
  EXPECT_EQ(ZX_OK, file_ptr->ReadAt(1000, 0, &status, &result));
  EXPECT_EQ(vmo_result.size(), result.size());
  EXPECT_EQ(vmo_result, result);

  // Describing the VMO duplicates the handle, and we can access the entire VMO.
  fuchsia::io::NodeInfo info;
  EXPECT_EQ(ZX_OK, file_ptr->Describe(&info));
  ASSERT_TRUE(info.is_vmofile());
  ASSERT_EQ(1000u, info.vmofile().length);
  ASSERT_EQ(24u, info.vmofile().offset);
  EXPECT_EQ(ReadVmo(test_vmo, 0, 4096), ReadVmo(info.vmofile().vmo, 0, 4096));

  // Writing should fail on the new VMO.
  EXPECT_NE(ZX_OK, info.vmofile().vmo.write("test", 0, 4));
}

TEST(VmoFile, WritableDuplicate) {
  // Create a VmoFile wrapping 1000 bytes starting at offset 24 of the vmo.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 24, 1000,
                    vfs::VmoFile::WriteOption::WRITABLE);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher(), /*writable=*/true);
  ASSERT_TRUE(file_ptr.is_bound());

  // Writes should succeed.
  std::vector<uint8_t> value{'a', 'b', 'c', 'd'};
  zx_status_t status;
  size_t actual;
  EXPECT_EQ(ZX_OK, file_ptr->WriteAt(value, 0, &status, &actual));
  EXPECT_EQ(ZX_OK, status);
  EXPECT_EQ(4u, actual);

  // Reading the VMO from offset 24 should match reading the file from offset 0.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 24, 1000);
  EXPECT_EQ(ZX_OK, file_ptr->ReadAt(1000, 0, &status, &result));
  EXPECT_EQ(vmo_result.size(), result.size());
  EXPECT_EQ(vmo_result, result);
  EXPECT_EQ('a', result[0]);

  // Describing the VMO duplicates the handle, and we can access the entire VMO.
  fuchsia::io::NodeInfo info;
  EXPECT_EQ(ZX_OK, file_ptr->Describe(&info));
  ASSERT_TRUE(info.is_vmofile());
  ASSERT_EQ(1000u, info.vmofile().length);
  ASSERT_EQ(24u, info.vmofile().offset);
  EXPECT_EQ(ReadVmo(test_vmo, 0, 4096), ReadVmo(info.vmofile().vmo, 0, 4096));

  // Writing should succeed on the new VMO.
  EXPECT_EQ(ZX_OK, info.vmofile().vmo.write("test", 0, 4));
  EXPECT_EQ(ReadVmo(test_vmo, 0, 4096), ReadVmo(info.vmofile().vmo, 0, 4096));
}

TEST(VmoFile, ReadOnlyCopyOnWrite) {
  // Create a VmoFile wrapping the VMO.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 0, 4096,
                    vfs::VmoFile::WriteOption::READ_ONLY,
                    vfs::VmoFile::Sharing::CLONE_COW);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher());
  ASSERT_TRUE(file_ptr.is_bound());

  // Writes should fail, since the VMO is read-only.
  std::vector<uint8_t> value{'a', 'b', 'c', 'd'};
  zx_status_t status;
  size_t actual;
  EXPECT_EQ(ZX_OK, file_ptr->WriteAt(value, 0, &status, &actual));
  EXPECT_NE(ZX_OK, status);

  // Reading the VMO shuld match reading the file.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 0, 4096);
  EXPECT_EQ(ZX_OK, file_ptr->ReadAt(4096, 0, &status, &result));
  EXPECT_EQ(vmo_result.size(), result.size());
  EXPECT_EQ(vmo_result, result);

  // Describing the VMO clones the handle, and we can access the entire VMO.
  fuchsia::io::NodeInfo info;
  EXPECT_EQ(ZX_OK, file_ptr->Describe(&info));
  ASSERT_TRUE(info.is_vmofile());
  ASSERT_EQ(4096u, info.vmofile().length);
  ASSERT_EQ(0u, info.vmofile().offset);
  EXPECT_EQ(ReadVmo(test_vmo, 0, 4096), ReadVmo(info.vmofile().vmo, 0, 4096));

  // Writing should succeed on the new VMO, due to copy on write.
  EXPECT_EQ(ZX_OK, info.vmofile().vmo.write("test", 0, 4));
  EXPECT_NE(ReadVmo(test_vmo, 0, 4096), ReadVmo(info.vmofile().vmo, 0, 4096));
}

TEST(VmoFile, WritableCopyOnWrite) {
  // Create a VmoFile wrapping the VMO.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 0, 4096,
                    vfs::VmoFile::WriteOption::WRITABLE,
                    vfs::VmoFile::Sharing::CLONE_COW);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher(), /*writable=*/true);
  ASSERT_TRUE(file_ptr.is_bound());

  // Writes should succeed.
  std::vector<uint8_t> value{'a', 'b', 'c', 'd'};
  zx_status_t status;
  size_t actual;
  EXPECT_EQ(ZX_OK, file_ptr->WriteAt(value, 0, &status, &actual));
  EXPECT_EQ(ZX_OK, status);
  EXPECT_EQ(4u, actual);

  // Reading the VMO should match reading the file.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 0, 4096);
  EXPECT_EQ(ZX_OK, file_ptr->ReadAt(4096, 0, &status, &result));
  EXPECT_EQ(vmo_result.size(), result.size());
  EXPECT_EQ(vmo_result, result);
  EXPECT_EQ('a', result[0]);

  // Describing the VMO duplicates the handle, and we can access the entire VMO.
  fuchsia::io::NodeInfo info;
  EXPECT_EQ(ZX_OK, file_ptr->Describe(&info));
  ASSERT_TRUE(info.is_vmofile());
  ASSERT_EQ(4096u, info.vmofile().length);
  ASSERT_EQ(0u, info.vmofile().offset);
  EXPECT_EQ(ReadVmo(test_vmo, 0, 4096), ReadVmo(info.vmofile().vmo, 0, 4096));

  // Writing should succeed on the new VMO, due to copy on write.
  EXPECT_EQ(ZX_OK, info.vmofile().vmo.write("test", 0, 4));
  EXPECT_NE(ReadVmo(test_vmo, 0, 4096), ReadVmo(info.vmofile().vmo, 0, 4096));
}

TEST(VmoFile, VmoWithNoRights) {
  // Create a VmoFile wrapping 1000 bytes of the VMO starting at offset 24.
  // The vmo we use has no rights, so reading, writing, and duplication will
  // fail.
  zx::vmo test_vmo = MakeTestVmo();
  zx::vmo bad_vmo;
  ASSERT_EQ(ZX_OK, test_vmo.duplicate(0, &bad_vmo));
  vfs::VmoFile file(std::move(bad_vmo), 24, 1000,
                    vfs::VmoFile::WriteOption::WRITABLE);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher(), /*writable=*/true);
  ASSERT_TRUE(file_ptr.is_bound());

  // Writes should fail.
  std::vector<uint8_t> value{'a', 'b', 'c', 'd'};
  zx_status_t status;
  size_t actual;
  EXPECT_EQ(ZX_OK, file_ptr->WriteAt(value, 0, &status, &actual));
  EXPECT_NE(ZX_OK, status);

  // Reading should fail.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 24, 1000);
  EXPECT_EQ(ZX_OK, file_ptr->ReadAt(1000, 0, &status, &result));
  EXPECT_NE(ZX_OK, status);

  // Describing the VMO should close the connection.
  fuchsia::io::NodeInfo info;
  EXPECT_EQ(ZX_ERR_PEER_CLOSED, file_ptr->Describe(&info));
}

TEST(VmoFile, UnalignedCopyOnWrite) {
  // Create a VmoFile wrapping 1000 bytes of the VMO starting at offset 24.
  // This offset is not page-aligned, so cloning will fail.
  zx::vmo test_vmo = MakeTestVmo();
  vfs::VmoFile file(zx::unowned_vmo(test_vmo), 24, 1000,
                    vfs::VmoFile::WriteOption::WRITABLE,
                    vfs::VmoFile::Sharing::CLONE_COW);

  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto file_ptr = OpenAsFile(&file, loop.dispatcher(), /*writable=*/true);
  ASSERT_TRUE(file_ptr.is_bound());

  // Writes should succeed.
  std::vector<uint8_t> value{'a', 'b', 'c', 'd'};
  zx_status_t status;
  size_t actual;
  EXPECT_EQ(ZX_OK, file_ptr->WriteAt(value, 0, &status, &actual));
  EXPECT_EQ(ZX_OK, status);
  EXPECT_EQ(4u, actual);

  // Reading the VMO from offset 24 should match reading the file from offset 0.
  std::vector<uint8_t> result;
  std::vector<uint8_t> vmo_result = ReadVmo(test_vmo, 24, 1000);
  EXPECT_EQ(ZX_OK, file_ptr->ReadAt(1000, 0, &status, &result));
  EXPECT_EQ(vmo_result.size(), result.size());
  EXPECT_EQ(vmo_result, result);
  EXPECT_EQ('a', result[0]);

  // Describing the VMO should close the connection.
  fuchsia::io::NodeInfo info;
  EXPECT_EQ(ZX_ERR_PEER_CLOSED, file_ptr->Describe(&info));
}

}  // namespace

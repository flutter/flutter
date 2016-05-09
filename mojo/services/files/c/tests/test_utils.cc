// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/tests/test_utils.h"

#include "files/interfaces/file.mojom-sync.h"
#include "files/interfaces/file.mojom.h"
#include "files/interfaces/types.mojom.h"
#include "mojo/public/cpp/bindings/synchronous_interface_ptr.h"
#include "mojo/public/cpp/environment/logging.h"

using mojo::InterfaceHandle;
using mojo::SynchronousInterfacePtr;

namespace mojio {
namespace test {

void MakeDirAt(SynchronousInterfacePtr<mojo::files::Directory>* root,
               const char* path) {
  MOJO_CHECK(root);
  MOJO_CHECK(path);
  auto& dir = *root;

  mojo::files::Error error = mojo::files::Error::INTERNAL;
  MOJO_CHECK(dir->OpenDirectory(path, nullptr, mojo::files::kOpenFlagRead |
                                                   mojo::files::kOpenFlagWrite |
                                                   mojo::files::kOpenFlagCreate,
                                &error));
  MOJO_CHECK(error == mojo::files::Error::OK);
}

InterfaceHandle<mojo::files::File> OpenFileAt(
    SynchronousInterfacePtr<mojo::files::Directory>* root,
    const char* path,
    uint32_t open_flags) {
  MOJO_CHECK(root);
  MOJO_CHECK(path);
  auto& dir = *root;

  InterfaceHandle<mojo::files::File> file;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  MOJO_CHECK(dir->OpenFile(path, mojo::GetProxy(&file), open_flags, &error));
  if (error != mojo::files::Error::OK)
    return nullptr;

  return file;
}

void CreateTestFileAt(SynchronousInterfacePtr<mojo::files::Directory>* root,
                      const char* path,
                      size_t size) {
  auto file = SynchronousInterfacePtr<mojo::files::File>::Create(OpenFileAt(
      root, path, mojo::files::kOpenFlagWrite | mojo::files::kOpenFlagCreate |
                      mojo::files::kOpenFlagExclusive));
  MOJO_CHECK(file);

  if (!size)
    return;

  std::vector<uint8_t> bytes_to_write(size);
  for (size_t i = 0; i < size; i++)
    bytes_to_write[i] = static_cast<uint8_t>(i);
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  uint32_t num_bytes_written = 0;
  MOJO_CHECK(file->Write(mojo::Array<uint8_t>::From(bytes_to_write), 0,
                         mojo::files::Whence::FROM_CURRENT, &error,
                         &num_bytes_written));
  MOJO_CHECK(error == mojo::files::Error::OK);
  MOJO_CHECK(num_bytes_written == bytes_to_write.size());
}

int64_t GetFileSize(SynchronousInterfacePtr<mojo::files::Directory>* root,
                    const char* path) {
  auto file = SynchronousInterfacePtr<mojo::files::File>::Create(
      OpenFileAt(root, path, mojo::files::kOpenFlagRead));
  if (!file)
    return -1;

  // Seek to the end to get the file size (we could also stat).
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  int64_t position = -1;
  MOJO_CHECK(file->Seek(0, mojo::files::Whence::FROM_END, &error, &position));
  MOJO_CHECK(error == mojo::files::Error::OK);
  MOJO_CHECK(position >= 0);
  return position;
}

std::string GetFileContents(
    SynchronousInterfacePtr<mojo::files::Directory>* root,
    const char* path) {
  auto file = SynchronousInterfacePtr<mojo::files::File>::Create(
      OpenFileAt(root, path, mojo::files::kOpenFlagRead));
  MOJO_CHECK(file);

  mojo::Array<uint8_t> bytes_read;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  MOJO_CHECK(file->Read(1024 * 1024, 0, mojo::files::Whence::FROM_START, &error,
                        &bytes_read));
  if (!bytes_read.size())
    return std::string();
  return std::string(reinterpret_cast<const char*>(&bytes_read[0]),
                     bytes_read.size());
}

}  // namespace test
}  // namespace mojio

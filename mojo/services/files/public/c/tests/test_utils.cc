// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/tests/test_utils.h"

#include "files/public/c/lib/template_util.h"
#include "files/public/interfaces/file.mojom.h"
#include "files/public/interfaces/types.mojom.h"
#include "mojo/public/cpp/environment/logging.h"

namespace mojio {
namespace test {

void MakeDirAt(mojo::files::DirectoryPtr* root, const char* path) {
  MOJO_CHECK(root);
  MOJO_CHECK(path);
  mojo::files::DirectoryPtr& dir = *root;

  mojo::files::Error error = mojo::files::ERROR_INTERNAL;
  dir->OpenDirectory(path, nullptr,
                     mojo::files::kOpenFlagRead | mojo::files::kOpenFlagWrite |
                         mojo::files::kOpenFlagCreate,
                     Capture(&error));
  MOJO_CHECK(dir.WaitForIncomingResponse());
  MOJO_CHECK(error == mojo::files::ERROR_OK);
}

mojo::files::FilePtr OpenFileAt(mojo::files::DirectoryPtr* root,
                                const char* path,
                                uint32_t open_flags) {
  MOJO_CHECK(root);
  MOJO_CHECK(path);
  mojo::files::DirectoryPtr& dir = *root;

  mojo::files::FilePtr file;
  mojo::files::Error error = mojo::files::ERROR_INTERNAL;
  dir->OpenFile(path, mojo::GetProxy(&file), open_flags, Capture(&error));
  MOJO_CHECK(dir.WaitForIncomingResponse());
  if (error != mojo::files::ERROR_OK)
    return nullptr;

  return file.Pass();
}

void CreateTestFileAt(mojo::files::DirectoryPtr* root,
                      const char* path,
                      size_t size) {
  mojo::files::FilePtr file = OpenFileAt(
      root, path, mojo::files::kOpenFlagWrite | mojo::files::kOpenFlagCreate |
                      mojo::files::kOpenFlagExclusive);
  MOJO_CHECK(file);

  if (!size)
    return;

  std::vector<uint8_t> bytes_to_write(size);
  for (size_t i = 0; i < size; i++)
    bytes_to_write[i] = static_cast<uint8_t>(i);
  mojo::files::Error error = mojo::files::ERROR_INTERNAL;
  uint32_t num_bytes_written = 0;
  file->Write(mojo::Array<uint8_t>::From(bytes_to_write), 0,
              mojo::files::WHENCE_FROM_CURRENT,
              Capture(&error, &num_bytes_written));
  MOJO_CHECK(file.WaitForIncomingResponse());
  MOJO_CHECK(error == mojo::files::ERROR_OK);
  MOJO_CHECK(num_bytes_written == bytes_to_write.size());
}

int64_t GetFileSize(mojo::files::DirectoryPtr* root, const char* path) {
  mojo::files::FilePtr file =
      OpenFileAt(root, path, mojo::files::kOpenFlagRead);
  if (!file)
    return -1;

  // Seek to the end to get the file size (we could also stat).
  mojo::files::Error error = mojo::files::ERROR_INTERNAL;
  int64_t position = -1;
  file->Seek(0, mojo::files::WHENCE_FROM_END, Capture(&error, &position));
  MOJO_CHECK(file.WaitForIncomingResponse());
  MOJO_CHECK(error == mojo::files::ERROR_OK);
  MOJO_CHECK(position >= 0);
  return position;
}

std::string GetFileContents(mojo::files::DirectoryPtr* root, const char* path) {
  mojo::files::FilePtr file =
      OpenFileAt(root, path, mojo::files::kOpenFlagRead);
  MOJO_CHECK(file);

  mojo::Array<uint8_t> bytes_read;
  mojo::files::Error error = mojo::files::ERROR_INTERNAL;
  file->Read(1024 * 1024, 0, mojo::files::WHENCE_FROM_START,
             Capture(&error, &bytes_read));
  MOJO_CHECK(file.WaitForIncomingResponse());
  if (!bytes_read.size())
    return std::string();
  return std::string(reinterpret_cast<const char*>(&bytes_read[0]),
                     bytes_read.size());
}

}  // namespace test
}  // namespace mojio

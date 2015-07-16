// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_TESTS_TEST_UTILS_H_
#define SERVICES_FILES_C_TESTS_TEST_UTILS_H_

#include <stddef.h>
#include <stdint.h>

#include <string>

#include "files/public/interfaces/directory.mojom.h"
#include "files/public/interfaces/file.mojom.h"

namespace mojio {
namespace test {

// Makes a directory at the given path under the given root directory.
// (Check-fails on any failure.)
void MakeDirAt(mojo::files::DirectoryPtr* root, const char* path);

// Opens a file at the given path under the given root directory using the given
// flags (|mojo::files::kOpenFlag...|). Returns a null |FilePtr| on failure
// (e.g., if the file doesn't exist and |open_flags| doesn't indicate that it
// should be created).
mojo::files::FilePtr OpenFileAt(mojo::files::DirectoryPtr* root,
                                const char* path,
                                uint32_t open_flags);

// Creates a test file at the given path under the given root directory; the
// file will be of the given size, with the i-th byte being i mod 256.
// (Check-fails on any failure.)
void CreateTestFileAt(mojo::files::DirectoryPtr* root,
                      const char* path,
                      size_t size);

// Gets the size of the file at the given path under the given root directory.
// Returns -1 if the file doesn't exist (or can't be opened for some reason), so
// this may be used to check for a file's existence.
int64_t GetFileSize(mojo::files::DirectoryPtr* root, const char* path);

// Gets the contents of the file (up to 1 MiB) at the given path under the given
// root directory. (Check-fails on any failure.)
std::string GetFileContents(mojo::files::DirectoryPtr* root, const char* path);

}  // namespace test
}  // namespace mojio

#endif  // SERVICES_FILES_C_TESTS_TEST_UTILS_H_

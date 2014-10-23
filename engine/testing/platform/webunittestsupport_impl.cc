// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/testing/platform/webunittestsupport_impl.h"

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/path_service.h"
#include "base/strings/utf_string_conversions.h"

namespace sky {

blink::WebString WebUnitTestSupportImpl::webKitRootDir() {
  base::FilePath path;
  PathService::Get(base::DIR_SOURCE_ROOT, &path);
  path = path.Append(FILE_PATH_LITERAL("sky"));
  path = base::MakeAbsoluteFilePath(path);
  CHECK(!path.empty());
  std::string path_ascii = path.MaybeAsASCII();
  CHECK(!path_ascii.empty());
  return blink::WebString::fromUTF8(path_ascii.c_str());
}

blink::WebData WebUnitTestSupportImpl::readFromFile(
    const blink::WebString& path) {
  base::FilePath file_path = base::FilePath::FromUTF16Unsafe(path);

  std::string buffer;
  base::ReadFileToString(file_path, &buffer);

  return blink::WebData(buffer.data(), buffer.size());
}

}  // namespace sky

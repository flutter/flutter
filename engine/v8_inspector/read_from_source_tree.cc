// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/path_service.h"
#include "sky/engine/config.h"
#include "sky/engine/v8_inspector/read_from_source_tree.h"

namespace inspector {

// TODO(eseidel): This is a horrible hack and only works when run
// inside its source tree!  crbug.com/434513
void ReadFileFromSourceTree(const char* name, std::string* buffer) {
  CHECK(buffer);
  base::FilePath root_dir;
  PathService::Get(base::DIR_SOURCE_ROOT, &root_dir);
  base::FilePath path = root_dir.AppendASCII("sky");
  path = path.AppendASCII("engine").AppendASCII("v8_inspector");

  if (std::string("InjectedScriptSource.js") == name)
    path = path.AppendASCII(name);
  else if (std::string("DebuggerScript.js") == name)
    path = path.AppendASCII(name);
  else
    CHECK(false);

  base::ReadFileToString(path, buffer);
  CHECK(!buffer->empty());
}

}  // namespace inspector

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>

#include "base/files/file.h"
#include "base/files/file_path.h"
#include "base/logging.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "nacl_bindings/monacl_sel_main.h"
#include "native_client/src/public/nacl_desc.h"

NaClDesc* OpenFile(const char* filename) {
  base::FilePath path(filename);
  base::File file(path, base::File::FLAG_OPEN | base::File::FLAG_READ);
  if (!file.IsValid()) {
    perror(filename);
    exit(1);
  }
  return NaClDescCreateWithFilePathMetadata(file.TakePlatformFile(), "");
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    std::cout << "Usage: " << argv[0] << " irt.nexe app.nexe [args for app]" <<
        std::endl;
    return 1;
  }

  const char* irt_file = argv[1];
  const char* nexe_file = argv[2];

  NaClDesc* irt_desc = OpenFile(irt_file);
  NaClDesc* nexe_desc = OpenFile(nexe_file);

  mojo::embedder::Init(scoped_ptr<mojo::embedder::PlatformSupport>(
      new mojo::embedder::SimplePlatformSupport()));

  int exit_code = mojo::LaunchNaCl(nexe_desc, irt_desc, argc - 2, argv + 2,
                                   MOJO_HANDLE_INVALID);

  // Exits the process cleanly, does not return.
  mojo::NaClExit(exit_code);
  NOTREACHED();
  return 1;
}

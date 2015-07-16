// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdio>

#include "base/at_exit.h"
#include "base/command_line.h"
#include "base/message_loop/message_loop.h"

#include "third_party/khronos_glcts/framework/common/tcuApp.hpp"
#include "third_party/khronos_glcts/framework/common/tcuCommandLine.hpp"
#include "third_party/khronos_glcts/framework/common/tcuDefs.hpp"
#include "third_party/khronos_glcts/framework/common/tcuPlatform.hpp"
#include "third_party/khronos_glcts/framework/common/tcuResource.hpp"
#include "third_party/khronos_glcts/framework/common/tcuTestLog.hpp"
#include "third_party/khronos_glcts/framework/delibs/decpp/deUniquePtr.hpp"

// implemented in the native platform
tcu::Platform* createPlatform ();

void GTFMain(int argc, char* argv[]) {
  setvbuf(stdout, DE_NULL, _IOLBF, 4*1024);

  try {
    tcu::CommandLine cmdLine(argc, argv);
    tcu::DirArchive archive(cmdLine.getArchiveDir());
    tcu::TestLog log(cmdLine.getLogFileName(), cmdLine.getLogFlags());
    de::UniquePtr<tcu::Platform> platform(createPlatform());
    de::UniquePtr<tcu::App> app(
      new tcu::App(*platform, archive, log, cmdLine));

    // Main loop.
    for (;;) {
      if (!app->iterate())
        break;
    }
  }
  catch (const std::exception& e) {
    tcu::die("%s", e.what());
  }
}

int main(int argc, char *argv[]) {
  base::AtExitManager at_exit;
  base::CommandLine::Init(argc, argv);
  base::MessageLoopForUI message_loop;

  GTFMain(argc, argv);

  return 0;
}

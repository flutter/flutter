// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/process/memory.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/tools/packager/loader.h"
#include "sky/tools/packager/logging.h"
#include "sky/tools/packager/scope.h"
#include "sky/tools/packager/switches.h"
#include "sky/tools/packager/vm.h"

void WriteSnapshot(base::FilePath path) {
  uint8_t* buffer;
  intptr_t size;
  CHECK(!LogIfError(Dart_CreateScriptSnapshot(&buffer, &size)));

  CHECK_EQ(base::WriteFile(path, reinterpret_cast<const char*>(buffer), size),
           size);

  std::cout << "Successfully wrote snapshot to " << path.LossyDisplayName()
            << " (" << size << " bytes)." << std::endl;
}

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::EnableTerminationOnHeapCorruption();
  base::CommandLine::Init(argc, argv);

  InitDartVM();
  Dart_Isolate isolate = CreateDartIsolate();
  CHECK(isolate);

  const base::CommandLine& command_line =
      *base::CommandLine::ForCurrentProcess();

  DartIsolateScope scope(isolate);
  DartApiScope api_scope;

  auto args = command_line.GetArgs();
  CHECK(args.size() == 1);
  LoadScript(args[0]);

  CHECK(!LogIfError(Dart_FinalizeLoading(true)));

  CHECK(command_line.HasSwitch(kSnapshot)) << "Need --snapshot";
  WriteSnapshot(command_line.GetSwitchValuePath(kSnapshot));

  return 0;
}

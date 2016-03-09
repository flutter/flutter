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
#include "sky/tools/sky_snapshot/loader.h"
#include "sky/tools/sky_snapshot/logging.h"
#include "sky/tools/sky_snapshot/scope.h"
#include "sky/tools/sky_snapshot/switches.h"
#include "sky/tools/sky_snapshot/vm.h"

void Usage() {
  std::cerr << "Usage: sky_snapshot"
            << " --" << switches::kPackageRoot << " --" << switches::kSnapshot
            << " --" << switches::kDepfile << " --" << switches::kBuildOutput
            << " <lib/main.dart>" << std::endl;
}

void WriteSnapshot(base::FilePath path) {
  uint8_t* buffer;
  intptr_t size;
  CHECK(!LogIfError(Dart_CreateScriptSnapshot(&buffer, &size)));

  CHECK_EQ(base::WriteFile(path, reinterpret_cast<const char*>(buffer), size),
           size);
}

void WriteDependencies(base::FilePath path,
                       const std::string& build_output,
                       const std::set<std::string>& deps) {
  base::FilePath current_directory;
  CHECK(base::GetCurrentDirectory(&current_directory));
  std::string output = build_output + ":";
  for (const auto& i : deps) {
    output += " ";
    output += current_directory.Append(i).MaybeAsASCII();
  }
  const char* data = output.c_str();
  const intptr_t data_length = output.size();
  CHECK_EQ(base::WriteFile(path, data, data_length), data_length);
}

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::EnableTerminationOnHeapCorruption();
  base::CommandLine::Init(argc, argv);

  const base::CommandLine& command_line =
      *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(switches::kHelp) ||
      command_line.GetArgs().empty()) {
    Usage();
    return 0;
  }

  InitDartVM();
  Dart_Isolate isolate = CreateDartIsolate();
  CHECK(isolate);

  DartIsolateScope scope(isolate);
  DartApiScope api_scope;

  auto args = command_line.GetArgs();
  CHECK(args.size() == 1);
  LoadScript(args[0]);

  CHECK(!LogIfError(Dart_FinalizeLoading(true)));

  CHECK(command_line.HasSwitch(switches::kSnapshot)) << "Need --snapshot";
  WriteSnapshot(command_line.GetSwitchValuePath(switches::kSnapshot));

  if (command_line.HasSwitch(switches::kDepfile)) {
    auto build_output = command_line.HasSwitch(switches::kBuildOutput) ?
        command_line.GetSwitchValueASCII(switches::kBuildOutput) :
        command_line.GetSwitchValueASCII(switches::kSnapshot);
    WriteDependencies(command_line.GetSwitchValuePath(switches::kDepfile),
                      build_output,
                      GetDependencies());
  }

  return 0;
}

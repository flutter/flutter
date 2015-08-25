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
#include "mojo/dart/dart_snapshotter/vm.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "tonic/dart_error.h"
#include "tonic/dart_isolate_scope.h"
#include "tonic/dart_library_loader.h"
#include "tonic/dart_library_provider_files.h"
#include "tonic/dart_script_loader_sync.h"
#include "tonic/dart_state.h"

const char kHelp[] = "help";
const char kPackageRoot[] = "package-root";
const char kSnapshot[] = "snapshot";

const uint8_t magic_number[] = { 0xf5, 0xf5, 0xdc, 0xdc };

void Usage() {
  std::cerr << "Usage: dart_snapshotter"
            << " --" << kPackageRoot << " --" << kSnapshot
            << " <dart-app>" << std::endl;
}

void WriteSnapshot(base::FilePath path) {
  uint8_t* buffer;
  intptr_t size;
  CHECK(!tonic::LogIfError(Dart_CreateScriptSnapshot(&buffer, &size)));

  intptr_t magic_number_len = sizeof(magic_number);
  CHECK_EQ(base::WriteFile(
      path, reinterpret_cast<const char*>(magic_number), sizeof(magic_number)),
      magic_number_len);
  CHECK(base::AppendToFile(
      path, reinterpret_cast<const char*>(buffer), size));
}

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::EnableTerminationOnHeapCorruption();
  base::CommandLine::Init(argc, argv);

  const base::CommandLine& command_line =
      *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(kHelp) || command_line.GetArgs().empty()) {
    Usage();
    return 0;
  }

  // Initialize mojo.
  mojo::embedder::Init(
      make_scoped_ptr(new mojo::embedder::SimplePlatformSupport()));

  InitDartVM();

  CHECK(command_line.HasSwitch(kPackageRoot)) << "Need --package-root";
  CHECK(command_line.HasSwitch(kSnapshot)) << "Need --snapshot";
  auto args = command_line.GetArgs();
  CHECK(args.size() == 1);

  Dart_Isolate isolate = CreateDartIsolate();
  CHECK(isolate);

  tonic::DartIsolateScope scope(isolate);
  tonic::DartApiScope api_scope;

  auto isolate_data = SnapshotterDartState::Current();
  CHECK(isolate_data != nullptr);

  // Use tonic's library tag handler.
  CHECK(!tonic::LogIfError(Dart_SetLibraryTagHandler(
            tonic::DartLibraryLoader::HandleLibraryTag)));

  // Use tonic's file system library provider.
  isolate_data->set_library_provider(
      new tonic::DartLibraryProviderFiles(
          command_line.GetSwitchValuePath(kPackageRoot)));

  // Load script.
  tonic::DartScriptLoaderSync::LoadScript(args[0],
                                          isolate_data->library_provider());

  // Write snapshot.
  WriteSnapshot(command_line.GetSwitchValuePath(kSnapshot));

  return 0;
}

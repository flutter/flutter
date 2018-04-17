// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_snapshot.h"

#include <sstream>

#include "flutter/fml/native_library.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/snapshot/snapshot.h"
#include "flutter/runtime/dart_snapshot_buffer.h"
#include "flutter/runtime/dart_vm.h"

namespace blink {

const char* DartSnapshot::kVMDataSymbol = "kDartVmSnapshotData";
const char* DartSnapshot::kVMInstructionsSymbol = "kDartVmSnapshotInstructions";
const char* DartSnapshot::kIsolateDataSymbol = "kDartIsolateSnapshotData";
const char* DartSnapshot::kIsolateInstructionsSymbol =
    "kDartIsolateSnapshotInstructions";

std::unique_ptr<DartSnapshotBuffer> ResolveVMData(const Settings& settings) {
  if (settings.aot_snapshot_path.size() > 0) {
    auto path = fml::paths::JoinPaths(
        {settings.aot_snapshot_path, settings.aot_vm_snapshot_data_filename});
    if (auto source = DartSnapshotBuffer::CreateWithContentsOfFile(
            path.c_str(), false /* executable */)) {
      return source;
    }
  }

  auto loaded_process = fml::NativeLibrary::CreateForCurrentProcess();
  return DartSnapshotBuffer::CreateWithSymbolInLibrary(
      loaded_process, DartSnapshot::kVMDataSymbol);
}

std::unique_ptr<DartSnapshotBuffer> ResolveVMInstructions(
    const Settings& settings) {
  if (settings.aot_snapshot_path.size() > 0) {
    auto path = fml::paths::JoinPaths(
        {settings.aot_snapshot_path, settings.aot_vm_snapshot_instr_filename});
    if (auto source = DartSnapshotBuffer::CreateWithContentsOfFile(
            path.c_str(), true /* executable */)) {
      return source;
    }
  }

  if (settings.application_library_path.size() > 0) {
    auto library =
        fml::NativeLibrary::Create(settings.application_library_path.c_str());
    if (auto source = DartSnapshotBuffer::CreateWithSymbolInLibrary(
            library, DartSnapshot::kVMInstructionsSymbol)) {
      return source;
    }
  }

  auto loaded_process = fml::NativeLibrary::CreateForCurrentProcess();
  return DartSnapshotBuffer::CreateWithSymbolInLibrary(
      loaded_process, DartSnapshot::kVMInstructionsSymbol);
}

std::unique_ptr<DartSnapshotBuffer> ResolveIsolateData(
    const Settings& settings) {
  if (settings.aot_snapshot_path.size() > 0) {
    auto path =
        fml::paths::JoinPaths({settings.aot_snapshot_path,
                               settings.aot_isolate_snapshot_data_filename});
    if (auto source = DartSnapshotBuffer::CreateWithContentsOfFile(
            path.c_str(), false /* executable */)) {
      return source;
    }
  }

  auto loaded_process = fml::NativeLibrary::CreateForCurrentProcess();
  return DartSnapshotBuffer::CreateWithSymbolInLibrary(
      loaded_process, DartSnapshot::kIsolateDataSymbol);
}

std::unique_ptr<DartSnapshotBuffer> ResolveIsolateInstructions(
    const Settings& settings) {
  if (settings.aot_snapshot_path.size() > 0) {
    auto path =
        fml::paths::JoinPaths({settings.aot_snapshot_path,
                               settings.aot_isolate_snapshot_instr_filename});
    if (auto source = DartSnapshotBuffer::CreateWithContentsOfFile(
            path.c_str(), true /* executable */)) {
      return source;
    }
  }

  if (settings.application_library_path.size() > 0) {
    auto library =
        fml::NativeLibrary::Create(settings.application_library_path.c_str());
    if (auto source = DartSnapshotBuffer::CreateWithSymbolInLibrary(
            library, DartSnapshot::kIsolateInstructionsSymbol)) {
      return source;
    }
  }

  auto loaded_process = fml::NativeLibrary::CreateForCurrentProcess();
  return DartSnapshotBuffer::CreateWithSymbolInLibrary(
      loaded_process, DartSnapshot::kIsolateInstructionsSymbol);
}

fxl::RefPtr<DartSnapshot> DartSnapshot::VMSnapshotFromSettings(
    const Settings& settings) {
  TRACE_EVENT0("flutter", "DartSnapshot::VMSnapshotFromSettings");
#if OS_WIN
  return fxl::MakeRefCounted<DartSnapshot>(
      DartSnapshotBuffer::CreateWithUnmanagedAllocation(kDartVmSnapshotData),
      DartSnapshotBuffer::CreateWithUnmanagedAllocation(
          kDartVmSnapshotInstructions));
#else   // OS_WIN
  auto snapshot =
      fxl::MakeRefCounted<DartSnapshot>(ResolveVMData(settings),         //
                                        ResolveVMInstructions(settings)  //
      );
  if (snapshot->IsValid()) {
    return snapshot;
  }
  return nullptr;
#endif  // OS_WIN
}

fxl::RefPtr<DartSnapshot> DartSnapshot::IsolateSnapshotFromSettings(
    const Settings& settings) {
  TRACE_EVENT0("flutter", "DartSnapshot::IsolateSnapshotFromSettings");
#if OS_WIN
  return fxl::MakeRefCounted<DartSnapshot>(
      DartSnapshotBuffer::CreateWithUnmanagedAllocation(
          kDartIsolateSnapshotData),
      DartSnapshotBuffer::CreateWithUnmanagedAllocation(
          kDartIsolateSnapshotInstructions));
#else  // OS_WIN
  auto snapshot =
      fxl::MakeRefCounted<DartSnapshot>(ResolveIsolateData(settings),         //
                                        ResolveIsolateInstructions(settings)  //
      );
  if (snapshot->IsValid()) {
    return snapshot;
  }
  return nullptr;
#endif
}

DartSnapshot::DartSnapshot(std::unique_ptr<DartSnapshotBuffer> data,
                           std::unique_ptr<DartSnapshotBuffer> instructions)
    : data_(std::move(data)), instructions_(std::move(instructions)) {}

DartSnapshot::~DartSnapshot() = default;

bool DartSnapshot::IsValid() const {
  return static_cast<bool>(data_);
}

bool DartSnapshot::IsValidForAOT() const {
  return data_ && instructions_;
}

const DartSnapshotBuffer* DartSnapshot::GetData() const {
  return data_.get();
}

const DartSnapshotBuffer* DartSnapshot::GetInstructions() const {
  return instructions_.get();
}

const uint8_t* DartSnapshot::GetInstructionsIfPresent() const {
  return instructions_ ? instructions_->GetSnapshotPointer() : nullptr;
}

}  // namespace blink

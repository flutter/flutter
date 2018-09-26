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

#if defined(OS_ANDROID)
// When assembling the .S file of the application, dart_bootstrap will prefix
// symbols via an `_` to ensure Mac's `dlsym()` can find it (Mac ABI prefixes C
// symbols with underscores).
// But Linux ABI does not prefix C symbols with underscores, so we have to
// explicitly look up the prefixed version.
#define SYMBOL_PREFIX "_"
#else
#define SYMBOL_PREFIX ""
#endif

static const char* kVMDataSymbolSo = SYMBOL_PREFIX "kDartVmSnapshotData";
static const char* kVMInstructionsSymbolSo =
    SYMBOL_PREFIX "kDartVmSnapshotInstructions";
static const char* kIsolateDataSymbolSo =
    SYMBOL_PREFIX "kDartIsolateSnapshotData";
static const char* kIsolateInstructionsSymbolSo =
    SYMBOL_PREFIX "kDartIsolateSnapshotInstructions";

std::unique_ptr<DartSnapshotBuffer> ResolveVMData(const Settings& settings) {
  if (settings.vm_snapshot_data_path.size() > 0) {
    if (auto source = DartSnapshotBuffer::CreateWithContentsOfFile(
            fml::OpenFile(settings.vm_snapshot_data_path.c_str(), false,
                          fml::FilePermission::kRead),
            {fml::FileMapping::Protection::kRead})) {
      return source;
    }
  }

  if (settings.application_library_path.size() > 0) {
    auto shared_library =
        fml::NativeLibrary::Create(settings.application_library_path.c_str());
    if (auto source = DartSnapshotBuffer::CreateWithSymbolInLibrary(
            shared_library, kVMDataSymbolSo)) {
      return source;
    }
  }

  auto loaded_process = fml::NativeLibrary::CreateForCurrentProcess();
  return DartSnapshotBuffer::CreateWithSymbolInLibrary(
      loaded_process, DartSnapshot::kVMDataSymbol);
}

std::unique_ptr<DartSnapshotBuffer> ResolveVMInstructions(
    const Settings& settings) {
  if (settings.vm_snapshot_instr_path.size() > 0) {
    if (auto source = DartSnapshotBuffer::CreateWithContentsOfFile(
            fml::OpenFile(settings.vm_snapshot_instr_path.c_str(), false,
                          fml::FilePermission::kRead),
            {fml::FileMapping::Protection::kExecute})) {
      return source;
    }
  }

  if (settings.application_library_path.size() > 0) {
    auto library =
        fml::NativeLibrary::Create(settings.application_library_path.c_str());
    if (auto source = DartSnapshotBuffer::CreateWithSymbolInLibrary(
            library, kVMInstructionsSymbolSo)) {
      return source;
    }
  }

  auto loaded_process = fml::NativeLibrary::CreateForCurrentProcess();
  return DartSnapshotBuffer::CreateWithSymbolInLibrary(
      loaded_process, DartSnapshot::kVMInstructionsSymbol);
}

std::unique_ptr<DartSnapshotBuffer> ResolveIsolateData(
    const Settings& settings) {
  if (settings.isolate_snapshot_data_path.size() > 0) {
    if (auto source = DartSnapshotBuffer::CreateWithContentsOfFile(
            fml::OpenFile(settings.isolate_snapshot_data_path.c_str(), false,
                          fml::FilePermission::kRead),
            {fml::FileMapping::Protection::kRead})) {
      return source;
    }
  }

  if (settings.application_library_path.size() > 0) {
    auto library =
        fml::NativeLibrary::Create(settings.application_library_path.c_str());
    if (auto source = DartSnapshotBuffer::CreateWithSymbolInLibrary(
            library, kIsolateDataSymbolSo)) {
      return source;
    }
  }

  auto loaded_process = fml::NativeLibrary::CreateForCurrentProcess();
  return DartSnapshotBuffer::CreateWithSymbolInLibrary(
      loaded_process, DartSnapshot::kIsolateDataSymbol);
}

std::unique_ptr<DartSnapshotBuffer> ResolveIsolateInstructions(
    const Settings& settings) {
  if (settings.isolate_snapshot_instr_path.size() > 0) {
    if (auto source = DartSnapshotBuffer::CreateWithContentsOfFile(
            fml::OpenFile(settings.isolate_snapshot_instr_path.c_str(), false,
                          fml::FilePermission::kRead),
            {fml::FileMapping::Protection::kExecute})) {
      return source;
    }
  }

  if (settings.application_library_path.size() > 0) {
    auto library =
        fml::NativeLibrary::Create(settings.application_library_path.c_str());
    if (auto source = DartSnapshotBuffer::CreateWithSymbolInLibrary(
            library, kIsolateInstructionsSymbolSo)) {
      return source;
    }
  }

  auto loaded_process = fml::NativeLibrary::CreateForCurrentProcess();
  return DartSnapshotBuffer::CreateWithSymbolInLibrary(
      loaded_process, DartSnapshot::kIsolateInstructionsSymbol);
}

fml::RefPtr<DartSnapshot> DartSnapshot::VMSnapshotFromSettings(
    const Settings& settings) {
  TRACE_EVENT0("flutter", "DartSnapshot::VMSnapshotFromSettings");
#if OS_WIN
  return fml::MakeRefCounted<DartSnapshot>(
      DartSnapshotBuffer::CreateWithUnmanagedAllocation(kDartVmSnapshotData),
      DartSnapshotBuffer::CreateWithUnmanagedAllocation(
          kDartVmSnapshotInstructions));
#else   // OS_WIN
  auto snapshot =
      fml::MakeRefCounted<DartSnapshot>(ResolveVMData(settings),         //
                                        ResolveVMInstructions(settings)  //
      );
  if (snapshot->IsValid()) {
    return snapshot;
  }
  return nullptr;
#endif  // OS_WIN
}

fml::RefPtr<DartSnapshot> DartSnapshot::IsolateSnapshotFromSettings(
    const Settings& settings) {
  TRACE_EVENT0("flutter", "DartSnapshot::IsolateSnapshotFromSettings");
#if OS_WIN
  return fml::MakeRefCounted<DartSnapshot>(
      DartSnapshotBuffer::CreateWithUnmanagedAllocation(
          kDartIsolateSnapshotData),
      DartSnapshotBuffer::CreateWithUnmanagedAllocation(
          kDartIsolateSnapshotInstructions));
#else  // OS_WIN
  auto snapshot =
      fml::MakeRefCounted<DartSnapshot>(ResolveIsolateData(settings),         //
                                        ResolveIsolateInstructions(settings)  //
      );
  if (snapshot->IsValid()) {
    return snapshot;
  }
  return nullptr;
#endif
}

fml::RefPtr<DartSnapshot> DartSnapshot::Empty() {
  return fml::MakeRefCounted<DartSnapshot>(nullptr, nullptr);
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

const uint8_t* DartSnapshot::GetDataIfPresent() const {
  return data_ ? data_->GetSnapshotPointer() : nullptr;
}

const uint8_t* DartSnapshot::GetInstructionsIfPresent() const {
  return instructions_ ? instructions_->GetSnapshotPointer() : nullptr;
}

}  // namespace blink

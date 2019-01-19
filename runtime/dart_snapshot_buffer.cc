// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_snapshot_buffer.h"

#include <utility>

#include "flutter/fml/mapping.h"

namespace blink {

class NativeLibrarySnapshotBuffer final : public DartSnapshotBuffer {
 public:
  NativeLibrarySnapshotBuffer(fml::RefPtr<fml::NativeLibrary> library,
                              const char* symbol_name)
      : library_(std::move(library)) {
    if (library_) {
      symbol_ = library_->ResolveSymbol(symbol_name);
    }
  }

  const uint8_t* GetSnapshotPointer() const override { return symbol_; }

  size_t GetSnapshotSize() const override { return 0; }

 private:
  fml::RefPtr<fml::NativeLibrary> library_;
  const uint8_t* symbol_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(NativeLibrarySnapshotBuffer);
};

class MappingBuffer final : public DartSnapshotBuffer {
 public:
  MappingBuffer(std::unique_ptr<fml::Mapping> mapping)
      : mapping_(std::move(mapping)) {
    FML_DCHECK(mapping_);
  }

  const uint8_t* GetSnapshotPointer() const override {
    return mapping_->GetMapping();
  }

  size_t GetSnapshotSize() const override { return mapping_->GetSize(); }

 private:
  std::unique_ptr<fml::Mapping> mapping_;

  FML_DISALLOW_COPY_AND_ASSIGN(MappingBuffer);
};

class UnmanagedAllocation final : public DartSnapshotBuffer {
 public:
  UnmanagedAllocation(const uint8_t* allocation) : allocation_(allocation) {}

  const uint8_t* GetSnapshotPointer() const override { return allocation_; }

  size_t GetSnapshotSize() const override { return 0; }

 private:
  const uint8_t* allocation_;

  FML_DISALLOW_COPY_AND_ASSIGN(UnmanagedAllocation);
};

std::unique_ptr<DartSnapshotBuffer>
DartSnapshotBuffer::CreateWithSymbolInLibrary(
    fml::RefPtr<fml::NativeLibrary> library,
    const char* symbol_name) {
  auto source = std::make_unique<NativeLibrarySnapshotBuffer>(
      std::move(library), symbol_name);
  return source->GetSnapshotPointer() == nullptr ? nullptr : std::move(source);
}

std::unique_ptr<DartSnapshotBuffer>
DartSnapshotBuffer::CreateWithContentsOfFile(
    const fml::UniqueFD& fd,
    std::initializer_list<fml::FileMapping::Protection> protection) {
  return CreateWithMapping(std::make_unique<fml::FileMapping>(fd, protection));
}

std::unique_ptr<DartSnapshotBuffer> DartSnapshotBuffer::CreateWithMapping(
    std::unique_ptr<fml::Mapping> mapping) {
  if (mapping == nullptr || mapping->GetSize() == 0 ||
      mapping->GetMapping() == nullptr) {
    return nullptr;
  }
  return std::make_unique<MappingBuffer>(std::move(mapping));
}

std::unique_ptr<DartSnapshotBuffer>
DartSnapshotBuffer::CreateWithUnmanagedAllocation(const uint8_t* allocation) {
  if (allocation == nullptr) {
    return nullptr;
  }
  return std::make_unique<UnmanagedAllocation>(allocation);
}

DartSnapshotBuffer::~DartSnapshotBuffer() = default;

}  // namespace blink

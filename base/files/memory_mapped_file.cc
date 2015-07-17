// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/memory_mapped_file.h"

#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/sys_info.h"

namespace base {

const MemoryMappedFile::Region MemoryMappedFile::Region::kWholeFile = {0, 0};

bool MemoryMappedFile::Region::operator==(
    const MemoryMappedFile::Region& other) const {
  return other.offset == offset && other.size == size;
}

bool MemoryMappedFile::Region::operator!=(
    const MemoryMappedFile::Region& other) const {
  return other.offset != offset || other.size != size;
}

MemoryMappedFile::~MemoryMappedFile() {
  CloseHandles();
}

#if !defined(OS_NACL)
bool MemoryMappedFile::Initialize(const FilePath& file_name) {
  if (IsValid())
    return false;

  file_.Initialize(file_name, File::FLAG_OPEN | File::FLAG_READ);

  if (!file_.IsValid()) {
    DLOG(ERROR) << "Couldn't open " << file_name.AsUTF8Unsafe();
    return false;
  }

  if (!MapFileRegionToMemory(Region::kWholeFile)) {
    CloseHandles();
    return false;
  }

  return true;
}

bool MemoryMappedFile::Initialize(File file) {
  return Initialize(file.Pass(), Region::kWholeFile);
}

bool MemoryMappedFile::Initialize(File file, const Region& region) {
  if (IsValid())
    return false;

  if (region != Region::kWholeFile) {
    DCHECK_GE(region.offset, 0);
    DCHECK_GT(region.size, 0);
  }

  file_ = file.Pass();

  if (!MapFileRegionToMemory(region)) {
    CloseHandles();
    return false;
  }

  return true;
}

bool MemoryMappedFile::IsValid() const {
  return data_ != NULL;
}

// static
void MemoryMappedFile::CalculateVMAlignedBoundaries(int64 start,
                                                    int64 size,
                                                    int64* aligned_start,
                                                    int64* aligned_size,
                                                    int32* offset) {
  // Sadly, on Windows, the mmap alignment is not just equal to the page size.
  const int64 mask = static_cast<int64>(SysInfo::VMAllocationGranularity()) - 1;
  DCHECK_LT(mask, std::numeric_limits<int32>::max());
  *offset = start & mask;
  *aligned_start = start & ~mask;
  *aligned_size = (size + *offset + mask) & ~mask;
}
#endif

}  // namespace base

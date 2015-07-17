// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/memory_mapped_file.h"

#include "base/files/file_path.h"
#include "base/strings/string16.h"
#include "base/threading/thread_restrictions.h"

namespace base {

MemoryMappedFile::MemoryMappedFile() : data_(NULL), length_(0), image_(false) {
}

bool MemoryMappedFile::InitializeAsImageSection(const FilePath& file_name) {
  image_ = true;
  return Initialize(file_name);
}

bool MemoryMappedFile::MapFileRegionToMemory(
    const MemoryMappedFile::Region& region) {
  ThreadRestrictions::AssertIOAllowed();

  if (!file_.IsValid())
    return false;

  int flags = image_ ? SEC_IMAGE | PAGE_READONLY : PAGE_READONLY;

  file_mapping_.Set(::CreateFileMapping(file_.GetPlatformFile(), NULL,
                                        flags, 0, 0, NULL));
  if (!file_mapping_.IsValid())
    return false;

  LARGE_INTEGER map_start = {};
  SIZE_T map_size = 0;
  int32 data_offset = 0;

  if (region == MemoryMappedFile::Region::kWholeFile) {
    int64 file_len = file_.GetLength();
    if (file_len <= 0 || file_len > kint32max)
      return false;
    length_ = static_cast<size_t>(file_len);
  } else {
    // The region can be arbitrarily aligned. MapViewOfFile, instead, requires
    // that the start address is aligned to the VM granularity (which is
    // typically larger than a page size, for instance 32k).
    // Also, conversely to POSIX's mmap, the |map_size| doesn't have to be
    // aligned and must be less than or equal the mapped file size.
    // We map here the outer region [|aligned_start|, |aligned_start+size|]
    // which contains |region| and then add up the |data_offset| displacement.
    int64 aligned_start = 0;
    int64 ignored = 0;
    CalculateVMAlignedBoundaries(
        region.offset, region.size, &aligned_start, &ignored, &data_offset);
    int64 size = region.size + data_offset;

    // Ensure that the casts below in the MapViewOfFile call are sane.
    if (aligned_start < 0 || size < 0 ||
        static_cast<uint64>(size) > std::numeric_limits<SIZE_T>::max()) {
      DLOG(ERROR) << "Region bounds are not valid for MapViewOfFile";
      return false;
    }
    map_start.QuadPart = aligned_start;
    map_size = static_cast<SIZE_T>(size);
    length_ = static_cast<size_t>(region.size);
  }

  data_ = static_cast<uint8*>(::MapViewOfFile(file_mapping_.Get(),
                                              FILE_MAP_READ,
                                              map_start.HighPart,
                                              map_start.LowPart,
                                              map_size));
  if (data_ == NULL)
    return false;
  data_ += data_offset;
  return true;
}

void MemoryMappedFile::CloseHandles() {
  if (data_)
    ::UnmapViewOfFile(data_);
  if (file_mapping_.IsValid())
    file_mapping_.Close();
  if (file_.IsValid())
    file_.Close();

  data_ = NULL;
  length_ = 0;
}

}  // namespace base

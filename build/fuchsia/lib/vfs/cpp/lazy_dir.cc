// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/vfs/cpp/lazy_dir.h>

#include <lib/fdio/vfs.h>
#include <lib/vfs/cpp/internal/dirent_filler.h>

#include <algorithm>

namespace vfs {

bool LazyDir::LazyEntry::operator<(const LazyDir::LazyEntry& rhs) const {
  return id < rhs.id;
}

LazyDir::LazyDir() {}

LazyDir::~LazyDir() = default;

zx_status_t LazyDir::GetAttr(
    fuchsia::io::NodeAttributes* out_attributes) const {
  out_attributes->mode = fuchsia::io::MODE_TYPE_DIRECTORY | V_IRUSR;
  out_attributes->id = fuchsia::io::INO_UNKNOWN;
  out_attributes->content_size = 0;
  out_attributes->storage_size = 0;
  out_attributes->link_count = 1;
  out_attributes->creation_time = 0;
  out_attributes->modification_time = 0;
  return ZX_OK;
}

zx_status_t LazyDir::Lookup(const std::string& name, Node** out_node) const {
  LazyEntryVector entries;
  GetContents(&entries);
  for (const auto& entry : entries) {
    if (name == entry.name) {
      return GetFile(out_node, entry.id, entry.name);
    }
  }
  return ZX_ERR_NOT_FOUND;
}

zx_status_t LazyDir::Readdir(uint64_t offset, void* data, uint64_t len,
                             uint64_t* out_offset, uint64_t* out_actual) {
  LazyEntryVector entries;
  GetContents(&entries);
  std::sort(entries.begin(), entries.end());

  vfs::internal::DirentFiller filler(data, len);

  const uint64_t ino = fuchsia::io::INO_UNKNOWN;
  if (offset < kDotId) {
    if (filler.Next(".", 1, fuchsia::io::DIRENT_TYPE_DIRECTORY, ino) != ZX_OK) {
      *out_actual = filler.GetBytesFilled();
      return ZX_ERR_INVALID_ARGS;  // out_actual would be 0
    }
    offset++;
    *out_offset = kDotId;
  }
  for (auto it = std::upper_bound(
           entries.begin(), entries.end(), offset,
           [](uint64_t b_id, const LazyEntry&a) { return b_id < a.id; });
       it != entries.end(); ++it) {
    auto dtype = ((fuchsia::io::MODE_TYPE_MASK & it->type) >> 12);
    if (filler.Next(it->name, dtype, ino) != ZX_OK) {
      *out_actual = filler.GetBytesFilled();
      if (*out_actual == 0) {
        // no space to fill even 1 dentry
        return ZX_ERR_INVALID_ARGS;
      }
      return ZX_OK;
    }
    *out_offset = it->id;
  }

  *out_actual = filler.GetBytesFilled();
  return ZX_OK;
}

uint64_t LazyDir::GetStartingId() const { return kDotId + 1; }

}  // namespace vfs

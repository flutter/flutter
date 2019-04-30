// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/vfs/cpp/vmo_file.h>

namespace vfs {

VmoFile::VmoFile(zx::unowned_vmo unowned_vmo, size_t offset, size_t length,
                 WriteOption write_option, Sharing vmo_sharing)
    : offset_(offset),
      length_(length),
      write_option_(write_option),
      vmo_sharing_(vmo_sharing) {
  unowned_vmo->duplicate(ZX_RIGHT_SAME_RIGHTS, &vmo_);
}

VmoFile::VmoFile(zx::vmo vmo, size_t offset, size_t length,
                 WriteOption write_option, Sharing vmo_sharing)
    : offset_(offset),
      length_(length),
      write_option_(write_option),
      vmo_sharing_(vmo_sharing),
      vmo_(std::move(vmo)) {}

VmoFile::~VmoFile() = default;

void VmoFile::Describe(fuchsia::io::NodeInfo* out_info) {
  zx::vmo temp_vmo;
  switch (vmo_sharing_) {
    case Sharing::NONE:
      out_info->set_file(fuchsia::io::FileObject());
      break;
    case Sharing::DUPLICATE:
      if (vmo_.duplicate(write_option_ == WriteOption::WRITABLE
                             ? ZX_RIGHTS_BASIC | ZX_RIGHT_READ | ZX_RIGHT_WRITE
                             : ZX_RIGHTS_BASIC | ZX_RIGHT_READ,
                         &temp_vmo) != ZX_OK) {
        return;
      }
      out_info->vmofile() = fuchsia::io::Vmofile{
          .vmo = std::move(temp_vmo), .length = length_, .offset = offset_};
      break;
    case Sharing::CLONE_COW:
      if (vmo_.clone(ZX_VMO_CLONE_COPY_ON_WRITE, offset_, length_, &temp_vmo) !=
          ZX_OK) {
        return;
      }
      out_info->vmofile() = fuchsia::io::Vmofile{
          .vmo = std::move(temp_vmo), .length = length_, .offset = offset_};
      break;
  }
}

uint32_t VmoFile::GetAdditionalAllowedFlags() const {
  return fuchsia::io::OPEN_RIGHT_READABLE |
         (write_option_ == WriteOption::WRITABLE
              ? fuchsia::io::OPEN_RIGHT_WRITABLE
              : 0);
}

zx_status_t VmoFile::ReadAt(uint64_t length, uint64_t offset,
                            std::vector<uint8_t>* out_data) {
  if (length == 0u || offset >= length_) {
    return ZX_OK;
  }

  size_t remaining_length = length_ - offset;
  if (length > remaining_length) {
    length = remaining_length;
  }

  out_data->resize(length);
  return vmo_.read(out_data->data(), offset_ + offset, length);
}

zx_status_t VmoFile::WriteAt(std::vector<uint8_t> data, uint64_t offset,
                             uint64_t* out_actual) {
  size_t length = data.size();
  if (length == 0u) {
    *out_actual = 0u;
    return ZX_OK;
  }
  if (offset >= length_) {
    return ZX_ERR_NO_SPACE;
  }

  size_t remaining_length = length_ - offset;
  if (length > remaining_length) {
    length = remaining_length;
  }
  zx_status_t status = vmo_.write(data.data(), offset_ + offset, length);
  if (status == ZX_OK) {
    *out_actual = length;
  }
  return status;
}

zx_status_t VmoFile::Truncate(uint64_t length) { return ZX_ERR_NOT_SUPPORTED; }

size_t VmoFile::GetCapacity() { return length_; };

size_t VmoFile::GetLength() { return length_; }

zx_status_t VmoFile::GetAttr(
    fuchsia::io::NodeAttributes* out_attributes) const {
  out_attributes->mode =
      fuchsia::io::MODE_TYPE_FILE | fuchsia::io::OPEN_RIGHT_READABLE |
      (write_option_ == WriteOption::WRITABLE ? fuchsia::io::OPEN_RIGHT_WRITABLE
                                              : 0);
  out_attributes->id = fuchsia::io::INO_UNKNOWN;
  out_attributes->content_size = length_;
  out_attributes->storage_size = length_;
  out_attributes->link_count = 1;
  out_attributes->creation_time = 0;
  out_attributes->modification_time = 0;
  return ZX_OK;
}

}  // namespace vfs

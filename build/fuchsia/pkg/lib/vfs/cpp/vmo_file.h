// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_VMO_FILE_H_
#define LIB_VFS_CPP_VMO_FILE_H_

#include <fuchsia/io/cpp/fidl.h>
#include <lib/vfs/cpp/file.h>
#include <lib/zx/vmo.h>
#include <stdint.h>

#include <vector>

namespace vfs {

// A file object in a file system backed by a VMO.
//
// Implements the |fuchsia.io.File| interface. Incoming connections are
// owned by this object and will be destroyed when this object is destroyed.
//
// See also:
//
//  * File, which represents file objects.
class VmoFile : public File {
 public:
  // Specifies the desired behavior of writes.
  enum class WriteOption {
    // The VMO handle and file are read only.
    READ_ONLY,
    // The VMO handle and file will be writable.
    WRITABLE,
  };

  // Specifies the desired behavior when a client asks for the file's
  // underlying VMO.
  enum class Sharing {
    // The VMO is not shared with the client.
    NONE,

    // The VMO handle is duplicated for each client.
    //
    // This is appropriate when it is okay for clients to access the entire
    // contents of the VMO, possibly extending beyond the pages spanned by the
    // file.
    //
    // This mode is significantly more efficient than |CLONE| and |CLONE_COW|
    // and should be preferred when file spans the whole VMO or when the VMO's
    // entire content is safe for clients to read.
    DUPLICATE,

    // The VMO range spanned by the file is cloned on demand, using
    // copy-on-write
    // semantics to isolate modifications of clients which open the file in
    // a writable mode.
    //
    // This is appropriate when clients need to be restricted from accessing
    // portions of the VMO outside of the range of the file and when file
    // modifications by clients should not be visible to each other.
    CLONE_COW,
  };

  // Creates a file node backed an VMO owned by the creator.
  // The creator retains ownership of |unowned_vmo| which must outlive this
  // object.
  VmoFile(zx::unowned_vmo unowned_vmo, size_t offset, size_t length,
          WriteOption write_options = WriteOption::READ_ONLY,
          Sharing vmo_sharing = Sharing::DUPLICATE);

  // Creates a file node backed by a VMO. The VmoFile takes ownership of the
  // vmo.
  VmoFile(zx::vmo vmo, size_t offset, size_t length,
          WriteOption write_options = WriteOption::READ_ONLY,
          Sharing vmo_sharing = Sharing::DUPLICATE);

  ~VmoFile();

  // Create |count| bytes of data from the file at the given |offset|.
  //
  // The data read should be copied to |out_data|, which should be empty when
  // passed as an argument. When |ReadAt| returns, |out_data| should contain no
  // more than |count| bytes.
  zx_status_t ReadAt(uint64_t count, uint64_t offset,
                     std::vector<uint8_t>* out_data) override;

  // Write the given |data| to the file at the given |offset|.
  //
  // Data should be copied into the file starting at the beginning of |data|.
  // If |WriteAt| returns |ZX_OK|, |out_actual| should contain the number of
  // bytes actually written to the file.
  zx_status_t WriteAt(std::vector<uint8_t> data, uint64_t offset,
                      uint64_t* out_actual) override;

  // Resize the file to the given |length|.
  zx_status_t Truncate(uint64_t length) override;

  // Override that describes this object as a vmofile.
  void Describe(fuchsia::io::NodeInfo* out_info) override;

  // Returns current file length.
  //
  // All implementations should implement this.
  uint64_t GetLength() override;

  // Returns file capacity.
  //
  // Seek() uses this to return ZX_ERR_OUT_OF_RANGE if new seek is more than
  // this value.
  size_t GetCapacity() override;

  // Returns the node attributes for this VmoFile.
  zx_status_t GetAttr(
      fuchsia::io::NodeAttributes* out_attributes) const override;

 protected:
  uint32_t GetAdditionalAllowedFlags() const override;

 private:
  const size_t offset_;
  const size_t length_;
  const WriteOption write_option_;
  const Sharing vmo_sharing_;

  zx::vmo vmo_;
};

}  // namespace vfs

#endif  // LIB_VFS_CPP_VMO_FILE_H_

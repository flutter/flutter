// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_LAZY_DIR_H_
#define LIB_VFS_CPP_LAZY_DIR_H_

#include <lib/vfs/cpp/directory.h>

namespace vfs {

// A |LazyDir| a base class for directories that dynamically update their
// contents on each operation.  Clients should derive from this class
// and implement GetContents and GetFile for their use case.  The base
// implementation of this class is thread-safe, but it is up to implementers
// to ensure their implementations are thread safe as well.
class LazyDir : public Directory {
 public:
  // Structure storing a single entry in the directory.
  struct LazyEntry {
    // Should be more than or equal to |GetStartingId()|, must remain stable
    // across calls.
    uint64_t id;
    std::string name;
    uint32_t type;

    bool operator<(const LazyEntry& rhs) const;
  };
  using LazyEntryVector = std::vector<LazyEntry>;

  LazyDir();
  ~LazyDir() override;

  // |Directory| implementation:
  zx_status_t Readdir(uint64_t offset, void* data, uint64_t len,
                      uint64_t* out_offset, uint64_t* out_actual) override;

  // |Node| implementations:
  zx_status_t GetAttr(
      fuchsia::io::NodeAttributes* out_attributes) const override;

  zx_status_t Lookup(const std::string& name, Node** out_node) const final;

 protected:
  // Get the contents of the directory in an output vector.
  virtual void GetContents(LazyEntryVector* out_vector) const = 0;

  // Get the reference to a single file. The id and name of the entry as
  // returned from GetContents are passed in to assist locating the file.
  virtual zx_status_t GetFile(Node** out_node, uint64_t id,
                              std::string name) const = 0;

  // Ids returned by |GetContent| should be more than or equal to id returned by
  // this function.
  uint64_t GetStartingId() const;

 private:
  static constexpr uint64_t kDotId = 1u;
};

}  // namespace vfs

#endif  // LIB_VFS_CPP_LAZY_DIR_H_

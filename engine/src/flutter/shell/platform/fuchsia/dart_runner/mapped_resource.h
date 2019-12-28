// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef APPS_DART_RUNNER_MAPPED_RESOURCE_H_
#define APPS_DART_RUNNER_MAPPED_RESOURCE_H_

#include <fuchsia/mem/cpp/fidl.h>
#include <lib/fdio/namespace.h>

namespace dart_runner {

class MappedResource {
 public:
  MappedResource() : address_(nullptr), size_(0) {}
  MappedResource(MappedResource&& other)
      : address_(other.address_), size_(other.size_) {
    other.address_ = nullptr;
    other.size_ = 0;
  }
  MappedResource& operator=(MappedResource&& other) {
    address_ = other.address_;
    size_ = other.size_;
    other.address_ = nullptr;
    other.size_ = 0;
    return *this;
  }
  ~MappedResource();

  // Loads the content of a file from the given namespace and maps it into the
  // current process's address space. If namespace is null, the fdio "global"
  // namespace is used (in which case, ./pkg means the dart_runner's package).
  // The content is unmapped when the MappedResource goes out of scope. Returns
  // true on success.
  static bool LoadFromNamespace(fdio_ns_t* namespc,
                                const std::string& path,
                                MappedResource& resource,
                                bool executable = false);

  // Maps a VMO into the current process's address space. The content is
  // unmapped when the MappedResource goes out of scope. Returns true on
  // success. The path is used only for error messages.
  static bool LoadFromVmo(const std::string& path,
                          fuchsia::mem::Buffer resource_vmo,
                          MappedResource& resource,
                          bool executable = false);

  const uint8_t* address() const {
    return reinterpret_cast<const uint8_t*>(address_);
  }
  size_t size() const { return size_; }

 private:
  void* address_;
  size_t size_;

  // Disallow copy and assignment.
  MappedResource(const MappedResource&) = delete;
  MappedResource& operator=(const MappedResource&) = delete;
};

}  // namespace dart_runner

#endif  // APPS_DART_RUNNER_MAPPED_RESOURCE_H_

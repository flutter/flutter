// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <string>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/compositor/texture_descriptor.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Specified where the allocation resides and how it is used.
///
enum class StorageMode {
  //----------------------------------------------------------------------------
  /// Allocations can be mapped onto the hosts address space and also be used by
  /// the device.
  ///
  kHostVisible,
  //----------------------------------------------------------------------------
  /// Allocations can only be used by the device. This location is optimal for
  /// use by the device. If the host needs to access these allocations, the
  /// transfer queue must be used to transfer this allocation onto the a host
  /// visible buffer.
  ///
  kDevicePrivate,
  //----------------------------------------------------------------------------
  /// Used by the device for temporary render targets. These allocations cannot
  /// be transferred from and to other allocations using the transfer queue.
  /// Render pass cannot initialize the contents of these buffers using load and
  /// store actions.
  ///
  /// These allocations reside in tile memory which has higher bandwidth, lower
  /// latency and lower power consumption. The total device memory usage is
  /// also lower as a separate allocation does not need to be created in
  /// device memory. Prefer using these allocations for intermediates like depth
  /// and stencil buffers.
  ///
  kDeviceTransient,
};

class Context;
class DeviceBuffer;
class Texture;

class Allocator {
 public:
  ~Allocator();

  bool IsValid() const;

  std::shared_ptr<DeviceBuffer> CreateBuffer(StorageMode mode, size_t length);

  std::shared_ptr<Texture> CreateTexture(StorageMode mode,
                                         const TextureDescriptor& desc);

  std::shared_ptr<DeviceBuffer> CreateBufferWithCopy(const uint8_t* buffer,
                                                     size_t length);

  std::shared_ptr<DeviceBuffer> CreateBufferWithCopy(
      const fml::Mapping& mapping);

  static bool RequiresExplicitHostSynchronization(StorageMode mode);

 private:
  friend class Context;

  // In the prototype, we are going to be allocating resources directly with the
  // MTLDevice APIs. But, in the future, this could be backed by named heaps
  // with specific limits.
  id<MTLDevice> device_;
  std::string allocator_label_;
  bool is_valid_ = false;

  Allocator(id<MTLDevice> device, std::string label);

  FML_DISALLOW_COPY_AND_ASSIGN(Allocator);
};

}  // namespace impeller

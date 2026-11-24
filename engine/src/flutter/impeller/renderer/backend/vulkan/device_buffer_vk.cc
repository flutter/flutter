// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"

#include "flutter/flutter_vma/flutter_vma.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"

namespace impeller {

DeviceBufferVK::BufferResource::~BufferResource() {
  if (tracker) {
    auto lock = tracker->LockShared();
    if (!tracker->IsShutdown()) {
      tracker->Unregister(this);
      info = {};
      buffer.reset();
    }
  }
}

void DeviceBufferVK::BufferResource::Invalidate(void* ptr) {
  auto* self = static_cast<BufferResource*>(ptr);
  self->info = {};
  self->buffer.reset();
}

DeviceBufferVK::DeviceBufferVK(DeviceBufferDescriptor desc,
                               std::weak_ptr<Context> context,
                               UniqueBufferVMA buffer,
                               VmaAllocationInfo info,
                               bool is_host_coherent,
                               std::shared_ptr<VmaResourceTracker> tracker)
    : DeviceBuffer(desc),
      context_(std::move(context)),
      tracker_(tracker),
      resource_(ContextVK::Cast(*context_.lock().get()).GetResourceManager(),
                BufferResource{
                    std::move(buffer),  //
                    info,               //
                    std::move(tracker)  //
                }),
      is_host_coherent_(is_host_coherent) {
  if (tracker_) {
    if (auto* res = resource_.GetMutable()) {
      tracker_->Register(res, &BufferResource::Invalidate);
    }
  }
}

DeviceBufferVK::~DeviceBufferVK() = default;

uint8_t* DeviceBufferVK::OnGetContents() const {
  return static_cast<uint8_t*>(resource_->info.pMappedData);
}

bool DeviceBufferVK::OnCopyHostBuffer(const uint8_t* source,
                                      Range source_range,
                                      size_t offset) {
  auto lock =
      tracker_ ? tracker_->LockShared() : std::shared_lock<std::shared_mutex>{};
  if ((tracker_ && tracker_->IsShutdown()) || !resource_->buffer.is_valid()) {
    return false;
  }
  uint8_t* dest = OnGetContents();

  if (!dest) {
    return false;
  }

  if (source) {
    ::memmove(dest + offset, source + source_range.offset, source_range.length);
  }
  ::vmaFlushAllocation(resource_->buffer.get().allocator,
                       resource_->buffer.get().allocation, offset,
                       source_range.length);

  return true;
}

bool DeviceBufferVK::SetLabel(std::string_view label) {
#ifdef IMPELLER_DEBUG
  // Lock context_ before tracker_ so context drops after the shared lock.
  auto context = context_.lock();
  if (!context) {
    // The context could have died at this point.
    return false;
  }
  auto lock =
      tracker_ ? tracker_->LockShared() : std::shared_lock<std::shared_mutex>{};
  if ((tracker_ && tracker_->IsShutdown()) || !resource_->buffer.is_valid()) {
    return false;
  }

  ::vmaSetAllocationName(resource_->buffer.get().allocator,   //
                         resource_->buffer.get().allocation,  //
                         label.data()                         //
  );

  return ContextVK::Cast(*context).SetDebugName(resource_->buffer.get().buffer,
                                                label);
#else
  return true;
#endif  // IMPELLER_DEBUG
}

void DeviceBufferVK::Flush(std::optional<Range> range) const {
  if (is_host_coherent_ || !resource_->buffer.is_valid()) {
    return;
  }
  auto flush_range = range.value_or(Range{0, GetDeviceBufferDescriptor().size});
  ::vmaFlushAllocation(resource_->buffer.get().allocator,
                       resource_->buffer.get().allocation, flush_range.offset,
                       flush_range.length);
}

// Visible for testing.
bool DeviceBufferVK::IsHostCoherent() const {
  return is_host_coherent_;
}

void DeviceBufferVK::Invalidate(std::optional<Range> range) const {
  auto lock =
      tracker_ ? tracker_->LockShared() : std::shared_lock<std::shared_mutex>{};
  if ((tracker_ && tracker_->IsShutdown()) || !resource_->buffer.is_valid()) {
    return;
  }
  auto flush_range = range.value_or(Range{0, GetDeviceBufferDescriptor().size});
  ::vmaInvalidateAllocation(resource_->buffer.get().allocator,
                            resource_->buffer.get().allocation,
                            flush_range.offset, flush_range.length);
}

bool DeviceBufferVK::SetLabel(std::string_view label, Range range) {
  // We do not have the ability to name ranges. Just name the whole thing.
  return SetLabel(label);
}

vk::Buffer DeviceBufferVK::GetBuffer() const {
  return resource_->buffer.get().buffer;
}

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SHARED_OBJECT_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SHARED_OBJECT_VK_H_

#include <memory>
#include <utility>

#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class SharedObjectVK {
 public:
  virtual ~SharedObjectVK() = default;
};

template <class T>
class SharedObjectVKT : public SharedObjectVK {
 public:
  using Resource = T;
  using UniqueResource =
      vk::UniqueHandle<Resource, VULKAN_HPP_DEFAULT_DISPATCHER_TYPE>;

  SharedObjectVKT(UniqueResource res,
                  std::weak_ptr<DeviceHolderVK> device_holder)
      : resource_(std::move(res)), device_holder_(std::move(device_holder)) {}

  ~SharedObjectVKT() override {
    auto device_holder = device_holder_.lock();
    if (!device_holder || !device_holder->GetDevice()) {
      // The device has already been destroyed. Release the handle without
      // calling vkDestroy* on a dead VkDevice.
      resource_.release();
    } else {
      resource_.reset();
    }
  }

  // NOLINTNEXTLINE(google-explicit-constructor)
  operator Resource() const { return Get(); }

  const Resource& Get() const { return *resource_; }

  const UniqueResource& GetUniqueWrapper() const { return resource_; }

 private:
  UniqueResource resource_;
  std::weak_ptr<DeviceHolderVK> device_holder_;

  SharedObjectVKT(const SharedObjectVKT&) = delete;

  SharedObjectVKT& operator=(const SharedObjectVKT&) = delete;
};

template <class T>
auto MakeSharedVK(
    vk::UniqueHandle<T, VULKAN_HPP_DEFAULT_DISPATCHER_TYPE> handle,
    std::weak_ptr<DeviceHolderVK> device_holder) {
  if (!handle) {
    return std::shared_ptr<SharedObjectVKT<T>>{nullptr};
  }
  return std::make_shared<SharedObjectVKT<T>>(std::move(handle),
                                              std::move(device_holder));
}

template <class T>
using SharedHandleVK = std::shared_ptr<SharedObjectVKT<T>>;

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SHARED_OBJECT_VK_H_

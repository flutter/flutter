// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
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

  explicit SharedObjectVKT(UniqueResource res) : resource_(std::move(res)) {}

  operator Resource() const { return Get(); }

  const Resource& Get() const { return *resource_; }

 private:
  UniqueResource resource_;

  SharedObjectVKT(const SharedObjectVKT&) = delete;

  SharedObjectVKT& operator=(const SharedObjectVKT&) = delete;
};

template <class T>
auto MakeSharedVK(
    vk::UniqueHandle<T, VULKAN_HPP_DEFAULT_DISPATCHER_TYPE> handle) {
  if (!handle) {
    return std::shared_ptr<SharedObjectVKT<T>>{nullptr};
  }
  return std::make_shared<SharedObjectVKT<T>>(std::move(handle));
}

template <class T>
using SharedHandleVK = std::shared_ptr<SharedObjectVKT<T>>;

}  // namespace impeller

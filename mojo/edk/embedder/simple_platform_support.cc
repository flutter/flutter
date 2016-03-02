// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/simple_platform_support.h"

#include <utility>

#include "mojo/edk/platform/random.h"
#include "mojo/edk/platform/simple_platform_shared_buffer.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::platform::CreateSimplePlatformSharedBuffer;
using mojo::platform::CreateSimplePlatformSharedBufferFromPlatformHandle;
using mojo::platform::PlatformSharedBuffer;
using mojo::platform::ScopedPlatformHandle;
using mojo::util::MakeUnique;
using mojo::util::RefPtr;

namespace mojo {
namespace embedder {

namespace {

class SimplePlatformSupport final : public PlatformSupport {
 public:
  SimplePlatformSupport() {}
  ~SimplePlatformSupport() override {}

  void GetCryptoRandomBytes(void* bytes, size_t num_bytes) override {
    platform::GetCryptoRandomBytes(bytes, num_bytes);
  }

  util::RefPtr<platform::PlatformSharedBuffer> CreateSharedBuffer(
      size_t num_bytes) override {
    return CreateSimplePlatformSharedBuffer(num_bytes);
  }

  util::RefPtr<platform::PlatformSharedBuffer> CreateSharedBufferFromHandle(
      size_t num_bytes,
      platform::ScopedPlatformHandle platform_handle) override {
    return CreateSimplePlatformSharedBufferFromPlatformHandle(
        num_bytes, std::move(platform_handle));
  }

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(SimplePlatformSupport);
};

}  // namespace

std::unique_ptr<PlatformSupport> CreateSimplePlatformSupport() {
  return MakeUnique<SimplePlatformSupport>();
}

}  // namespace embedder
}  // namespace mojo

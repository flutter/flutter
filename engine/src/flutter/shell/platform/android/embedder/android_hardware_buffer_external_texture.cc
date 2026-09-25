// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder/android_hardware_buffer_external_texture.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

AndroidHardwareBufferExternalTexture::AndroidHardwareBufferExternalTexture(
    std::shared_ptr<JniDelegate> jni_delegate,
    const FlutterEngineProcTable& proc_table)
    : jni_delegate_(std::move(jni_delegate)), embedder_api_(proc_table) {}

AndroidHardwareBufferExternalTexture::~AndroidHardwareBufferExternalTexture() =
    default;

bool AndroidHardwareBufferExternalTexture::RegisterTexture(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_id) {
  TRACE_EVENT0("flutter",
               "AndroidHardwareBufferExternalTexture::RegisterTexture");
  if (engine == nullptr || embedder_api_.RegisterExternalTexture == nullptr) {
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    textures_[texture_id].registered = true;
  }
  return embedder_api_.RegisterExternalTexture(engine, texture_id) == kSuccess;
}

bool AndroidHardwareBufferExternalTexture::UnregisterTexture(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_id) {
  TRACE_EVENT0("flutter",
               "AndroidHardwareBufferExternalTexture::UnregisterTexture");
  if (engine == nullptr || embedder_api_.UnregisterExternalTexture == nullptr) {
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    textures_.erase(texture_id);
  }
  return embedder_api_.UnregisterExternalTexture(engine, texture_id) ==
         kSuccess;
}

bool AndroidHardwareBufferExternalTexture::MarkFrameAvailable(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_id) {
  TRACE_EVENT0("flutter",
               "AndroidHardwareBufferExternalTexture::MarkFrameAvailable");
  if (engine == nullptr ||
      embedder_api_.MarkExternalTextureFrameAvailable == nullptr) {
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = textures_.find(texture_id);
    if (it == textures_.end() || !it->second.registered) {
      return false;
    }
  }
  return embedder_api_.MarkExternalTextureFrameAvailable(engine, texture_id) ==
         kSuccess;
}

void AndroidHardwareBufferExternalTexture::SetTextureUvTransform(
    int64_t texture_id,
    const FlutterTransformation& uv_transform) {
  std::lock_guard<std::mutex> lock(mutex_);
  textures_[texture_id].uv_transform = uv_transform;
}

void AndroidHardwareBufferExternalTexture::SetTextureYcbcrConversionInfo(
    int64_t texture_id,
    const FlutterVulkanYcbcrConversionInfo& ycbcr_info) {
  std::lock_guard<std::mutex> lock(mutex_);
  TextureRecord& record = textures_[texture_id];
  record.has_ycbcr_info = true;
  record.ycbcr_info = ycbcr_info;
  record.ycbcr_info.struct_size = sizeof(FlutterVulkanYcbcrConversionInfo);
}

void AndroidHardwareBufferExternalTexture::SetOpenGLTextureName(
    int64_t texture_id,
    uint32_t target,
    uint32_t gl_texture_name) {
  std::lock_guard<std::mutex> lock(mutex_);
  TextureRecord& record = textures_[texture_id];
  record.gl_target = target;
  record.gl_texture_name = gl_texture_name;
}

bool AndroidHardwareBufferExternalTexture::AcquireVulkanExternalTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterVulkanExternalTexture* texture_out) {
  TRACE_EVENT0("flutter",
               "AndroidHardwareBufferExternalTexture::"
               "AcquireVulkanExternalTextureFrame");
  if (texture_out == nullptr || jni_delegate_ == nullptr) {
    return false;
  }

  uint32_t buffer_width = static_cast<uint32_t>(width);
  uint32_t buffer_height = static_cast<uint32_t>(height);
  const uintptr_t ahb_handle = jni_delegate_->AcquireLatestHardwareBuffer(
      texture_id, &buffer_width, &buffer_height);
  if (ahb_handle == 0) {
    return false;
  }

  const FlutterVulkanYcbcrConversionInfo* ycbcr_ptr = nullptr;
  FlutterTransformation uv_transform = {1.0, 0.0, 0.0, 0.0, 1.0,
                                        0.0, 0.0, 0.0, 1.0};
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = textures_.find(texture_id);
    if (it == textures_.end() || !it->second.registered) {
      jni_delegate_->ReleaseHardwareBuffer(ahb_handle);
      return false;
    }
    uv_transform = it->second.uv_transform;
    if (it->second.has_ycbcr_info) {
      ycbcr_ptr = &it->second.ycbcr_info;
    }
    active_buffer_leases_++;
  }

  auto* lease = new BufferLeaseContext{this, jni_delegate_, ahb_handle};

  *texture_out = {};
  texture_out->struct_size = sizeof(FlutterVulkanExternalTexture);
  texture_out->type = kFlutterVulkanExternalTextureTypeAHardwareBuffer;
  texture_out->hardware_buffer =
      reinterpret_cast<FlutterAHardwareBufferHandle>(ahb_handle);
  texture_out->width = buffer_width > 0 ? buffer_width : width;
  texture_out->height = buffer_height > 0 ? buffer_height : height;
  texture_out->ycbcr_conversion_info = ycbcr_ptr;
  texture_out->uv_transform = uv_transform;
  texture_out->user_data = lease;
  texture_out->destruction_callback =
      &AndroidHardwareBufferExternalTexture::OnReleaseHardwareBufferLease;
  return true;
}

bool AndroidHardwareBufferExternalTexture::AcquireOpenGLExternalTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterOpenGLTexture2* texture_out) {
  TRACE_EVENT0("flutter",
               "AndroidHardwareBufferExternalTexture::"
               "AcquireOpenGLExternalTextureFrame");
  if (texture_out == nullptr) {
    return false;
  }

  std::lock_guard<std::mutex> lock(mutex_);
  auto it = textures_.find(texture_id);
  if (it == textures_.end() || !it->second.registered ||
      it->second.gl_texture_name == 0) {
    return false;
  }

  *texture_out = {};
  texture_out->struct_size = sizeof(FlutterOpenGLTexture2);
  texture_out->target = it->second.gl_target;
  texture_out->name = it->second.gl_texture_name;
  texture_out->format = 0x8058;  // GL_RGBA8
  texture_out->width = width;
  texture_out->height = height;
  texture_out->uv_transform = it->second.uv_transform;
  return true;
}

size_t AndroidHardwareBufferExternalTexture::GetActiveBufferLeaseCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return active_buffer_leases_;
}

void AndroidHardwareBufferExternalTexture::OnReleaseHardwareBufferLease(
    void* user_data) {
  TRACE_EVENT0(
      "flutter",
      "AndroidHardwareBufferExternalTexture::OnReleaseHardwareBufferLease");
  auto* lease = static_cast<BufferLeaseContext*>(user_data);
  if (lease == nullptr) {
    return;
  }
  if (lease->jni_delegate != nullptr && lease->hardware_buffer_handle != 0) {
    lease->jni_delegate->ReleaseHardwareBuffer(lease->hardware_buffer_handle);
  }
  if (lease->owner != nullptr) {
    std::lock_guard<std::mutex> lock(lease->owner->mutex_);
    if (lease->owner->active_buffer_leases_ > 0) {
      lease->owner->active_buffer_leases_--;
    }
  }
  delete lease;
}

}  // namespace flutter

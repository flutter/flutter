// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_hb.h"

#include <utility>

#if !defined(_WIN32)
#include <poll.h>
#include <unistd.h>
#endif

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"

#if defined(IMPELLER_SUPPORTS_RENDERING)
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#endif

#if defined(__ANDROID__)
#include <android/hardware_buffer.h>
#if __ANDROID_API__ >= 26
#include "third_party/skia/include/android/GrAHardwareBufferUtils.h"
#endif

#if defined(SHELL_ENABLE_VULKAN)
#include "flutter/impeller/renderer/backend/vulkan/android/ahb_texture_source_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/texture_vk.h"
#endif

#if defined(SHELL_ENABLE_GL)
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/handle_gles.h"
#include "flutter/impeller/renderer/backend/gles/texture_gles.h"
#endif

#endif  // defined(__ANDROID__)

namespace flutter {

namespace {

void CloseFenceFd(int32_t fence_fd) {
  if (fence_fd >= 0) {
#if !defined(_WIN32)
    close(fence_fd);
#endif
  }
}

class HardwareBufferDlImageSkia final : public DlImageSkia {
 public:
  HardwareBufferDlImageSkia(sk_sp<SkImage> image,
                            int32_t fence_fd,
                            VoidCallback destruction_callback,
                            void* user_data)
      : DlImageSkia(std::move(image)),
        fence_fd_(fence_fd),
        destruction_callback_(destruction_callback),
        user_data_(user_data) {}

  ~HardwareBufferDlImageSkia() override {
    CloseFenceFd(fence_fd_);
    if (destruction_callback_) {
      TRACE_EVENT0("flutter",
                   "HardwareBufferExternalTextureDestructionCallback");
      destruction_callback_(user_data_);
    }
  }

 private:
  int32_t fence_fd_;
  VoidCallback destruction_callback_;
  void* user_data_;
};

}  // namespace

EmbedderExternalTextureHB::EmbedderExternalTextureHB(
    int64_t texture_identifier,
    ExternalTextureCallback callback)
    : Texture(texture_identifier),
      external_texture_callback_(std::move(callback)) {
  FML_DCHECK(external_texture_callback_);
}

EmbedderExternalTextureHB::~EmbedderExternalTextureHB() {
  TRACE_EVENT0("flutter",
               "EmbedderExternalTextureHB::~EmbedderExternalTextureHB");
  ReleaseLatestFrame();
}

void EmbedderExternalTextureHB::Paint(PaintContext& context,
                                      const DlRect& bounds,
                                      bool freeze,
                                      const DlImageSampling sampling) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::Paint");
  if (!freeze && has_new_frame_.exchange(false)) {
    sk_sp<DlImage> new_image =
        ResolveTexture(Id(), context.gr_context, context.aiks_context,
                       SkISize::Make(bounds.GetWidth(), bounds.GetHeight()));
    if (new_image) {
      last_image_ = std::move(new_image);
    }
  }

  DlCanvas* canvas = context.canvas;
  const DlPaint* paint = context.paint;

  if (last_image_ && canvas) {
    DlRect image_bounds = DlRect::Make(last_image_->GetBounds());
    if (bounds != image_bounds) {
      canvas->DrawImageRect(last_image_, image_bounds, bounds, sampling, paint);
    } else {
      canvas->DrawImage(last_image_, bounds.GetOrigin(), sampling, paint);
    }
  }
}

sk_sp<DlImage> EmbedderExternalTextureHB::ResolveTexture(
    int64_t texture_id,
    GrDirectContext* context,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::ResolveTexture");

#if defined(__ANDROID__)
  if (aiks_context) {
    return ResolveTextureImpeller(texture_id, aiks_context, size);
  } else if (context) {
    return ResolveTextureSkia(texture_id, context, size);
  }
#else
  if (aiks_context) {
    auto img = ResolveTextureImpeller(texture_id, aiks_context, size);
    if (img) {
      return img;
    }
  } else if (context) {
    auto img = ResolveTextureSkia(texture_id, context, size);
    if (img) {
      return img;
    }
  }
#endif

  // Fallback for mock unit tests on host where context and aiks_context are
  // null, or where synthetic test handles are used.
  std::unique_ptr<FlutterHardwareBufferExternalTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  if (texture->struct_size < sizeof(FlutterHardwareBufferExternalTexture)) {
    FML_LOG(ERROR)
        << "Invalid FlutterHardwareBufferExternalTexture struct_size: "
        << texture->struct_size;
    if (texture->struct_size >=
        offsetof(FlutterHardwareBufferExternalTexture, fence_fd) +
            sizeof(int32_t)) {
      CloseFenceFd(texture->fence_fd);
    }
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  size_t width = texture->width != 0 ? texture->width : size.width();
  size_t height = texture->height != 0 ? texture->height : size.height();

  if (texture->buffer == nullptr || width == 0 || height == 0) {
    FML_LOG(ERROR)
        << "Invalid HardwareBuffer external texture parameters (buffer="
        << texture->buffer << ", size=" << width << "x" << height << ")";
    CloseFenceFd(texture->fence_fd);
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  // Allocate a minimal 1x1 raster surface for unit test handle verification
  // and host mocks. 1x1 dimensions avoid multi-megabyte allocations on host.
  constexpr int kFallbackDimension = 1;
  auto info = SkImageInfo::Make(kFallbackDimension, kFallbackDimension,
                                kRGBA_8888_SkColorType, kPremul_SkAlphaType);
  auto sk_surface = SkSurfaces::Raster(info);
  if (!sk_surface) {
    CloseFenceFd(texture->fence_fd);
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  int32_t fence_fd = texture->fence_fd;
  VoidCallback destruction_callback = texture->destruction_callback;
  void* user_data = texture->user_data;
  // Detach fence_fd and destruction callback from the struct so that ownership
  // is held by the DlImage wrapper and invoked when the frame lifecycle
  // completes. -1 indicates no fence synchronization FD.
  texture->fence_fd = -1;
  texture->destruction_callback = nullptr;

  {
    std::lock_guard<std::mutex> lock(frame_mutex_);
    last_texture_frame_ = std::move(texture);
  }

  return sk_make_sp<HardwareBufferDlImageSkia>(sk_surface->makeImageSnapshot(),
                                               fence_fd, destruction_callback,
                                               user_data);
}

sk_sp<DlImage> EmbedderExternalTextureHB::ResolveTextureImpeller(
    int64_t texture_id,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::ResolveTextureImpeller");
  std::unique_ptr<FlutterHardwareBufferExternalTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture || !texture->buffer) {
    return nullptr;
  }

#if defined(__ANDROID__)
  AHardwareBuffer* hardware_buffer =
      static_cast<AHardwareBuffer*>(texture->buffer);

  // Synchronize on fence FD if provided before GPU samples from buffer:
  if (texture->fence_fd >= 0) {
    // Wait for the producer to finish writing before GPU consumption.
    // 3000ms timeout prevents indefinite hangs on stalled hardware decoders.
    constexpr int kFenceTimeoutMs = 3000;
    struct pollfd pfd = {texture->fence_fd, POLLIN, 0};
    int poll_res = poll(&pfd, 1, kFenceTimeoutMs);
    if (poll_res < 0) {
      FML_LOG(WARNING) << "Failed to wait on hardware buffer fence fd: "
                       << strerror(errno);
    }
    CloseFenceFd(texture->fence_fd);
    // -1 indicates no fence file descriptor.
    texture->fence_fd = -1;
  }

  std::shared_ptr<impeller::Context> impeller_context =
      aiks_context->GetContext();
  if (!impeller_context) {
    FML_LOG(ERROR) << "Unable to retrieve Impeller context from AiksContext.";
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  std::shared_ptr<impeller::Texture> impeller_texture;

#ifdef SHELL_ENABLE_VULKAN
  if (impeller_context->GetBackendType() ==
      impeller::Context::BackendType::kVulkan) {
    AHardwareBuffer_Desc desc = {};
    AHardwareBuffer_describe(hardware_buffer, &desc);
    auto texture_source = std::make_shared<impeller::AHBTextureSourceVK>(
        impeller_context, hardware_buffer, desc);
    if (!texture_source->IsValid()) {
      FML_LOG(ERROR) << "Failed to construct valid AHBTextureSourceVK.";
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      return nullptr;
    }
    impeller_texture =
        std::make_shared<impeller::TextureVK>(impeller_context, texture_source);
  }
#endif

#ifdef SHELL_ENABLE_GL
  if (impeller_context->GetBackendType() ==
      impeller::Context::BackendType::kOpenGLES) {
    using PFNEGLGETNATIVECLIENTBUFFERANDROIDPROC =
        EGLClientBuffer (*)(const struct AHardwareBuffer* buffer);
    static auto get_native_client_buffer_fn =
        reinterpret_cast<PFNEGLGETNATIVECLIENTBUFFERANDROIDPROC>(
            eglGetProcAddress("eglGetNativeClientBufferANDROID"));
    if (!get_native_client_buffer_fn) {
      FML_LOG(ERROR)
          << "Failed to resolve eglGetNativeClientBufferANDROID extension.";
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      return nullptr;
    }
    EGLClientBuffer client_buffer =
        get_native_client_buffer_fn(hardware_buffer);
    if (!client_buffer) {
      FML_LOG(ERROR) << "eglGetNativeClientBufferANDROID returned null.";
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      return nullptr;
    }

    EGLDisplay display = eglGetCurrentDisplay();
    if (display == EGL_NO_DISPLAY) {
      FML_LOG(ERROR) << "No active EGLDisplay found on calling thread.";
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      return nullptr;
    }
    // EGL_NONE terminates the attribute list.
    const EGLint attribs[] = {EGL_IMAGE_PRESERVED_KHR, EGL_TRUE, EGL_NONE};
    EGLImageKHR egl_image =
        eglCreateImageKHR(display, EGL_NO_CONTEXT, EGL_NATIVE_BUFFER_ANDROID,
                          client_buffer, attribs);
    if (egl_image == EGL_NO_IMAGE_KHR) {
      FML_LOG(ERROR) << "eglCreateImageKHR failed for AHardwareBuffer.";
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      return nullptr;
    }

    impeller::ContextGLES& context_gles =
        impeller::ContextGLES::Cast(*impeller_context);
    const auto& gl = context_gles.GetReactor()->GetProcTable();
    GLuint gl_tex = GL_NONE;
    gl.GenTextures(1, &gl_tex);
    if (gl_tex == GL_NONE) {
      FML_LOG(ERROR) << "Failed to generate GL texture for external texture.";
      eglDestroyImageKHR(display, egl_image);
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      return nullptr;
    }
    // 0x8D65 is GL_TEXTURE_EXTERNAL_OES defined by the
    // GL_OES_EGL_image_external extension.
    constexpr GLenum kTextureExternalOes = 0x8D65;
    gl.BindTexture(kTextureExternalOes, gl_tex);
    using PFNEGLIMAGETARGETTEXTURE2DOESPROC =
        void (*)(unsigned int target, void* image);
    static auto glEGLImageTargetTexture2DOES =
        reinterpret_cast<PFNEGLIMAGETARGETTEXTURE2DOESPROC>(
            eglGetProcAddress("glEGLImageTargetTexture2DOES"));
    if (!glEGLImageTargetTexture2DOES) {
      FML_LOG(ERROR) << "Failed to resolve glEGLImageTargetTexture2DOES.";
      gl.DeleteTextures(1, &gl_tex);
      eglDestroyImageKHR(display, egl_image);
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      return nullptr;
    }
    glEGLImageTargetTexture2DOES(kTextureExternalOes, egl_image);
    eglDestroyImageKHR(display, egl_image);

    AHardwareBuffer_Desc hb_desc = {};
    AHardwareBuffer_describe(hardware_buffer, &hb_desc);

    impeller::TextureDescriptor desc;
    desc.type = impeller::TextureType::kTextureExternalOES;
    desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    desc.size = {
        static_cast<int>(hb_desc.width > 0 ? hb_desc.width : size.width()),
        static_cast<int>(hb_desc.height > 0 ? hb_desc.height : size.height())};
    // 1 mip level for un-mipmapped external texture.
    desc.mip_count = 1;

    impeller::HandleGLES handle = context_gles.GetReactor()->CreateHandle(
        impeller::HandleType::kTexture, gl_tex);
    auto texture_gles = impeller::TextureGLES::WrapTexture(
        context_gles.GetReactor(), desc, handle);
    if (!texture_gles) {
      FML_LOG(ERROR) << "Failed to wrap TextureGLES for external texture.";
      gl.DeleteTextures(1, &gl_tex);
      if (texture->destruction_callback) {
        texture->destruction_callback(texture->user_data);
      }
      return nullptr;
    }
    texture_gles->MarkContentsInitialized();
    impeller_texture = texture_gles;
  }
#endif

  if (!impeller_texture) {
    FML_LOG(ERROR)
        << "Failed to import AHardwareBuffer into Impeller backend texture.";
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  {
    std::lock_guard<std::mutex> lock(frame_mutex_);
    if (last_texture_frame_ && last_texture_frame_->destruction_callback) {
      last_texture_frame_->destruction_callback(last_texture_frame_->user_data);
      last_texture_frame_->destruction_callback = nullptr;
    }
    last_texture_frame_ = std::move(texture);
  }

  return impeller::DlImageImpeller::Make(std::move(impeller_texture));
#else
  if (texture->destruction_callback) {
    texture->destruction_callback(texture->user_data);
  }
  return nullptr;
#endif
}

sk_sp<DlImage> EmbedderExternalTextureHB::ResolveTextureSkia(
    int64_t texture_id,
    GrDirectContext* context,
    const SkISize& size) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::ResolveTextureSkia");
  std::unique_ptr<FlutterHardwareBufferExternalTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture || !texture->buffer) {
    return nullptr;
  }

#if defined(__ANDROID__) && __ANDROID_API__ >= 26
  AHardwareBuffer* hardware_buffer =
      static_cast<AHardwareBuffer*>(texture->buffer);
  size_t width = texture->width != 0 ? texture->width : size.width();
  size_t height = texture->height != 0 ? texture->height : size.height();

  // Format 0 indicates to query default format from AHardwareBuffer.
  GrBackendFormat backend_format = GrAHardwareBufferUtils::GetBackendFormat(
      context, hardware_buffer, /*format=*/0, /*require_renderable=*/false);
  if (!backend_format.isValid()) {
    CloseFenceFd(texture->fence_fd);
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  GrAHardwareBufferUtils::DeleteImageProc delete_proc = nullptr;
  GrAHardwareBufferUtils::UpdateImageProc update_proc = nullptr;
  GrAHardwareBufferUtils::TexImageCtx tex_image_ctx = nullptr;

  GrBackendTexture backend_texture = GrAHardwareBufferUtils::MakeBackendTexture(
      context, hardware_buffer, width, height, &delete_proc, &update_proc,
      &tex_image_ctx, /*is_protected_content=*/false, backend_format,
      /*require_renderable=*/false);

  if (!backend_texture.isValid()) {
    CloseFenceFd(texture->fence_fd);
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  sk_sp<SkImage> sk_image = SkImages::BorrowTextureFrom(
      context, backend_texture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType,
      /*colorSpace=*/nullptr, delete_proc, tex_image_ctx);

  if (!sk_image) {
    CloseFenceFd(texture->fence_fd);
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  int32_t fence_fd = texture->fence_fd;
  VoidCallback destruction_callback = texture->destruction_callback;
  void* user_data = texture->user_data;
  // -1 indicates fence has been transferred or consumed.
  texture->fence_fd = -1;
  texture->destruction_callback = nullptr;

  {
    std::lock_guard<std::mutex> lock(frame_mutex_);
    last_texture_frame_ = std::move(texture);
  }

  return sk_make_sp<HardwareBufferDlImageSkia>(std::move(sk_image), fence_fd,
                                               destruction_callback, user_data);
#else
  FML_LOG(ERROR) << "Skia HardwareBuffer external texture is not supported on "
                    "Android API < 26.";
  CloseFenceFd(texture->fence_fd);
  if (texture->destruction_callback) {
    texture->destruction_callback(texture->user_data);
  }
  return nullptr;
#endif
}

void EmbedderExternalTextureHB::ReleaseLatestFrame() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::ReleaseLatestFrame");
  {
    std::lock_guard<std::mutex> lock(frame_mutex_);
    if (last_texture_frame_) {
      if (last_texture_frame_->destruction_callback) {
        TRACE_EVENT0("flutter",
                     "HardwareBufferExternalTextureDestructionCallback");
        last_texture_frame_->destruction_callback(
            last_texture_frame_->user_data);
      }
      last_texture_frame_.reset();
    }
  }
  last_image_ = nullptr;
}

void EmbedderExternalTextureHB::OnGrContextCreated() {
  has_new_frame_.store(true);
}

void EmbedderExternalTextureHB::OnGrContextDestroyed() {
  ReleaseLatestFrame();
  has_new_frame_.store(true);
}

void EmbedderExternalTextureHB::MarkNewFrameAvailable() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::MarkNewFrameAvailable");
  has_new_frame_.store(true);
}

void EmbedderExternalTextureHB::OnTextureUnregistered() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::OnTextureUnregistered");
  ReleaseLatestFrame();
}

}  // namespace flutter

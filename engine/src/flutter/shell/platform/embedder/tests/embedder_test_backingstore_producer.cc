// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_backingstore_producer.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/pixel_formats.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GpuTypes.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"

#include <cstdlib>
#include <memory>
#include <utility>

#ifdef SHELL_ENABLE_VULKAN
#include "third_party/skia/include/gpu/ganesh/vk/GrVkBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkTypes.h"
#endif  // SHELL_ENABLE_VULKAN

#ifdef SHELL_ENABLE_METAL
#include "third_party/skia/include/gpu/ganesh/mtl/GrMtlBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/mtl/GrMtlTypes.h"
#endif  // SHELL_ENABLE_METAL

#ifdef SHELL_ENABLE_GL
#include "flutter/testing/test_gl_surface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLTypes.h"
#endif  // SHELL_ENABLE_GL

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace flutter {
namespace testing {

EmbedderTestBackingStoreProducer::EmbedderTestBackingStoreProducer(
    sk_sp<GrDirectContext> context,
    RenderTargetType type,
    FlutterSoftwarePixelFormat software_pixfmt)
    : context_(std::move(context)),
      type_(type),
      software_pixfmt_(software_pixfmt)
#ifdef SHELL_ENABLE_GL
      ,
      test_egl_context_(nullptr)
#endif
#ifdef SHELL_ENABLE_METAL
      ,
      test_metal_context_(std::make_unique<TestMetalContext>())
#endif
#ifdef SHELL_ENABLE_VULKAN
      ,
      test_vulkan_context_(nullptr)
#endif
{
  if (type == RenderTargetType::kSoftwareBuffer &&
      software_pixfmt_ != kFlutterSoftwarePixelFormatNative32) {
    FML_LOG(ERROR) << "Expected pixel format to be the default "
                      "(kFlutterSoftwarePixelFormatNative32) when"
                      "backing store producer should produce deprecated v1 "
                      "software backing "
                      "stores.";
    std::abort();
  };
}

EmbedderTestBackingStoreProducer::~EmbedderTestBackingStoreProducer() = default;

#ifdef SHELL_ENABLE_GL
void EmbedderTestBackingStoreProducer::SetEGLContext(
    std::shared_ptr<TestEGLContext> context) {
  // Ideally this would be set in the constructor, however we can't do that
  // without introducing different constructors depending on different graphics
  // APIs, which is a bit ugly.
  test_egl_context_ = std::move(context);
}
#endif

bool EmbedderTestBackingStoreProducer::Create(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* renderer_out) {
  switch (type_) {
    case RenderTargetType::kSoftwareBuffer:
      return CreateSoftware(config, renderer_out);
    case RenderTargetType::kSoftwareBuffer2:
      return CreateSoftware2(config, renderer_out);
#ifdef SHELL_ENABLE_GL
    case RenderTargetType::kOpenGLTexture:
      return CreateTexture(config, renderer_out);
    case RenderTargetType::kOpenGLFramebuffer:
      return CreateFramebuffer(config, renderer_out);
    case RenderTargetType::kOpenGLSurface:
      return CreateSurface(config, renderer_out);
#endif
#ifdef SHELL_ENABLE_METAL
    case RenderTargetType::kMetalTexture:
      return CreateMTLTexture(config, renderer_out);
#endif
#ifdef SHELL_ENABLE_VULKAN
    case RenderTargetType::kVulkanImage:
      return CreateVulkanImage(config, renderer_out);
#endif
    default:
      return false;
  }
}

bool EmbedderTestBackingStoreProducer::CreateFramebuffer(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
#ifdef SHELL_ENABLE_GL
  const auto image_info =
      SkImageInfo::MakeN32Premul(config->size.width, config->size.height);

  auto surface =
      SkSurfaces::RenderTarget(context_.get(),               // context
                               skgpu::Budgeted::kNo,         // budgeted
                               image_info,                   // image info
                               1,                            // sample count
                               kBottomLeft_GrSurfaceOrigin,  // surface origin
                               nullptr,  // surface properties
                               false     // mipmaps
      );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create render target for compositor layer.";
    return false;
  }

  GrBackendRenderTarget render_target = SkSurfaces::GetBackendRenderTarget(
      surface.get(), SkSurfaces::BackendHandleAccess::kDiscardWrite);

  if (!render_target.isValid()) {
    FML_LOG(ERROR) << "Backend render target was invalid.";
    return false;
  }

  GrGLFramebufferInfo framebuffer_info = {};
  if (!GrBackendRenderTargets::GetGLFramebufferInfo(render_target,
                                                    &framebuffer_info)) {
    FML_LOG(ERROR) << "Could not access backend framebuffer info.";
    return false;
  }

  auto user_data = new UserData(surface);

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = user_data;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.target = framebuffer_info.fFormat;
  backing_store_out->open_gl.framebuffer.name = framebuffer_info.fFBOID;
  backing_store_out->open_gl.framebuffer.user_data = user_data;
  backing_store_out->open_gl.framebuffer.destruction_callback =
      [](void* user_data) { delete reinterpret_cast<UserData*>(user_data); };

  return true;
#else
  return false;
#endif
}

bool EmbedderTestBackingStoreProducer::CreateTexture(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
#ifdef SHELL_ENABLE_GL
  const auto image_info =
      SkImageInfo::MakeN32Premul(config->size.width, config->size.height);

  auto surface =
      SkSurfaces::RenderTarget(context_.get(),               // context
                               skgpu::Budgeted::kNo,         // budgeted
                               image_info,                   // image info
                               1,                            // sample count
                               kBottomLeft_GrSurfaceOrigin,  // surface origin
                               nullptr,  // surface properties
                               false     // mipmaps
      );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create render target for compositor layer.";
    return false;
  }

  GrBackendTexture render_texture = SkSurfaces::GetBackendTexture(
      surface.get(), SkSurfaces::BackendHandleAccess::kDiscardWrite);

  if (!render_texture.isValid()) {
    FML_LOG(ERROR) << "Backend render texture was invalid.";
    return false;
  }

  GrGLTextureInfo texture_info = {};
  if (!GrBackendTextures::GetGLTextureInfo(render_texture, &texture_info)) {
    FML_LOG(ERROR) << "Could not access backend texture info.";
    return false;
  }

  auto user_data = new UserData(surface);

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = user_data;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeTexture;
  backing_store_out->open_gl.texture.target = texture_info.fTarget;
  backing_store_out->open_gl.texture.name = texture_info.fID;
  backing_store_out->open_gl.texture.format = texture_info.fFormat;
  backing_store_out->open_gl.texture.user_data = user_data;
  backing_store_out->open_gl.texture.destruction_callback =
      [](void* user_data) { delete reinterpret_cast<UserData*>(user_data); };

  return true;
#else
  return false;
#endif
}

bool EmbedderTestBackingStoreProducer::CreateSurface(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
#ifdef SHELL_ENABLE_GL
  FML_CHECK(test_egl_context_);
  auto surface = std::make_unique<TestGLOnscreenOnlySurface>(
      test_egl_context_,
      SkSize::Make(config->size.width, config->size.height).toRound());

  auto make_current = [](void* user_data, bool* invalidate_state) -> bool {
    *invalidate_state = false;
    return reinterpret_cast<UserData*>(user_data)->gl_surface->MakeCurrent();
  };

  auto clear_current = [](void* user_data, bool* invalidate_state) -> bool {
    *invalidate_state = false;
    // return
    // reinterpret_cast<GLUserData*>(user_data)->gl_surface->ClearCurrent();
    return true;
  };

  auto destruction_callback = [](void* user_data) {
    delete reinterpret_cast<UserData*>(user_data);
  };

  auto sk_surface = surface->GetOnscreenSurface();

  auto user_data = new UserData(sk_surface, nullptr, std::move(surface));

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = user_data;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeSurface;
  backing_store_out->open_gl.surface.user_data = user_data;
  backing_store_out->open_gl.surface.make_current_callback = make_current;
  backing_store_out->open_gl.surface.clear_current_callback = clear_current;
  backing_store_out->open_gl.surface.destruction_callback =
      destruction_callback;

  return true;
#else
  return false;
#endif
}

bool EmbedderTestBackingStoreProducer::CreateSoftware(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  auto surface = SkSurfaces::Raster(
      SkImageInfo::MakeN32Premul(config->size.width, config->size.height));

  if (!surface) {
    FML_LOG(ERROR)
        << "Could not create the render target for compositor layer.";
    return false;
  }

  SkPixmap pixmap;
  if (!surface->peekPixels(&pixmap)) {
    FML_LOG(ERROR) << "Could not peek pixels of pixmap.";
    return false;
  }

  auto user_data = new UserData(surface);

  backing_store_out->type = kFlutterBackingStoreTypeSoftware;
  backing_store_out->user_data = user_data;
  backing_store_out->software.allocation = pixmap.addr();
  backing_store_out->software.row_bytes = pixmap.rowBytes();
  backing_store_out->software.height = pixmap.height();
  backing_store_out->software.user_data = user_data;
  backing_store_out->software.destruction_callback = [](void* user_data) {
    delete reinterpret_cast<UserData*>(user_data);
  };

  return true;
}

bool EmbedderTestBackingStoreProducer::CreateSoftware2(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  const auto color_info = getSkColorInfo(software_pixfmt_);
  if (!color_info) {
    return false;
  }

  auto surface = SkSurfaces::Raster(SkImageInfo::Make(
      SkISize::Make(config->size.width, config->size.height), *color_info));
  if (!surface) {
    FML_LOG(ERROR)
        << "Could not create the render target for compositor layer.";
    return false;
  }

  SkPixmap pixmap;
  if (!surface->peekPixels(&pixmap)) {
    FML_LOG(ERROR) << "Could not peek pixels of pixmap.";
    return false;
  }

  auto user_data = new UserData(surface);

  backing_store_out->type = kFlutterBackingStoreTypeSoftware2;
  backing_store_out->user_data = user_data;
  backing_store_out->software2.struct_size =
      sizeof(FlutterSoftwareBackingStore2);
  backing_store_out->software2.allocation = pixmap.writable_addr();
  backing_store_out->software2.row_bytes = pixmap.rowBytes();
  backing_store_out->software2.height = pixmap.height();
  backing_store_out->software2.user_data = user_data;
  backing_store_out->software2.destruction_callback = [](void* user_data) {
    delete reinterpret_cast<UserData*>(user_data);
  };
  backing_store_out->software2.pixel_format = software_pixfmt_;

  return true;
}

bool EmbedderTestBackingStoreProducer::CreateMTLTexture(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
#ifdef SHELL_ENABLE_METAL
  // TODO(gw280): Use SkSurfaces::RenderTarget instead of generating our
  // own MTLTexture and wrapping it.
  auto surface_size = SkISize::Make(config->size.width, config->size.height);
  auto texture_info = test_metal_context_->CreateMetalTexture(surface_size);

  GrMtlTextureInfo skia_texture_info;
  skia_texture_info.fTexture.reset(SkCFSafeRetain(texture_info.texture));
  GrBackendTexture backend_texture =
      GrBackendTextures::MakeMtl(surface_size.width(), surface_size.height(),
                                 skgpu::Mipmapped::kNo, skia_texture_info);

  sk_sp<SkSurface> surface = SkSurfaces::WrapBackendTexture(
      context_.get(), backend_texture, kTopLeft_GrSurfaceOrigin, 1,
      kBGRA_8888_SkColorType, nullptr, nullptr);

  if (!surface) {
    FML_LOG(ERROR) << "Could not create Skia surface from a Metal texture.";
    return false;
  }

  backing_store_out->type = kFlutterBackingStoreTypeMetal;
  backing_store_out->user_data = surface.get();
  backing_store_out->metal.texture.texture = texture_info.texture;
  // The balancing unref is in the destruction callback.
  surface->ref();
  backing_store_out->metal.struct_size = sizeof(FlutterMetalBackingStore);
  backing_store_out->metal.texture.user_data = surface.get();
  backing_store_out->metal.texture.destruction_callback = [](void* user_data) {
    reinterpret_cast<SkSurface*>(user_data)->unref();
  };

  return true;
#else
  return false;
#endif
}

bool EmbedderTestBackingStoreProducer::CreateVulkanImage(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
#ifdef SHELL_ENABLE_VULKAN
  if (!test_vulkan_context_) {
    test_vulkan_context_ = fml::MakeRefCounted<TestVulkanContext>();
  }

  auto surface_size = SkISize::Make(config->size.width, config->size.height);
  TestVulkanImage* test_image = new TestVulkanImage(
      std::move(test_vulkan_context_->CreateImage(surface_size).value()));

  GrVkImageInfo image_info = {
      .fImage = test_image->GetImage(),
      .fImageTiling = VK_IMAGE_TILING_OPTIMAL,
      .fImageLayout = VK_IMAGE_LAYOUT_UNDEFINED,
      .fFormat = VK_FORMAT_R8G8B8A8_UNORM,
      .fImageUsageFlags = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
                          VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
                          VK_IMAGE_USAGE_TRANSFER_DST_BIT |
                          VK_IMAGE_USAGE_SAMPLED_BIT,
      .fSampleCount = 1,
      .fLevelCount = 1,
  };
  auto backend_texture = GrBackendTextures::MakeVk(
      surface_size.width(), surface_size.height(), image_info);

  SkSurfaceProps surface_properties(0, kUnknown_SkPixelGeometry);

  SkSurfaces::TextureReleaseProc release_vktexture = [](void* user_data) {
    delete reinterpret_cast<TestVulkanImage*>(user_data);
  };

  sk_sp<SkSurface> surface = SkSurfaces::WrapBackendTexture(
      context_.get(),            // context
      backend_texture,           // back-end texture
      kTopLeft_GrSurfaceOrigin,  // surface origin
      1,                         // sample count
      kRGBA_8888_SkColorType,    // color type
      SkColorSpace::MakeSRGB(),  // color space
      &surface_properties,       // surface properties
      release_vktexture,         // texture release proc
      test_image                 // release context
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create Skia surface from Vulkan image.";
    return false;
  }
  backing_store_out->type = kFlutterBackingStoreTypeVulkan;

  FlutterVulkanImage* image = new FlutterVulkanImage();
  image->image = reinterpret_cast<uint64_t>(image_info.fImage);
  image->format = VK_FORMAT_R8G8B8A8_UNORM;
  backing_store_out->vulkan.image = image;

  // Collect all allocated resources in the destruction_callback.
  {
    auto user_data = new UserData(surface, image);
    backing_store_out->user_data = user_data;
    backing_store_out->vulkan.user_data = user_data;
    backing_store_out->vulkan.destruction_callback = [](void* user_data) {
      UserData* d = reinterpret_cast<UserData*>(user_data);
      delete d->image;
      delete d;
    };
  }

  return true;
#else
  return false;
#endif
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(bugprone-unchecked-optional-access)

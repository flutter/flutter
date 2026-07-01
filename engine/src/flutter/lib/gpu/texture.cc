// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/texture.h"

#include <cstring>

#include "flutter/lib/gpu/formats.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "fml/make_copyable.h"
#include "fml/mapping.h"
#include "impeller/core/allocator.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/command_queue.h"
#include "impeller/renderer/context.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/display_list/image/dl_image.h"      // nogncheck
#include "impeller/display_list/dl_image_impeller.h"  // nogncheck
#endif
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_wrappable.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, Texture);

Texture::Texture(std::shared_ptr<impeller::Texture> texture)
    : texture_(std::move(texture)) {}

Texture::~Texture() = default;

std::shared_ptr<impeller::Texture> Texture::GetTexture() {
  return texture_;
}

// Returns the size in pixels of the given dimension at `mip_level`, clamped
// at 1, matching standard mip-chain semantics. The Dart-side helper
// `Texture.getMipLevelSizeInBytes` uses the same `max(1, dim >> level)`
// formula in pixel-count form; if either is updated, both must be kept in
// sync.
static int32_t MipDimensionAtLevel(int32_t base_dimension, uint32_t mip_level) {
  const int32_t shifted = base_dimension >> mip_level;
  return shifted > 0 ? shifted : 1;
}

// Records a blit-pass that copies `source_bytes` into the given mip level and
// slice of `texture` on `context`, then submits the command buffer. Returns
// true if the encode and submit both succeed. The actual GPU upload may
// complete asynchronously after this call returns.
static bool EncodeAndSubmitOverwrite(
    impeller::Context& context,
    const std::shared_ptr<impeller::Texture>& texture,
    const std::shared_ptr<impeller::DeviceBuffer>& staging_buffer,
    size_t source_length,
    impeller::IRect destination_region,
    uint32_t mip_level,
    uint32_t slice) {
  auto command_buffer = context.CreateCommandBuffer();
  if (!command_buffer) {
    FML_LOG(ERROR) << "Failed to create command buffer for texture overwrite.";
    return false;
  }
  auto blit_pass = command_buffer->CreateBlitPass();
  if (!blit_pass) {
    FML_LOG(ERROR) << "Failed to create blit pass for texture overwrite.";
    return false;
  }
  impeller::BufferView buffer_view(staging_buffer,
                                   impeller::Range(0, source_length));
  if (!blit_pass->AddCopy(std::move(buffer_view), texture, destination_region,
                          /*label=*/"Texture.overwrite", mip_level, slice)) {
    return false;
  }
  if (!blit_pass->EncodeCommands()) {
    return false;
  }
  return context.GetCommandQueue()->Submit({std::move(command_buffer)}).ok();
}

bool Texture::Overwrite(Context& gpu_context,
                        const tonic::DartByteData& source_bytes,
                        uint32_t mip_level,
                        uint32_t slice) {
  const uint8_t* data = static_cast<const uint8_t*>(source_bytes.data());
  const size_t length = source_bytes.length_in_bytes();

  auto& impeller_context = gpu_context.GetContext();
  auto staging_buffer =
      impeller_context.GetResourceAllocator()->CreateBufferWithCopy(data,
                                                                    length);
  if (!staging_buffer) {
    FML_LOG(ERROR) << "Failed to allocate staging buffer for texture "
                      "overwrite.";
    return false;
  }

  // Compute the destination region for the requested mip level. The
  // BlitPass::AddCopy validation requires the region to fit within the base
  // texture size, and the actual GPU copy uses this rectangle as the
  // destination on the chosen mip level. The same `max(1, dim >> level)`
  // formula is used by `Texture.getMipLevelSizeInBytes` on the Dart side; if
  // either is updated, both must be kept in sync.
  const impeller::ISize base_size = texture_->GetSize();
  const impeller::IRect destination_region = impeller::IRect::MakeXYWH(
      0, 0, MipDimensionAtLevel(base_size.width, mip_level),
      MipDimensionAtLevel(base_size.height, mip_level));

  // For the GLES backend, command queue submission just flushes the reactor,
  // which needs to happen on the raster thread.
  if (impeller_context.GetBackendType() ==
      impeller::Context::BackendType::kOpenGLES) {
    auto dart_state = flutter::UIDartState::Current();
    auto& task_runners = dart_state->GetTaskRunners();
    auto context_shared = gpu_context.GetContextShared();
    task_runners.GetRasterTaskRunner()->PostTask(fml::MakeCopyable(
        [context_shared, texture = texture_, staging_buffer, length,
         destination_region, mip_level, slice]() mutable {
          if (!EncodeAndSubmitOverwrite(*context_shared, texture,
                                        staging_buffer, length,
                                        destination_region, mip_level, slice)) {
            FML_LOG(ERROR) << "Failed to encode texture overwrite blit on the "
                              "raster thread.";
          }
          context_shared->DisposeThreadLocalCachedResources();
        }));
    return true;
  }

  if (!EncodeAndSubmitOverwrite(impeller_context, texture_, staging_buffer,
                                length, destination_region, mip_level, slice)) {
    return false;
  }
  impeller_context.DisposeThreadLocalCachedResources();
  return true;
}

#if IMPELLER_SUPPORTS_RENDERING
// Extracts the impeller::Texture that backs the ui.Image `image_wrapper`.
// Returns nullptr if the image is not backed by a Flutter GPU compatible
// texture, for example a non-Impeller image or a deferred image (from
// Picture.toImageSync) that has not finished rasterizing yet.
static std::shared_ptr<impeller::Texture> GetTextureFromImage(
    Context* gpu_context,
    Dart_Handle image_wrapper) {
  if (gpu_context == nullptr || Dart_IsNull(image_wrapper)) {
    return nullptr;
  }
  // A `ui.Image` wraps the private `_Image` native field holder.
  Dart_Handle inner = Dart_GetField(image_wrapper, tonic::ToDart("_image"));
  if (Dart_IsError(inner) || Dart_IsNull(inner)) {
    return nullptr;
  }
  auto* canvas_image =
      tonic::DartConverter<flutter::CanvasImage*>::FromDart(inner);
  if (!canvas_image) {
    return nullptr;
  }
  sk_sp<flutter::DlImage> dl_image = canvas_image->image();
  if (!dl_image) {
    return nullptr;
  }
  const impeller::DlImageImpeller* impeller_image = dl_image->asImpellerImage();
  if (!impeller_image) {
    return nullptr;
  }
  return impeller_image->GetImpellerTexture(gpu_context->GetContextShared());
}
#endif

Dart_Handle Texture::AsImage() const {
  // DlImageImpeller isn't compiled in builds with Impeller disabled. If
  // Impeller is disabled, it's impossible to get here anyhow, so just ifdef it
  // out.
#if IMPELLER_SUPPORTS_RENDERING
  auto image = flutter::CanvasImage::Create();
  auto dl_image = impeller::DlImageImpeller::Make(texture_);
  image->set_image(dl_image);
  auto wrapped = image->CreateOuterWrapping();
  return wrapped;
#else
  return Dart_Null();
#endif
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

bool InternalFlutterGpu_Texture_Initialize(Dart_Handle wrapper,
                                           flutter::gpu::Context* gpu_context,
                                           int storage_mode,
                                           int format,
                                           int width,
                                           int height,
                                           int sample_count,
                                           int texture_type,
                                           bool enable_render_target_usage,
                                           bool enable_shader_read_usage,
                                           bool enable_shader_write_usage,
                                           int mip_level_count) {
  if (mip_level_count < 1) {
    return false;
  }
  impeller::TextureDescriptor desc;
  desc.storage_mode = flutter::gpu::ToImpellerStorageMode(storage_mode);
  desc.size = {width, height};
  desc.format = flutter::gpu::ToImpellerPixelFormat(format);
  desc.mip_count = static_cast<size_t>(mip_level_count);
  desc.usage = {};
  if (enable_render_target_usage) {
    desc.usage |= impeller::TextureUsage::kRenderTarget;
  }
  if (enable_shader_read_usage) {
    desc.usage |= impeller::TextureUsage::kShaderRead;
  }
  if (enable_shader_write_usage) {
    desc.usage |= impeller::TextureUsage::kShaderWrite;
  }
  switch (sample_count) {
    case 1:
      desc.sample_count = impeller::SampleCount::kCount1;
      break;
    case 4:
      desc.sample_count = impeller::SampleCount::kCount4;
      break;
    default:
      return false;
  }
  desc.type = static_cast<impeller::TextureType>(texture_type);
  if (!impeller::IsMultisampleCapable(desc.type) &&
      desc.sample_count != impeller::SampleCount::kCount1) {
    return false;
  }

  auto texture =
      gpu_context->GetContext().GetResourceAllocator()->CreateTexture(desc,
                                                                      true);
  if (!texture) {
    FML_LOG(ERROR) << "Failed to create texture.";
    return false;
  }

  auto res = fml::MakeRefCounted<flutter::gpu::Texture>(std::move(texture));
  res->AssociateWithDartWrapper(wrapper);

  return true;
}

bool InternalFlutterGpu_Texture_Overwrite(flutter::gpu::Texture* texture,
                                          flutter::gpu::Context* gpu_context,
                                          Dart_Handle source_byte_data,
                                          int mip_level,
                                          int slice) {
  if (mip_level < 0 || slice < 0) {
    return false;
  }
  return texture->Overwrite(*gpu_context, tonic::DartByteData(source_byte_data),
                            static_cast<uint32_t>(mip_level),
                            static_cast<uint32_t>(slice));
}

Dart_Handle InternalFlutterGpu_Texture_AsImage(flutter::gpu::Texture* wrapper) {
  return wrapper->AsImage();
}

Dart_Handle InternalFlutterGpu_Texture_ImageTextureInfo(
    flutter::gpu::Context* gpu_context,
    Dart_Handle image_wrapper) {
#if IMPELLER_SUPPORTS_RENDERING
  auto texture = flutter::gpu::GetTextureFromImage(gpu_context, image_wrapper);
  if (!texture) {
    return Dart_NewTypedData(Dart_TypedData_kInt32, 0);
  }
  const impeller::TextureDescriptor& desc = texture->GetTextureDescriptor();
  const impeller::TextureUsageMask usage = desc.usage;

  // Layout must match the parsing in the Dart `Texture._fromImage`.
  int32_t values[10];
  values[0] = static_cast<int32_t>(
      flutter::gpu::FromImpellerStorageMode(desc.storage_mode));
  values[1] =
      static_cast<int32_t>(flutter::gpu::FromImpellerPixelFormat(desc.format));
  values[2] = static_cast<int32_t>(desc.size.width);
  values[3] = static_cast<int32_t>(desc.size.height);
  values[4] = static_cast<int32_t>(desc.sample_count);
  // The Flutter GPU `TextureType` enum mirrors `impeller::TextureType`.
  values[5] = static_cast<int32_t>(desc.type);
  values[6] = (usage & impeller::TextureUsage::kRenderTarget) ? 1 : 0;
  values[7] = (usage & impeller::TextureUsage::kShaderRead) ? 1 : 0;
  values[8] = (usage & impeller::TextureUsage::kShaderWrite) ? 1 : 0;
  values[9] = static_cast<int32_t>(desc.mip_count);

  const intptr_t length = sizeof(values) / sizeof(values[0]);
  Dart_Handle list = Dart_NewTypedData(Dart_TypedData_kInt32, length);
  if (Dart_IsError(list)) {
    return list;
  }
  Dart_TypedData_Type type;
  void* data = nullptr;
  intptr_t data_length = 0;
  Dart_Handle acquire_result =
      Dart_TypedDataAcquireData(list, &type, &data, &data_length);
  if (Dart_IsError(acquire_result)) {
    return acquire_result;
  }
  std::memcpy(data, values, sizeof(values));
  Dart_TypedDataReleaseData(list);
  return list;
#else
  return Dart_NewTypedData(Dart_TypedData_kInt32, 0);
#endif
}

bool InternalFlutterGpu_Texture_InitializeFromImage(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    Dart_Handle image_wrapper) {
#if IMPELLER_SUPPORTS_RENDERING
  auto texture = flutter::gpu::GetTextureFromImage(gpu_context, image_wrapper);
  if (!texture) {
    return false;
  }
  auto res = fml::MakeRefCounted<flutter::gpu::Texture>(std::move(texture));
  res->AssociateWithDartWrapper(wrapper);
  return true;
#else
  return false;
#endif
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/texture.h"

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
#include "impeller/display_list/dl_image_impeller.h"  // nogncheck
#endif
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

void Texture::SetCoordinateSystem(
    impeller::TextureCoordinateSystem coordinate_system) {
  texture_->SetCoordinateSystem(coordinate_system);
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

size_t Texture::GetBytesPerTexel() {
  return impeller::BytesPerPixelForPixelFormat(
      texture_->GetTextureDescriptor().format);
}

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
                                           int coordinate_system,
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

  texture->SetCoordinateSystem(
      flutter::gpu::ToImpellerTextureCoordinateSystem(coordinate_system));

  auto res = fml::MakeRefCounted<flutter::gpu::Texture>(std::move(texture));
  res->AssociateWithDartWrapper(wrapper);

  return true;
}

void InternalFlutterGpu_Texture_SetCoordinateSystem(
    flutter::gpu::Texture* wrapper,
    int coordinate_system) {
  return wrapper->SetCoordinateSystem(
      flutter::gpu::ToImpellerTextureCoordinateSystem(coordinate_system));
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

extern int InternalFlutterGpu_Texture_BytesPerTexel(
    flutter::gpu::Texture* wrapper) {
  return wrapper->GetBytesPerTexel();
}

Dart_Handle InternalFlutterGpu_Texture_AsImage(flutter::gpu::Texture* wrapper) {
  return wrapper->AsImage();
}

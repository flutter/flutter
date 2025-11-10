// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/texture.h"

#include "flutter/lib/gpu/formats.h"
#include "flutter/lib/ui/painting/image.h"
#include "fml/make_copyable.h"
#include "fml/mapping.h"
#include "impeller/core/allocator.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture.h"
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

bool Texture::Overwrite(Context& gpu_context,
                        const tonic::DartByteData& source_bytes) {
  const uint8_t* data = static_cast<const uint8_t*>(source_bytes.data());
  auto copy = std::vector<uint8_t>(data, data + source_bytes.length_in_bytes());
  // Texture::SetContents is a bit funky right now. It takes a shared_ptr of a
  // mapping and we're forced to copy here.
  auto mapping = std::make_shared<fml::DataMapping>(copy);

  // For the GLES backend, command queue submission just flushes the reactor,
  // which needs to happen on the raster thread.
  if (gpu_context.GetContext().GetBackendType() ==
      impeller::Context::BackendType::kOpenGLES) {
    auto dart_state = flutter::UIDartState::Current();
    auto& task_runners = dart_state->GetTaskRunners();

    task_runners.GetRasterTaskRunner()->PostTask(
        fml::MakeCopyable([texture = texture_, mapping = mapping]() mutable {
          if (!texture->SetContents(mapping)) {
            FML_LOG(ERROR) << "Failed to set texture contents.";
          }
        }));
  }

  if (!texture_->SetContents(mapping)) {
    return false;
  }
  gpu_context.GetContext().DisposeThreadLocalCachedResources();
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
                                           bool enable_shader_write_usage) {
  impeller::TextureDescriptor desc;
  desc.storage_mode = flutter::gpu::ToImpellerStorageMode(storage_mode);
  desc.size = {width, height};
  desc.format = flutter::gpu::ToImpellerPixelFormat(format);
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
                                          Dart_Handle source_byte_data) {
  return texture->Overwrite(*gpu_context,
                            tonic::DartByteData(source_byte_data));
}

extern int InternalFlutterGpu_Texture_BytesPerTexel(
    flutter::gpu::Texture* wrapper) {
  return wrapper->GetBytesPerTexel();
}

Dart_Handle InternalFlutterGpu_Texture_AsImage(flutter::gpu::Texture* wrapper) {
  return wrapper->AsImage();
}

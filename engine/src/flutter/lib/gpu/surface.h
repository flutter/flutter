// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_SURFACE_H_
#define FLUTTER_LIB_GPU_SURFACE_H_

#include <atomic>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "dart_api.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/lib/gpu/command_buffer.h"
#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/gpu/texture.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/context.h"

namespace flutter {
namespace gpu {

class Surface : public RefCountedDartWrappable<Surface> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Surface);

 public:
  Surface(std::shared_ptr<impeller::Context> context,
          impeller::ISize size,
          impeller::PixelFormat format);

  ~Surface() override;

  int AcquireNextFrame(Dart_Handle texture_wrapper);

  Dart_Handle PresentFrame(size_t texture_index, CommandBuffer& command_buffer);

  void DiscardFrame(size_t texture_index);

  Dart_Handle GetCurrentImage() const;

  std::optional<std::string> Resize(impeller::ISize size);

  size_t GetBackingTextureCount() const;

 private:
  struct TextureRecord {
    TextureRecord(std::shared_ptr<impeller::Texture> texture,
                  sk_sp<DlImage> image,
                  impeller::ISize size,
                  impeller::PixelFormat format);

    std::shared_ptr<impeller::Texture> texture;
    sk_sp<DlImage> image;
    impeller::ISize size;
    impeller::PixelFormat format;
    bool acquired = false;
    std::atomic_bool producer_pending = false;
  };

  std::shared_ptr<TextureRecord> CreateTextureRecord() const;

  bool IsReusable(const std::shared_ptr<TextureRecord>& record,
                  size_t index) const;

  void PruneTextureRecords();

  Dart_Handle CreateImage(const sk_sp<DlImage>& image) const;

  std::shared_ptr<impeller::Context> context_;
  impeller::ISize size_;
  impeller::PixelFormat format_;
  std::vector<std::shared_ptr<TextureRecord>> records_;
  std::optional<size_t> current_index_;

  FML_DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_Surface_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    int width,
    int height,
    int format);

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Surface_AcquireNextFrame(
    flutter::gpu::Surface* wrapper,
    Dart_Handle texture_wrapper);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_Surface_PresentFrame(
    flutter::gpu::Surface* wrapper,
    int texture_index,
    flutter::gpu::CommandBuffer* command_buffer);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_Surface_DiscardFrame(
    flutter::gpu::Surface* wrapper,
    int texture_index);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_Surface_GetCurrentImage(
    flutter::gpu::Surface* wrapper);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_Surface_Resize(
    flutter::gpu::Surface* wrapper,
    int width,
    int height);

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Surface_GetBackingTextureCount(
    flutter::gpu::Surface* wrapper);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_SURFACE_H_

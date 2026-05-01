// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_PROVIDER_H_
#define FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_PROVIDER_H_

#include <utility>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/display_list/skia/dl_sk_canvas.h"
#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"

#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

class DlPixelData : public SkRefCnt {
 public:
  virtual ~DlPixelData() = default;

  virtual const uint32_t* addr32(int x, int y) const = 0;
  virtual size_t width() const = 0;
  virtual size_t height() const = 0;
  virtual void write(const std::string& path) const = 0;
};

class DlSurfaceInstance {
 public:
  virtual ~DlSurfaceInstance() = default;

  /// Clear the entire surface to the indicated color.
  virtual void Clear(const DlColor& color) = 0;

  /// Return a DlCanvas instance that renders to this surface. Note that
  /// actual execution of the rendering calls are not guaranteed until the
  /// FlushSubmitCpuSync method is called.
  virtual DlCanvas* GetCanvas() = 0;

  /// Render the indicated DisplayList to the surface. Note that the
  /// commands may be enqueued by this call and will be rendered at some
  /// time in the future, but the caller must call FlushSubmitCpuSync to
  /// be sure they are done being rendered.
  ///
  /// In some cases this may be faster than using:
  ///   GetCanvas().DrawDisplayList(display_list);
  virtual void RenderDisplayList(const sk_sp<DisplayList>& display_list) = 0;

  /// Ensure that all outstanding calls executed on the DlCanvas instance
  /// are rendered to the surface.
  virtual void FlushSubmitCpuSync() = 0;

  /// Store a snapshot of this Surface to the file indicated by the filename.
  virtual bool SnapshotToFile(std::string& filename) const = 0;

  /// The size of the underlying surface.
  DlISize GetSize() const { return DlISize(width(), height()); }

  /// The width of the underlying surface.
  virtual int width() const = 0;

  /// The height of the underlying surface.
  virtual int height() const = 0;

  /// Return a pointer to an underlying SkSurface if the image instance
  /// has one.
  /// THIS METHOD IS DEPRECATED AND ONLY USED IN DL_RENDERING_UNITTESTS.
  virtual sk_sp<SkSurface> sk_surface() { return nullptr; }
};

class DlSurfaceProvider {
 public:
  enum PixelFormat {
    kN32Premul,
    k565,
  };

  enum class BackendType {
    kSkiaSoftware,
    kSkiaOpenGL,
    kSkiaMetal,
    kImpellerMetal,
    kImpellerMetalSDF,
  };

  static SkImageInfo MakeInfo(PixelFormat format, int w, int h) {
    switch (format) {
      case kN32Premul:
        return SkImageInfo::MakeN32Premul(w, h);
      case k565:
        return SkImageInfo::Make(SkISize::Make(w, h), kRGB_565_SkColorType,
                                 kOpaque_SkAlphaType);
    }
    FML_DCHECK(false);
  }

  static std::string BackendName(BackendType type);
  static std::unique_ptr<DlSurfaceProvider> Create(BackendType backend_type);

  virtual ~DlSurfaceProvider() = default;

  virtual const std::string GetBackendName() const = 0;
  virtual BackendType GetBackendType() const = 0;
  virtual bool SupportsPixelFormat(PixelFormat format) const = 0;
  virtual bool SupportsImpeller() const { return false; }
  virtual bool InitializeSurface(size_t width,
                                 size_t height,
                                 PixelFormat format = kN32Premul) = 0;
  virtual std::shared_ptr<DlSurfaceInstance> GetPrimarySurface() const = 0;
  virtual std::shared_ptr<DlSurfaceInstance> MakeOffscreenSurface(
      size_t width,
      size_t height,
      PixelFormat format = kN32Premul) const = 0;

  virtual sk_sp<DlPixelData> ImpellerSnapshot(const sk_sp<DisplayList>& list,
                                              int width,
                                              int height) const {
    return nullptr;
  }
  virtual sk_sp<DlImage> MakeImpellerImage(const sk_sp<DisplayList>& list,
                                           int width,
                                           int height) const {
    return nullptr;
  }

 protected:
  DlSurfaceProvider() = default;

 private:
  static std::unique_ptr<DlSurfaceProvider> CreateSkiaSoftware();
  static std::unique_ptr<DlSurfaceProvider> CreateSkiaOpenGL();
  static std::unique_ptr<DlSurfaceProvider> CreateSkiaMetal();
  static std::unique_ptr<DlSurfaceProvider> CreateImpellerMetal();
  static std::unique_ptr<DlSurfaceProvider> CreateImpellerMetalSDF();
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SURFACE_PROVIDER_H_

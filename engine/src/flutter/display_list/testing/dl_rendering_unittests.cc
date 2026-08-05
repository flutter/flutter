// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <utility>

#include "absl/strings/str_split.h"

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_op_flags.h"
#include "flutter/display_list/dl_sampling_options.h"
#include "flutter/display_list/dl_text_skia.h"
#include "flutter/display_list/effects/color_filters/dl_matrix_color_filter.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/geometry/dl_geometry_conversions.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/display_list/skia/dl_sk_conversions.h"
#include "flutter/display_list/testing/dl_test_snippets.h"
#include "flutter/display_list/testing/dl_test_surface_provider.h"
#include "flutter/display_list/utils/dl_comparable.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/math.h"
#include "flutter/testing/display_list_testing.h"
#include "flutter/testing/testing.h"
#ifdef IMPELLER_SUPPORTS_RENDERING
#include "flutter/impeller/display_list/dl_text_impeller.h"  // nogncheck
#include "flutter/impeller/typographer/backends/skia/text_frame_skia.h"  // nogncheck
#endif  // IMPELLER_SUPPORTS_RENDERING

#include "flutter/third_party/skia/include/core/SkColor.h"
#include "flutter/third_party/skia/include/core/SkColorFilter.h"
#include "flutter/txt/src/txt/platform.h"

namespace flutter {
namespace testing {

constexpr uint32_t kTestWidth = 200;
constexpr uint32_t kTestHeight = 200;
constexpr uint32_t kRenderWidth = 100;
constexpr uint32_t kRenderHeight = 100;
constexpr DlScalar kRenderLeft = (kTestWidth - kRenderWidth) / 2;
constexpr DlScalar kRenderTop = (kTestHeight - kRenderHeight) / 2;
constexpr DlScalar kRenderRight = kRenderLeft + kRenderWidth;
constexpr DlScalar kRenderBottom = kRenderTop + kRenderHeight;
constexpr DlScalar kRenderCenterX = (kRenderLeft + kRenderRight) / 2;
constexpr DlScalar kRenderCenterY = (kRenderTop + kRenderBottom) / 2;
constexpr DlScalar kRenderRadius = std::min(kRenderWidth, kRenderHeight) / 2.0;
constexpr DlScalar kRenderCornerRadius = kRenderRadius / 5.0;
constexpr DlScalar kTextFontHeight = kRenderHeight * 0.33f;

constexpr DlRect kTestBounds2 = DlRect::MakeWH(kTestWidth, kTestHeight);
const DlPoint kTestCenter2 = kTestBounds2.GetCenter();
constexpr DlRect kRenderBounds =
    DlRect::MakeLTRB(kRenderLeft, kRenderTop, kRenderRight, kRenderBottom);

// The tests try 3 miter limit values, 0.0, 4.0 (the default), and 10.0
// These values will allow us to construct a diamond that spans the
// width or height of the render box and still show the miter for 4.0
// and 10.0.
// These values were discovered by drawing a diamond path in Skia fiddle
// and then playing with the cross-axis size until the miter was about
// as large as it could get before it got cut off.

// The X offsets which will be used for tall vertical diamonds are
// expressed in terms of the rendering height to obtain the proper angle
constexpr DlScalar kMiterExtremeDiamondOffsetX = kRenderHeight * 0.04;
constexpr DlScalar kMiter10DiamondOffsetX = kRenderHeight * 0.051;
constexpr DlScalar kMiter4DiamondOffsetX = kRenderHeight * 0.14;

// The Y offsets which will be used for long horizontal diamonds are
// expressed in terms of the rendering width to obtain the proper angle
constexpr DlScalar kMiterExtremeDiamondOffsetY = kRenderWidth * 0.04;
constexpr DlScalar kMiter10DiamondOffsetY = kRenderWidth * 0.051;
constexpr DlScalar kMiter4DiamondOffsetY = kRenderWidth * 0.14;

// Render 3 vertical and horizontal diamonds each
// designed to break at the tested miter limits
// 0.0, 4.0 and 10.0
// Center is biased by 0.5 to include more pixel centers in the
// thin miters
constexpr DlScalar kXOffset0 = kRenderCenterX + 0.5;
constexpr DlScalar kXOffsetL1 = kXOffset0 - kMiter4DiamondOffsetX;
constexpr DlScalar kXOffsetL2 = kXOffsetL1 - kMiter10DiamondOffsetX;
constexpr DlScalar kXOffsetL3 = kXOffsetL2 - kMiter10DiamondOffsetX;
constexpr DlScalar kXOffsetR1 = kXOffset0 + kMiter4DiamondOffsetX;
constexpr DlScalar kXOffsetR2 = kXOffsetR1 + kMiterExtremeDiamondOffsetX;
constexpr DlScalar kXOffsetR3 = kXOffsetR2 + kMiterExtremeDiamondOffsetX;
constexpr DlPoint kVerticalMiterDiamondPoints[] = {
    // Vertical diamonds:
    //  M10   M4  Mextreme
    //   /\   /|\   /\       top of RenderBounds
    //  /  \ / | \ /  \              to
    // <----X--+--X---->         RenderCenter
    //  \  / \ | / \  /              to
    //   \/   \|/   \/      bottom of RenderBounds
    // clang-format off
    DlPoint(kXOffsetL3, kRenderCenterY),
    DlPoint(kXOffsetL2, kRenderTop),
    DlPoint(kXOffsetL1, kRenderCenterY),
    DlPoint(kXOffset0,  kRenderTop),
    DlPoint(kXOffsetR1, kRenderCenterY),
    DlPoint(kXOffsetR2, kRenderTop),
    DlPoint(kXOffsetR3, kRenderCenterY),
    DlPoint(kXOffsetR2, kRenderBottom),
    DlPoint(kXOffsetR1, kRenderCenterY),
    DlPoint(kXOffset0,  kRenderBottom),
    DlPoint(kXOffsetL1, kRenderCenterY),
    DlPoint(kXOffsetL2, kRenderBottom),
    DlPoint(kXOffsetL3, kRenderCenterY),
    // clang-format on
};
const int kVerticalMiterDiamondPointCount =
    sizeof(kVerticalMiterDiamondPoints) /
    sizeof(kVerticalMiterDiamondPoints[0]);

constexpr DlScalar kYOffset0 = kRenderCenterY + 0.5;
constexpr DlScalar kYOffsetU1 = kXOffset0 - kMiter4DiamondOffsetY;
constexpr DlScalar kYOffsetU2 = kYOffsetU1 - kMiter10DiamondOffsetY;
constexpr DlScalar kYOffsetU3 = kYOffsetU2 - kMiter10DiamondOffsetY;
constexpr DlScalar kYOffsetD1 = kXOffset0 + kMiter4DiamondOffsetY;
constexpr DlScalar kYOffsetD2 = kYOffsetD1 + kMiterExtremeDiamondOffsetY;
constexpr DlScalar kYOffsetD3 = kYOffsetD2 + kMiterExtremeDiamondOffsetY;
const DlPoint kHorizontalMiterDiamondPoints[] = {
    // Horizontal diamonds
    // Same configuration as Vertical diamonds above but
    // rotated 90 degrees
    // clang-format off
    DlPoint(kRenderCenterX, kYOffsetU3),
    DlPoint(kRenderLeft,    kYOffsetU2),
    DlPoint(kRenderCenterX, kYOffsetU1),
    DlPoint(kRenderLeft,    kYOffset0),
    DlPoint(kRenderCenterX, kYOffsetD1),
    DlPoint(kRenderLeft,    kYOffsetD2),
    DlPoint(kRenderCenterX, kYOffsetD3),
    DlPoint(kRenderRight,   kYOffsetD2),
    DlPoint(kRenderCenterX, kYOffsetD1),
    DlPoint(kRenderRight,   kYOffset0),
    DlPoint(kRenderCenterX, kYOffsetU1),
    DlPoint(kRenderRight,   kYOffsetU2),
    DlPoint(kRenderCenterX, kYOffsetU3),
    // clang-format on
};
const int kHorizontalMiterDiamondPointCount =
    (sizeof(kHorizontalMiterDiamondPoints) /
     sizeof(kHorizontalMiterDiamondPoints[0]));

namespace {
constexpr uint8_t toC(DlScalar fComp) {
  return round(fComp * 255);
}

constexpr uint32_t PremultipliedArgb(const DlColor& color) {
  if (color.isOpaque()) {
    return color.argb();
  }
  DlScalar f = color.getAlphaF();
  return (color.argb() & 0xFF000000) |      //
         toC(color.getRedF() * f) << 16 |   //
         toC(color.getGreenF() * f) << 8 |  //
         toC(color.getBlueF() * f);
}
}  // namespace

static void DrawCheckerboard(DlCanvas* canvas) {
  DlPaint p0, p1;
  p0.setDrawStyle(DlDrawStyle::kFill);
  p0.setColor(DlColor(0xff00fe00));  // off-green
  p1.setDrawStyle(DlDrawStyle::kFill);
  p1.setColor(DlColor::kBlue());
  // Some pixels need some transparency for DstIn testing
  p1.setAlpha(128);
  int cbdim = 5;
  int width = canvas->GetBaseLayerDimensions().width;
  int height = canvas->GetBaseLayerDimensions().height;
  for (int y = 0; y < width; y += cbdim) {
    for (int x = 0; x < height; x += cbdim) {
      DlPaint& cellp = ((x + y) & 1) == 0 ? p0 : p1;
      canvas->DrawRect(DlRect::MakeXYWH(x, y, cbdim, cbdim), cellp);
    }
  }
}

static std::shared_ptr<DlImageColorSource> MakeColorSource(
    const sk_sp<DlImage>& image) {
  return std::make_shared<DlImageColorSource>(image,                //
                                              DlTileMode::kRepeat,  //
                                              DlTileMode::kRepeat,  //
                                              DlImageSampling::kLinear);
}

// Used to show "INFO" warnings about tests that are omitted on certain
// backends, but only once for the entire test run to avoid warning spam
class OncePerBackendWarning {
 public:
  explicit OncePerBackendWarning(const std::string& warning)
      : warning_(warning) {}

  void warn(const std::string& name) {
    if (warnings_sent_.find(name) == warnings_sent_.end()) {
      warnings_sent_.insert(name);
      FML_LOG(INFO) << warning_ << " on " << name;
    }
  }

 private:
  std::string warning_;
  std::set<std::string> warnings_sent_;
};

// A class to specify how much tolerance to allow in bounds estimates.
// For some attributes, the machinery must make some conservative
// assumptions as to the extent of the bounds, but some of our test
// parameters do not produce bounds that expand by the full conservative
// estimates. This class provides a number of tweaks to apply to the
// pixel bounds to account for the conservative factors.
//
// An instance is passed along through the methods and if any test adds
// a paint attribute or other modifier that will cause a more conservative
// estimate for bounds, it can modify the factors here to account for it.
// Ideally, all tests will be executed with geometry that will trigger
// the conservative cases anyway and all attributes will be combined with
// other attributes that make their output more predictable, but in those
// cases where a given test sequence cannot really provide attributes to
// demonstrate the worst case scenario, they can modify these factors to
// avoid false bounds overflow notifications.
class BoundsTolerance {
 public:
  BoundsTolerance() = default;
  BoundsTolerance(const BoundsTolerance&) = default;

  BoundsTolerance addBoundsPadding(DlScalar bounds_pad_x,
                                   DlScalar bounds_pad_y) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.bounds_pad_ += DlPoint(bounds_pad_x, bounds_pad_y);
    return copy;
  }

  BoundsTolerance mulScale(DlScalar scale_x, DlScalar scale_y) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.scale_ *= DlPoint(scale_x, scale_y);
    return copy;
  }

  BoundsTolerance addAbsolutePadding(DlScalar absolute_pad_x,
                                     DlScalar absolute_pad_y) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.absolute_pad_ += DlPoint(absolute_pad_x, absolute_pad_y);
    return copy;
  }

  BoundsTolerance addPostClipPadding(DlScalar absolute_pad_x,
                                     DlScalar absolute_pad_y) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.clip_pad_ += DlPoint(absolute_pad_x, absolute_pad_y);
    return copy;
  }

  BoundsTolerance addDiscreteOffset(DlScalar discrete_offset) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.discrete_offset_ += discrete_offset;
    return copy;
  }

  BoundsTolerance clip(DlRect clip) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.clip_ = copy.clip_.IntersectionOrEmpty(clip);
    return copy;
  }

  static DlRect Scale(const DlRect& rect, const DlPoint& scales) {
    DlScalar outset_x = rect.GetWidth() * (scales.x - 1);
    DlScalar outset_y = rect.GetHeight() * (scales.y - 1);
    return rect.Expand(outset_x, outset_y);
  }

  bool overflows(DlIRect pix_bounds,
                 int worst_bounds_pad_x,
                 int worst_bounds_pad_y) const {
    DlRect allowed = DlRect::Make(pix_bounds);
    allowed = allowed.Expand(bounds_pad_.x, bounds_pad_.y);
    allowed = Scale(allowed, scale_);
    allowed = allowed.Expand(absolute_pad_.x, absolute_pad_.y);
    allowed = allowed.IntersectionOrEmpty(clip_);
    allowed = allowed.Expand(clip_pad_.x, clip_pad_.y);
    DlIRect rounded = DlIRect::RoundOut(allowed);
    int pad_left = std::max(0, pix_bounds.GetLeft() - rounded.GetLeft());
    int pad_top = std::max(0, pix_bounds.GetTop() - rounded.GetTop());
    int pad_right = std::max(0, pix_bounds.GetRight() - rounded.GetRight());
    int pad_bottom = std::max(0, pix_bounds.GetBottom() - rounded.GetBottom());
    int allowed_pad_x = std::max(pad_left, pad_right);
    int allowed_pad_y = std::max(pad_top, pad_bottom);
    if (worst_bounds_pad_x > allowed_pad_x ||
        worst_bounds_pad_y > allowed_pad_y) {
      FML_LOG(ERROR) << "acceptable bounds padding: "  //
                     << allowed_pad_x << ", " << allowed_pad_y;
    }
    return (worst_bounds_pad_x > allowed_pad_x ||
            worst_bounds_pad_y > allowed_pad_y);
  }

  DlScalar discrete_offset() const { return discrete_offset_; }

  bool operator==(BoundsTolerance const& other) const {
    return bounds_pad_ == other.bounds_pad_ && scale_ == other.scale_ &&
           absolute_pad_ == other.absolute_pad_ && clip_ == other.clip_ &&
           clip_pad_ == other.clip_pad_ &&
           discrete_offset_ == other.discrete_offset_;
  }

 private:
  DlPoint bounds_pad_ = {0, 0};
  DlPoint scale_ = {1, 1};
  DlPoint absolute_pad_ = {0, 0};
  DlRect clip_ = DlRect::MakeLTRB(-1E9, -1E9, 1E9, 1E9);
  DlPoint clip_pad_ = {0, 0};

  DlScalar discrete_offset_ = 0;
};

class RenderEnvironment;
struct DlSetupContext {
  const RenderEnvironment& env;
  DlCanvas* canvas;
  DlPaint& paint;
};
struct DlRenderContext {
  const RenderEnvironment& env;
  DlCanvas* canvas;
  const DlPaint& paint;
};

using DlSetup = const std::function<void(const DlSetupContext&)>;
using DlRenderer = const std::function<void(const DlRenderContext&)>;
static const DlSetup kEmptyDlSetup = [](const DlSetupContext&) {};
static const DlRenderer kEmptyDlRenderer = [](const DlRenderContext&) {};

using PixelFormat = DlSurfaceProvider::PixelFormat;
using BackendType = DlSurfaceProvider::BackendType;

struct RenderResult {
  static RenderResult Make(const std::shared_ptr<DlSurfaceInstance>& surface) {
    return Make(surface->SnapshotToPixelData());
  }

  static RenderResult Make(const std::shared_ptr<DlPixelData>& data) {
    return Make(data, DlRect::MakeWH(data->width(), data->height()));
  }

  static RenderResult Make(const std::shared_ptr<DlPixelData>& data,
                           const DlRect& bounds) {
    return {
        .pixel_data = data,
        .render_bounds = bounds,
    };
  }

  std::shared_ptr<DlPixelData> pixel_data;
  DlRect render_bounds;
};

struct RenderJobInfo {
  int width = kTestWidth;
  int height = kTestHeight;
  DlColor bg = DlColor::kTransparent();
  DlScalar scale = 1.0f;
  DlScalar opacity = 1.0f;
};

struct JobRenderer {
  virtual void Render(const RenderEnvironment& env,
                      DlCanvas* canvas,
                      const RenderJobInfo& info) = 0;
};

struct MatrixClipJobRenderer : public JobRenderer {
 public:
  const DlMatrix& GetSetupMatrix() const {
    FML_CHECK(is_setup_);
    return setup_matrix_;
  }

  const DlIRect& GetSetupClipBounds() const {
    FML_CHECK(is_setup_);
    return setup_clip_bounds_;
  }

 protected:
  bool is_setup_ = false;
  DlMatrix setup_matrix_;
  DlIRect setup_clip_bounds_;
};

struct DlJobRenderer : public MatrixClipJobRenderer {
  explicit DlJobRenderer(const DlSetup& dl_setup,
                         const DlRenderer& dl_render,
                         const DlRenderer& dl_restore)
      : dl_setup_(dl_setup),    //
        dl_render_(dl_render),  //
        dl_restore_(dl_restore) {}

  void Render(const RenderEnvironment& env,
              DlCanvas* canvas,
              const RenderJobInfo& info) override {
    FML_DCHECK(info.opacity == 1.0f);
    DlPaint paint;
    dl_setup_({env, canvas, paint});
    setup_paint_ = paint;
    setup_matrix_ = canvas->GetMatrix();
    setup_clip_bounds_ =
        DlIRect::RoundOut(canvas->GetDestinationClipCoverage());
    is_setup_ = true;
    dl_render_({env, canvas, paint});
    dl_restore_({env, canvas, paint});
  }

  sk_sp<DisplayList> MakeDisplayList(const RenderEnvironment& env,
                                     const RenderJobInfo& info) {
    DisplayListBuilder builder(kTestBounds2);
    Render(env, &builder, info);
    return builder.Build();
  }

  const DlPaint& GetSetupPaint() const {
    FML_CHECK(is_setup_);
    return setup_paint_;
  }

 private:
  const DlSetup dl_setup_;
  const DlRenderer dl_render_;
  const DlRenderer dl_restore_;
  DlPaint setup_paint_;
};

struct DisplayListJobRenderer : public JobRenderer {
  explicit DisplayListJobRenderer(sk_sp<DisplayList> display_list)
      : display_list_(std::move(display_list)) {}

  void Render(const RenderEnvironment& env,
              DlCanvas* canvas,
              const RenderJobInfo& info) override {
    canvas->DrawDisplayList(display_list_, info.opacity);
  }

 private:
  sk_sp<DisplayList> display_list_;
};

class RenderEnvironment {
 public:
  RenderEnvironment(const DlSurfaceProvider* provider, PixelFormat format)
      : provider_(provider), format_(format) {}

  static RenderEnvironment Make565(const DlSurfaceProvider* provider) {
    return RenderEnvironment(provider, PixelFormat::k565);
  }

  static RenderEnvironment MakeN32(const DlSurfaceProvider* provider) {
    return RenderEnvironment(provider, PixelFormat::kN32Premul);
  }

  void InitializeReference(DlSetup& dl_setup,
                           DlRenderer& dl_renderer,
                           DlColor bg = DlColor::kTransparent()) {
    RenderJobInfo info = {
        .bg = bg,
    };
    DlJobRenderer dl_job(dl_setup, dl_renderer, kEmptyDlRenderer);
    ref_dl_result_ = GetResult(info, dl_job);
    ref_dl_paint_ = dl_job.GetSetupPaint();
    ref_matrix_ = dl_job.GetSetupMatrix();
    ref_clip_bounds_ = dl_job.GetSetupClipBounds();
  }

  RenderResult GetResult(const RenderJobInfo& info,
                         JobRenderer& renderer) const {
    std::shared_ptr<DlSurfaceInstance> surface =
        getSurface(info.width, info.height);
    FML_DCHECK(surface != nullptr);

    DisplayListBuilder builder(DlRect::MakeWH(info.width, info.height));
    builder.Clear(info.bg);
    builder.Scale(info.scale, info.scale);
    renderer.Render(*this, &builder, info);
    sk_sp<DisplayList> display_list = builder.Build();
    DlRect dl_bounds = display_list->GetBounds();
    surface->RenderDisplayList(display_list);
    surface->FlushSubmitCpuSync();

    return RenderResult::Make(surface->SnapshotToPixelData(), dl_bounds);
  }

  RenderResult GetResult(const sk_sp<DisplayList>& dl) const {
    DisplayListJobRenderer job(dl);
    RenderJobInfo info = {};
    return GetResult(info, job);
  }

  PixelFormat GetPixelFormat() const { return format_; }
  const DlSurfaceProvider* GetProvider() const { return provider_; }
  bool IsValid() const { return provider_->SupportsPixelFormat(format_); }
  const std::string GetBackendName() const {
    return provider_->GetBackendName();
  }

  const DlPaint& GetReferencePaint() const { return ref_dl_paint_; }
  const DlMatrix& GetReferenceMatrix() const { return ref_matrix_; }
  const DlIRect& GetReferenceClipBounds() const { return ref_clip_bounds_; }
  const RenderResult& GetReferenceResult() const { return ref_dl_result_; }

  const sk_sp<DlImage> GetTestImage() const {
    if (test_image_ == nullptr) {
      test_image_ = MakeTestImage();
    }
    return test_image_;
  }

  const std::shared_ptr<DlText> GetTestText() const {
    if (test_text_ == nullptr) {
      test_text_ = MakeTestText();
    }
    return test_text_;
  }

 private:
  mutable std::shared_ptr<DlSurfaceInstance> cached_surface_;
  std::shared_ptr<DlSurfaceInstance> getSurface(int width, int height) const {
    FML_DCHECK(IsValid());
    if (cached_surface_ == nullptr ||  //
        cached_surface_->width() != width ||
        cached_surface_->height() != height) {
      cached_surface_.reset();
      cached_surface_ =
          provider_->MakeOffscreenSurface(kTestWidth, kTestHeight, format_);
    }
    return cached_surface_;
  }

  const DlSurfaceProvider* provider_;
  const PixelFormat format_;

  DlPaint ref_dl_paint_;
  DlMatrix ref_matrix_;
  DlIRect ref_clip_bounds_;
  RenderResult ref_dl_result_;

  mutable sk_sp<DlImage> test_image_;
  sk_sp<DlImage> MakeTestImage() const {
    std::shared_ptr<DlSurfaceInstance> surface =
        provider_->MakeOffscreenSurface(kRenderWidth, kRenderHeight,
                                        DlSurfaceProvider::kN32Premul);
    DisplayListBuilder builder(DlRect::MakeWH(kRenderWidth, kRenderHeight));
    DrawCheckerboard(&builder);
    surface->RenderDisplayList(builder.Build());
    surface->FlushSubmitCpuSync();
    return surface->SnapshotToImage();
  }

  mutable std::shared_ptr<DlText> test_text_;
  std::shared_ptr<DlText> MakeTestText() const {
    sk_sp<SkTextBlob> blob = MakeTextBlob("Testing", kTextFontHeight);
    if (provider_->TargetsImpeller()) {
#ifdef IMPELLER_SUPPORTS_RENDERING
      return DlTextImpeller::MakeFromBlob(blob);
#else   // IMPELLER_SUPPORTS_RENDERING
      return nullptr;
#endif  // IMPELLER_SUPPORTS_RENDERING
    } else {
      return DlTextSkia::Make(blob);
    }
  }

  static sk_sp<SkTextBlob> MakeTextBlob(const std::string& string,
                                        DlScalar font_height) {
    SkFont font = CreateTestFontOfSize(font_height);
    sk_sp<SkTypeface> face = font.refTypeface();
    FML_CHECK(face);
    FML_CHECK(face->countGlyphs() > 0) << "No glyphs in font";
    return SkTextBlob::MakeFromText(string.c_str(), string.size(), font,
                                    SkTextEncoding::kUTF8);
  }
};

class CaseParameters {
 public:
  explicit CaseParameters(std::string info)
      : CaseParameters(std::move(info), kEmptyDlSetup) {}

  CaseParameters(std::string info, DlSetup& dl_setup)
      : CaseParameters(std::move(info),
                       dl_setup,
                       kEmptyDlRenderer,
                       DlColor::kTransparent(),
                       false,
                       false,
                       false) {}

  CaseParameters(std::string info,
                 DlSetup& dl_setup,
                 DlRenderer& dl_restore,
                 DlColor bg,
                 bool has_diff_clip,
                 bool has_mutating_save_layer,
                 bool fuzzy_compare_components)
      : info_(std::move(info)),
        bg_(bg),
        dl_setup_(dl_setup),
        dl_restore_(dl_restore),
        has_diff_clip_(has_diff_clip),
        has_mutating_save_layer_(has_mutating_save_layer),
        fuzzy_compare_components_(fuzzy_compare_components) {}

  CaseParameters with_restore(DlRenderer& dl_restore,
                              bool mutating_layer,
                              bool fuzzy_compare_components = false) {
    return CaseParameters(info_, dl_setup_, dl_restore, bg_, has_diff_clip_,
                          mutating_layer, fuzzy_compare_components);
  }

  CaseParameters with_bg(DlColor bg) {
    return CaseParameters(info_, dl_setup_, dl_restore_, bg, has_diff_clip_,
                          has_mutating_save_layer_, fuzzy_compare_components_);
  }

  CaseParameters with_diff_clip() {
    return CaseParameters(info_, dl_setup_, dl_restore_, bg_, true,
                          has_mutating_save_layer_, fuzzy_compare_components_);
  }

  std::string info() const { return info_; }
  DlColor bg() const { return bg_; }
  bool has_diff_clip() const { return has_diff_clip_; }
  bool has_mutating_save_layer() const { return has_mutating_save_layer_; }
  bool fuzzy_compare_components() const { return fuzzy_compare_components_; }

  DlSetup dl_setup() const { return dl_setup_; }
  DlRenderer dl_restore() const { return dl_restore_; }

 private:
  const std::string info_;
  const DlColor bg_;
  const DlSetup dl_setup_;
  const DlRenderer dl_restore_;
  const bool has_diff_clip_;
  const bool has_mutating_save_layer_;
  const bool fuzzy_compare_components_;
};

class TestParameters {
 public:
  TestParameters(const DlRenderer& dl_renderer,
                 const DisplayListAttributeFlags& flags)
      : dl_renderer_(dl_renderer), flags_(flags) {}

  bool uses_paint() const { return !flags_.ignores_paint(); }
  bool uses_gradient() const { return flags_.applies_shader(); }

  bool impeller_compatible(const DlPaint& paint) const {
    if (is_draw_text_blob()) {
      // Non-color text is rendered as paths
      if (paint.getColorSourcePtr()) {
        return false;
      }
      // Non-filled text (stroke or stroke and fill) is rendered as paths
      if (paint.getDrawStyle() != DlDrawStyle::kFill) {
        return false;
      }
    }
    return true;
  }

  bool should_match(const RenderEnvironment& env,
                    const CaseParameters& caseP,
                    const DlPaint& attr,
                    const MatrixClipJobRenderer& renderer) const {
    if (caseP.has_mutating_save_layer()) {
      return false;
    }
    if (env.GetReferenceClipBounds() != renderer.GetSetupClipBounds() ||
        caseP.has_diff_clip()) {
      return false;
    }
    if (env.GetReferenceMatrix() != renderer.GetSetupMatrix() &&
        !flags_.is_flood()) {
      return false;
    }
    if (flags_.ignores_paint()) {
      return true;
    }
    const DlPaint& ref_attr = env.GetReferencePaint();
    if (flags_.applies_anti_alias() &&  //
        ref_attr.isAntiAlias() != attr.isAntiAlias()) {
      if (env.GetProvider()->TargetsImpeller()) {
        // Impeller only does MSAA, ignoring the AA attribute
        // https://github.com/flutter/flutter/issues/104721
      } else {
        return false;
      }
    }
    if (flags_.applies_color() &&  //
        ref_attr.getColor() != attr.getColor()) {
      return false;
    }
    if (flags_.applies_blend() &&  //
        ref_attr.getBlendMode() != attr.getBlendMode()) {
      return false;
    }
    if (flags_.applies_color_filter() &&  //
        (ref_attr.isInvertColors() != attr.isInvertColors() ||
         NotEquals(ref_attr.getColorFilter(), attr.getColorFilter()))) {
      return false;
    }
    if (flags_.applies_mask_filter() &&  //
        NotEquals(ref_attr.getMaskFilter(), attr.getMaskFilter())) {
      return false;
    }
    if (flags_.applies_image_filter() &&  //
        ref_attr.getImageFilter() != attr.getImageFilter()) {
      return false;
    }
    if (flags_.applies_shader() &&  //
        NotEquals(ref_attr.getColorSource(), attr.getColorSource())) {
      return false;
    }

    bool is_stroked = flags_.is_stroked(attr.getDrawStyle());
    if (flags_.is_stroked(ref_attr.getDrawStyle()) != is_stroked) {
      return false;
    }
    if (!is_stroked) {
      return true;
    }
    if (ref_attr.getStrokeWidth() != attr.getStrokeWidth()) {
      return false;
    }
    DisplayListSpecialGeometryFlags geo_flags =
        flags_.GeometryFlags(is_stroked);
    if (geo_flags.may_have_end_caps() &&  //
        getCap(ref_attr, geo_flags) != getCap(attr, geo_flags)) {
      return false;
    }
    if (geo_flags.may_have_joins()) {
      if (ref_attr.getStrokeJoin() != attr.getStrokeJoin()) {
        return false;
      }
      if (ref_attr.getStrokeJoin() == DlStrokeJoin::kMiter) {
        DlScalar ref_miter = ref_attr.getStrokeMiter();
        DlScalar test_miter = attr.getStrokeMiter();
        // miter limit < 1.4 affects right angles
        if (geo_flags.may_have_acute_joins() ||  //
            ref_miter < 1.4 || test_miter < 1.4) {
          if (ref_miter != test_miter) {
            return false;
          }
        }
      }
    }
    return true;
  }

  DlStrokeCap getCap(const DlPaint& attr,
                     DisplayListSpecialGeometryFlags geo_flags) const {
    DlStrokeCap cap = attr.getStrokeCap();
    if (geo_flags.butt_cap_becomes_square() && cap == DlStrokeCap::kButt) {
      return DlStrokeCap::kSquare;
    }
    return cap;
  }

  const BoundsTolerance adjust(const BoundsTolerance& tolerance,
                               const DlPaint& paint,
                               const DlMatrix& matrix) const {
    if (is_draw_text_blob() && tolerance.discrete_offset() > 0) {
      // drawTextBlob needs just a little more leeway when using a
      // discrete path effect.
      return tolerance.addBoundsPadding(2, 2);
    }
    if (is_draw_line()) {
      return lineAdjust(tolerance, paint, matrix);
    }
    if (is_draw_arc_center()) {
      if (paint.getDrawStyle() != DlDrawStyle::kFill &&
          paint.getStrokeJoin() == DlStrokeJoin::kMiter) {
        // the miter join at the center of an arc does not really affect
        // its bounds in any of our test cases, but the bounds code needs
        // to take it into account for the cases where it might, so we
        // relax our tolerance to reflect the miter bounds padding.
        DlScalar miter_pad =
            paint.getStrokeMiter() * paint.getStrokeWidth() * 0.5f;
        return tolerance.addBoundsPadding(miter_pad, miter_pad);
      }
    }
    return tolerance;
  }

  const BoundsTolerance lineAdjust(const BoundsTolerance& tolerance,
                                   const DlPaint& paint,
                                   const DlMatrix& matrix) const {
    DlScalar adjust = 0.0;
    DlScalar half_width = paint.getStrokeWidth() * 0.5f;
    if (tolerance.discrete_offset() > 0) {
      // When a discrete path effect is added, the bounds calculations must
      // allow for miters in any direction, but a horizontal line will not
      // have miters in the horizontal direction, similarly for vertical
      // lines, and diagonal lines will have miters off at a "45 degree"
      // angle that don't expand the bounds much at all.
      // Also, the discrete offset will not move any points parallel with
      // the line, so provide tolerance for both miters and offset.
      adjust =
          half_width * paint.getStrokeMiter() + tolerance.discrete_offset();
    }

    DisplayListSpecialGeometryFlags geo_flags = flags_.GeometryFlags(true);
    if (paint.getStrokeCap() == DlStrokeCap::kButt &&
        !geo_flags.butt_cap_becomes_square()) {
      adjust = std::max(adjust, half_width);
    }
    if (adjust == 0) {
      return tolerance;
    }
    DlScalar h_tolerance;
    DlScalar v_tolerance;
    if (is_horizontal_line()) {
      FML_DCHECK(!is_vertical_line());
      h_tolerance = adjust;
      v_tolerance = 0;
    } else if (is_vertical_line()) {
      h_tolerance = 0;
      v_tolerance = adjust;
    } else {
      // The perpendicular miters just do not impact the bounds of
      // diagonal lines at all as they are aimed in the wrong direction
      // to matter. So allow tolerance in both axes.
      h_tolerance = v_tolerance = adjust;
    }
    BoundsTolerance new_tolerance =
        tolerance.addBoundsPadding(h_tolerance, v_tolerance);
    return new_tolerance;
  }

  const DlRenderer& dl_renderer() const { return dl_renderer_; }

  // Tests that call drawTextBlob with an sk_ref paint attribute will cause
  // those attributes to be stored in an internal Skia cache so we need
  // to expect that the |sk_ref.unique()| call will fail in those cases.
  // See: (TBD(flar) - file Skia bug)
  bool is_draw_text_blob() const { return is_draw_text_blob_; }
  bool is_draw_display_list() const { return is_draw_display_list_; }
  bool is_draw_line() const { return is_draw_line_; }
  bool is_draw_arc_center() const { return is_draw_arc_center_; }
  bool is_draw_path() const { return is_draw_path_; }
  bool is_horizontal_line() const { return is_horizontal_line_; }
  bool is_vertical_line() const { return is_vertical_line_; }
  bool ignores_dashes() const { return ignores_dashes_; }

  DisplayListAttributeFlags flags() const { return flags_; }

  TestParameters& set_draw_text_blob() {
    is_draw_text_blob_ = true;
    return *this;
  }
  TestParameters& set_draw_display_list() {
    is_draw_display_list_ = true;
    return *this;
  }
  TestParameters& set_draw_line() {
    is_draw_line_ = true;
    return *this;
  }
  TestParameters& set_draw_arc_center() {
    is_draw_arc_center_ = true;
    return *this;
  }
  TestParameters& set_draw_path() {
    is_draw_path_ = true;
    return *this;
  }
  TestParameters& set_ignores_dashes() {
    ignores_dashes_ = true;
    return *this;
  }
  TestParameters& set_horizontal_line() {
    is_horizontal_line_ = true;
    return *this;
  }
  TestParameters& set_vertical_line() {
    is_vertical_line_ = true;
    return *this;
  }

 private:
  const DlRenderer dl_renderer_;
  const DisplayListAttributeFlags flags_;

  bool is_draw_text_blob_ = false;
  bool is_draw_display_list_ = false;
  bool is_draw_line_ = false;
  bool is_draw_arc_center_ = false;
  bool is_draw_path_ = false;
  bool ignores_dashes_ = false;
  bool is_horizontal_line_ = false;
  bool is_vertical_line_ = false;
};

class CanvasCompareTester {
 private:
  static std::string failure_image_directory_;
  static bool save_failure_images_;
  static std::vector<std::string> failure_image_filenames_;

 public:
  static void EnableSaveImagesOnFailures() { save_failure_images_ = true; }

  static void PrintFailureImageFileNames() {
    if (failure_image_filenames_.empty()) {
      return;
    }
    FML_LOG(INFO);
    FML_LOG(INFO) << failure_image_filenames_.size() << " images saved in "
                  << failure_image_directory_;
    for (const std::string& filename : failure_image_filenames_) {
      FML_LOG(INFO) << "  " << filename;
    }
    FML_LOG(INFO);
  }

  static BoundsTolerance DefaultTolerance;

  static void RenderAll(const std::unique_ptr<DlSurfaceProvider>& provider,
                        const TestParameters& params,
                        const BoundsTolerance& tolerance = DefaultTolerance) {
    RenderEnvironment env = RenderEnvironment::MakeN32(provider.get());
    env.InitializeReference(kEmptyDlSetup, params.dl_renderer());

    RenderWithTransforms(params, env, tolerance);
    RenderWithClips(params, env, tolerance);
    RenderWithSaveRestore(params, env, tolerance);
    // Only test attributes if the canvas version uses the paint object
    if (params.uses_paint()) {
      RenderWithAttributes(params, env, tolerance);
    }
  }

  static void RenderWithSaveRestore(const TestParameters& testP,
                                    const RenderEnvironment& env,
                                    const BoundsTolerance& tolerance) {
    DlRect clip =
        DlRect::MakeXYWH(kRenderCenterX - 1, kRenderCenterY - 1, 2, 2);
    DlRect rect = DlRect::MakeXYWH(kRenderCenterX, kRenderCenterY, 10, 10);
    DlColor alpha_layer_color = DlColor::kCyan().withAlpha(0x7f);
    DlRenderer dl_safe_restore = [=](const DlRenderContext& ctx) {
      // Draw another primitive to disable peephole optimizations
      // As the rendering op rejection in the DisplayList Builder
      // gets smarter and smarter, this operation has had to get
      // sneakier and sneakier about specifying an operation that
      // won't practically show up in the output, but technically
      // can't be culled.
      ctx.canvas->DrawRect(
          DlRect::MakeXYWH(kRenderCenterX, kRenderCenterY, 0.0001, 0.0001),
          DlPaint());
      ctx.canvas->Restore();
    };
    DlRenderer dl_opt_restore = [=](const DlRenderContext& ctx) {
      // Just a simple restore to allow peephole optimizations to occur
      ctx.canvas->Restore();
    };
    DlRect layer_bounds = kRenderBounds.Expand(-15, -15);
    // clang-format off
    // The following section gets re-formatted on every commit even if it
    // doesn't change.
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "With prior save/clip/restore",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->Save();
                     ctx.canvas->ClipRect(clip, DlClipOp::kIntersect, false);
                     DlPaint p2;
                     ctx.canvas->DrawRect(rect, p2);
                     p2.setBlendMode(DlBlendMode::kClear);
                     ctx.canvas->DrawRect(rect, p2);
                     ctx.canvas->Restore();
                   }));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer no paint, no bounds",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->SaveLayer(std::nullopt, nullptr);
                   })
                   .with_restore(dl_safe_restore, false));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer no paint, with bounds",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->SaveLayer(layer_bounds, nullptr);
                   })
                   .with_restore(dl_safe_restore, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with alpha, no bounds",
                   [=](const DlSetupContext& ctx) {
                     DlPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     ctx.canvas->SaveLayer(std::nullopt, &save_p);
                   })
                   .with_restore(dl_safe_restore, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with peephole alpha, no bounds",
                   [=](const DlSetupContext& ctx) {
                     DlPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     ctx.canvas->SaveLayer(std::nullopt, &save_p);
                   })
                   .with_restore(dl_opt_restore, true, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with alpha and bounds",
                   [=](const DlSetupContext& ctx) {
                     DlPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     ctx.canvas->SaveLayer(layer_bounds, &save_p);
                   })
                   .with_restore(dl_safe_restore, true));
    // clang-format on
    {
      // Being able to see a backdrop blur requires a non-default background
      // so we create a new environment for these tests that has a checkerboard
      // background that can be blurred by the backdrop filter. We also want
      // to avoid the rendered primitive from obscuring the blurred background
      // so we set an alpha value which works for all primitives except for
      // drawColor which can override the alpha with its color, but it now uses
      // a non-opaque color to avoid that problem.
      RenderEnvironment backdrop_env =
          RenderEnvironment::MakeN32(env.GetProvider());
      DlSetup dl_backdrop_setup = [=](const DlSetupContext& ctx) {
        DlPaint setup_p;
        setup_p.setColorSource(MakeColorSource(ctx.env.GetTestImage()));
        ctx.canvas->DrawPaint(setup_p);
      };
      DlSetup dl_content_setup = [=](const DlSetupContext& ctx) {
        ctx.paint.setAlpha(ctx.paint.getAlpha() / 2);
      };
      backdrop_env.InitializeReference(dl_backdrop_setup, testP.dl_renderer());

      DlBlurImageFilter dl_backdrop(5, 5, DlTileMode::kDecal);
      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      RenderWith(
          testP, backdrop_env, tolerance,
          CaseParameters(
              "saveLayer with backdrop",
              [=](const DlSetupContext& ctx) {
                dl_backdrop_setup(ctx);
                ctx.canvas->SaveLayer(std::nullopt, nullptr, &dl_backdrop);
                dl_content_setup(ctx);
              })
              .with_restore(dl_safe_restore, true));
      RenderWith(testP, backdrop_env, tolerance,
                 CaseParameters(
                     "saveLayer with bounds and backdrop",
                     [=](const DlSetupContext& ctx) {
                       dl_backdrop_setup(ctx);
                       ctx.canvas->SaveLayer(layer_bounds, nullptr,
                                             &dl_backdrop);
                       dl_content_setup(ctx);
                     })
                     .with_restore(dl_safe_restore, true));
      RenderWith(
          testP, backdrop_env, tolerance,
          CaseParameters(
              "clipped saveLayer with backdrop",
              [=](const DlSetupContext& ctx) {
                dl_backdrop_setup(ctx);
                ctx.canvas->ClipRect(layer_bounds);
                ctx.canvas->SaveLayer(std::nullopt, nullptr, &dl_backdrop);
                dl_content_setup(ctx);
              })
              .with_restore(dl_safe_restore, true));
      // clang-format on
    }

    {
      // clang-format off
      constexpr float rotate_alpha_color_matrix[20] = {
          0, 1, 0,  0 , 0,
          0, 0, 1,  0 , 0,
          1, 0, 0,  0 , 0,
          0, 0, 0, 0.5, 0,
      };
      // clang-format on
      std::shared_ptr<const DlColorFilter> dl_alpha_rotate_filter =
          DlColorFilter::MakeMatrix(rotate_alpha_color_matrix);
      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ColorFilter, no bounds",
                       [=](const DlSetupContext& ctx) {
                         DlPaint save_p;
                         save_p.setColorFilter(dl_alpha_rotate_filter);
                         ctx.canvas->SaveLayer(std::nullopt, &save_p);
                         ctx.paint.setStrokeWidth(5.0);
                       })
                       .with_restore(dl_safe_restore, true));
      }
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ColorFilter and bounds",
                       [=](const DlSetupContext& ctx) {
                         DlPaint save_p;
                         save_p.setColorFilter(dl_alpha_rotate_filter);
                         ctx.canvas->SaveLayer(kRenderBounds, &save_p);
                         ctx.paint.setStrokeWidth(5.0);
                       })
                       .with_restore(dl_safe_restore, true));
      }
      // clang-format on
    }

    {
      // clang-format off
      constexpr float color_matrix[20] = {
          0.5, 0, 0, 0, 0.5,
          0, 0.5, 0, 0, 0.5,
          0, 0, 0.5, 0, 0.5,
          0, 0, 0, 1, 0,
      };
      // clang-format on
      std::shared_ptr<const DlColorFilter> dl_color_filter =
          DlColorFilter::MakeMatrix(color_matrix);
      std::shared_ptr<DlImageFilter> dl_cf_image_filter =
          DlImageFilter::MakeColorFilter(dl_color_filter);
      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ImageFilter, no bounds",
                       [=](const DlSetupContext& ctx) {
                         DlPaint save_p;
                         save_p.setImageFilter(dl_cf_image_filter);
                         ctx.canvas->SaveLayer(std::nullopt, &save_p);
                         ctx.paint.setStrokeWidth(5.0);
                       })
                       .with_restore(dl_safe_restore, true));
      }
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ImageFilter and bounds",
                       [=](const DlSetupContext& ctx) {
                         DlPaint save_p;
                         save_p.setImageFilter(dl_cf_image_filter);
                         ctx.canvas->SaveLayer(kRenderBounds, &save_p);
                         ctx.paint.setStrokeWidth(5.0);
                       })
                       .with_restore(dl_safe_restore, true));
      }
      // clang-format on
    }
  }

  static void RenderWithAttributes(const TestParameters& testP,
                                   const RenderEnvironment& env,
                                   const BoundsTolerance& tolerance) {
    RenderWith(testP, env, tolerance, CaseParameters("Defaults Test"));

    {
      // CPU renderer with default line width of 0 does not show antialiasing
      // for stroked primitives, so we make a new reference with a non-trivial
      // stroke width to demonstrate the differences
      RenderEnvironment aa_env = RenderEnvironment::MakeN32(env.GetProvider());
      // Tweak the bounds tolerance for the displacement of 1/10 of a pixel
      const BoundsTolerance aa_tolerance = tolerance.addBoundsPadding(1, 1);
      auto dl_aa_setup = [=](DlSetupContext ctx, bool is_aa) -> void {
        ctx.canvas->Translate(0.1, 0.1);
        ctx.paint.setAntiAlias(is_aa);
        ctx.paint.setStrokeWidth(5.0);
      };
      aa_env.InitializeReference(
          [=](const DlSetupContext& ctx) { dl_aa_setup(ctx, false); },
          testP.dl_renderer());

      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      RenderWith(
          testP, aa_env, aa_tolerance,
          CaseParameters(
              "AntiAlias == True",
              [=](const DlSetupContext& ctx) { dl_aa_setup(ctx, true); }));
      RenderWith(
          testP, aa_env, aa_tolerance,
          CaseParameters(
              "AntiAlias == False",
              [=](const DlSetupContext& ctx) { dl_aa_setup(ctx, false); }));
      // clang-format on
    }

    // clang-format off
    // The following section gets re-formatted on every commit even if it
    // doesn't change.
    RenderWith(  //
        testP, env, tolerance,
        CaseParameters(
            "Color == Blue",
            [=](const DlSetupContext& ctx) {
              ctx.paint.setColor(DlColor::kBlue());
            }));
    RenderWith(  //
        testP, env, tolerance,
        CaseParameters(
            "Color == Green",
            [=](const DlSetupContext& ctx) {
              ctx.paint.setColor(DlColor::kGreen());
            }));
    // clang-format on

    RenderWithStrokes(testP, env, tolerance);

    {
      // half opaque cyan
      DlColor blendable_color = DlColor::kCyan().withAlpha(0x7f);
      DlColor bg = DlColor::kWhite();

      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      RenderWith(testP, env, tolerance,
                 CaseParameters(
                     "Blend == SrcIn",
                     [=](const DlSetupContext& ctx) {
                       ctx.paint.setBlendMode(DlBlendMode::kSrcIn);
                       ctx.paint.setColor(blendable_color);
                     })
                     .with_bg(bg));
      RenderWith(testP, env, tolerance,
                 CaseParameters(
                     "Blend == DstIn",
                     [=](const DlSetupContext& ctx) {
                       ctx.paint.setBlendMode(DlBlendMode::kDstIn);
                       ctx.paint.setColor(blendable_color);
                     })
                     .with_bg(bg));
      // clang-format on
    }

    {
      // Being able to see a blur requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment blur_env =
          RenderEnvironment::MakeN32(env.GetProvider());
      DlSetup dl_blur_setup = [=](const DlSetupContext& ctx) {
        ctx.paint.setColorSource(MakeColorSource(ctx.env.GetTestImage()));
        ctx.paint.setStrokeWidth(5.0);
      };
      blur_env.InitializeReference(dl_blur_setup, testP.dl_renderer());

      DlBlurImageFilter dl_filter_decal_5(5.0, 5.0, DlTileMode::kDecal);
      BoundsTolerance blur_5_tolerance = tolerance.addBoundsPadding(4, 4);
      {
        // clang-format off
        // The following section gets re-formatted on every commit even if it
        // doesn't change.
        RenderWith(testP, blur_env, blur_5_tolerance,
                   CaseParameters(
                       "ImageFilter == Decal Blur 5",
                       [=](const DlSetupContext& ctx) {
                         dl_blur_setup(ctx);
                         ctx.paint.setImageFilter(&dl_filter_decal_5);
                       }));
        // clang-format on
      }
      DlBlurImageFilter dl_filter_clamp_5(5.0, 5.0, DlTileMode::kClamp);
      {
        // clang-format off
        // The following section gets re-formatted on every commit even if it
        // doesn't change.
        RenderWith(testP, blur_env, blur_5_tolerance,
                   CaseParameters(
                       "ImageFilter == Clamp Blur 5",
                       [=](const DlSetupContext& ctx) {
                         dl_blur_setup(ctx);
                         ctx.paint.setImageFilter(&dl_filter_clamp_5);
                       }));
        // clang-format on
      }
    }

    {
      // Being able to see a dilate requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment dilate_env =
          RenderEnvironment::MakeN32(env.GetProvider());
      DlSetup dl_dilate_setup = [=](const DlSetupContext& ctx) {
        ctx.paint.setColorSource(MakeColorSource(ctx.env.GetTestImage()));
        ctx.paint.setStrokeWidth(5.0);
      };
      dilate_env.InitializeReference(dl_dilate_setup, testP.dl_renderer());

      DlDilateImageFilter dl_dilate_filter_5(5.0, 5.0);
      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      RenderWith(testP, dilate_env, tolerance,
                 CaseParameters(
                     "ImageFilter == Dilate 5",
                     [=](const DlSetupContext& ctx) {
                       dl_dilate_setup(ctx);
                       ctx.paint.setImageFilter(&dl_dilate_filter_5);
                     }));
      // clang-format on
    }

    {
      // Being able to see an erode requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment erode_env =
          RenderEnvironment::MakeN32(env.GetProvider());
      DlSetup dl_erode_setup = [=](const DlSetupContext& ctx) {
        ctx.paint.setColorSource(MakeColorSource(ctx.env.GetTestImage()));
        ctx.paint.setStrokeWidth(6.0);
      };
      erode_env.InitializeReference(dl_erode_setup, testP.dl_renderer());

      // do not erode too much, because some tests assert there are enough
      // pixels that are changed.
      DlErodeImageFilter dl_erode_filter_1(1.0, 1.0);
      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      RenderWith(testP, erode_env, tolerance,
                 CaseParameters(
                     "ImageFilter == Erode 1",
                     [=](const DlSetupContext& ctx) {
                       dl_erode_setup(ctx);
                       ctx.paint.setImageFilter(&dl_erode_filter_1);
                     }));
      // clang-format on
    }

    {
      // clang-format off
      constexpr float rotate_color_matrix[20] = {
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          1, 0, 0, 0, 0,
          0, 0, 0, 1, 0,
      };
      // clang-format on
      std::shared_ptr<const DlColorFilter> dl_color_filter =
          DlColorFilter::MakeMatrix(rotate_color_matrix);
      {
        DlColor bg = DlColor::kWhite();
        // clang-format off
        // The following section gets re-formatted on every commit even if it
        // doesn't change.
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "ColorFilter == RotateRGB",
                       [=](const DlSetupContext& ctx) {
                         ctx.paint.setColor(DlColor::kYellow());
                         ctx.paint.setColorFilter(dl_color_filter);
                       })
                       .with_bg(bg));
        // clang-format on
      }
      {
        DlColor bg = DlColor::kWhite();
        // clang-format off
        // The following section gets re-formatted on every commit even if it
        // doesn't change.
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "ColorFilter == Invert",
                       [=](const DlSetupContext& ctx) {
                         ctx.paint.setColor(DlColor::kYellow());
                         ctx.paint.setInvertColors(true);
                       })
                       .with_bg(bg));
        // clang-format on
      }
    }

    {
      const DlBlurMaskFilter dl_mask_filter(DlBlurStyle::kNormal, 5.0);
      BoundsTolerance blur_5_tolerance = tolerance.addBoundsPadding(4, 4);
      {
        // clang-format off
        // The following section gets re-formatted on every commit even if it
        // doesn't change.
        RenderWith(testP, env, blur_5_tolerance,
                   CaseParameters(
                       "MaskFilter == Blur 5",
                       [=](const DlSetupContext& ctx) {
                         // Stroked primitives need some non-trivial stroke
                         // width to be blurred
                         ctx.paint.setStrokeWidth(5.0);
                         ctx.paint.setMaskFilter(&dl_mask_filter);
                       }));
        // clang-format on
      }
    }

    {
      DlPoint dl_end_points[] = {
          kRenderBounds.GetLeftTop(),
          kRenderBounds.GetRightBottom(),
      };
      DlColor dl_colors[] = {
          DlColor::kGreen(),
          DlColor::kYellow().withAlpha(0x7f),
          DlColor::kBlue(),
      };
      float stops[] = {
          0.0,
          0.5,
          1.0,
      };
      std::shared_ptr<DlColorSource> dl_gradient =
          DlColorSource::MakeLinear(dl_end_points[0], dl_end_points[1], 3,
                                    dl_colors, stops, DlTileMode::kMirror);
      {
        // clang-format off
        // The following section gets re-formatted on every commit even if it
        // doesn't change.
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "LinearGradient GYB",
                       [=](const DlSetupContext& ctx) {
                         ctx.paint.setColorSource(dl_gradient);
                       }));
        // clang-format on
      }
    }
  }

  static void RenderWithStrokes(const TestParameters& testP,
                                const RenderEnvironment& env,
                                const BoundsTolerance& tolerance_in) {
    // The test cases were generated with geometry that will try to fill
    // out the various miter limits used for testing, but they can be off
    // by a couple of pixels so we will relax bounds testing for strokes by
    // a couple of pixels.

    // clang-format off
    // The following section gets re-formatted on every commit even if it
    // doesn't change.
    BoundsTolerance tolerance = tolerance_in.addBoundsPadding(2, 2);
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Fill",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kFill);
                   }));
    // clang-format on

    // Skia on HW produces a strong miter consistent with width=1.0
    // for any width less than a pixel, but the bounds computations of
    // both DL and SkPicture do not account for this. We will get
    // OOB pixel errors for the highly mitered drawPath geometry if
    // we don't set stroke width to 1.0 for that test on HW.
    // See https://bugs.chromium.org/p/skia/issues/detail?id=14046
    bool no_hairlines =
        testP.is_draw_path() &&
        env.GetProvider()->GetBackendType() != BackendType::kSkiaSoftware;
    // clang-format off
    // The following section gets re-formatted on every commit even if it
    // doesn't change.
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Stroke + defaults",
                   [=](const DlSetupContext& ctx) {
                     if (no_hairlines) {
                       ctx.paint.setStrokeWidth(1.0);
                     }
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                   }));

    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Fill + unnecessary StrokeWidth 10",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kFill);
                     ctx.paint.setStrokeWidth(10.0);
                   }));
    // clang-format on

    RenderEnvironment stroke_base_env =
        RenderEnvironment::MakeN32(env.GetProvider());
    DlSetup dl_stroke_setup = [=](const DlSetupContext& ctx) {
      ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
      ctx.paint.setStrokeWidth(5.0);
    };
    stroke_base_env.InitializeReference(dl_stroke_setup, testP.dl_renderer());

    // clang-format off
    // The following section gets re-formatted on every commit even if it
    // doesn't change.
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 10",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                     ctx.paint.setStrokeWidth(10.0);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                     ctx.paint.setStrokeWidth(5.0);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Square Cap",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                     ctx.paint.setStrokeWidth(5.0);
                     ctx.paint.setStrokeCap(DlStrokeCap::kSquare);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Round Cap",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                     ctx.paint.setStrokeWidth(5.0);
                     ctx.paint.setStrokeCap(DlStrokeCap::kRound);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Bevel Join",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                     ctx.paint.setStrokeWidth(5.0);
                     ctx.paint.setStrokeJoin(DlStrokeJoin::kBevel);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Round Join",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                     ctx.paint.setStrokeWidth(5.0);
                     ctx.paint.setStrokeJoin(DlStrokeJoin::kRound);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Miter 10",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                     ctx.paint.setStrokeWidth(5.0);
                     ctx.paint.setStrokeMiter(10.0);
                     ctx.paint.setStrokeJoin(DlStrokeJoin::kMiter);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Miter 0",
                   [=](const DlSetupContext& ctx) {
                     ctx.paint.setDrawStyle(DlDrawStyle::kStroke);
                     ctx.paint.setStrokeWidth(5.0);
                     ctx.paint.setStrokeMiter(0.0);
                     ctx.paint.setStrokeJoin(DlStrokeJoin::kMiter);
                   }));
    // clang-format on
  }

  static void RenderWithTransforms(const TestParameters& testP,
                                   const RenderEnvironment& env,
                                   const BoundsTolerance& tolerance) {
    // If the rendering method does not fill the corners of the original
    // bounds, then the estimate under rotation or skewing will be off
    // so we scale the padding by about 5% to compensate.
    BoundsTolerance skewed_tolerance = tolerance.mulScale(1.05, 1.05);
    RenderWith(  //
        testP, env, tolerance,
        CaseParameters(
            "Translate 5, 10",  //
            [=](const DlSetupContext& ctx) { ctx.canvas->Translate(5, 10); }));
    RenderWith(  //
        testP, env, tolerance,
        CaseParameters(
            "Scale +5%",  //
            [=](const DlSetupContext& ctx) { ctx.canvas->Scale(1.05, 1.05); }));
    RenderWith(  //
        testP, env, skewed_tolerance,
        CaseParameters(
            "Rotate 5 degrees",  //
            [=](const DlSetupContext& ctx) { ctx.canvas->Rotate(5); }));
    RenderWith(  //
        testP, env, skewed_tolerance,
        CaseParameters(
            "Skew 5%",  //
            [=](const DlSetupContext& ctx) { ctx.canvas->Skew(0.05, 0.05); }));
    {
      // This rather odd transform can cause slight differences in
      // computing in-bounds samples depending on which base rendering
      // routine Skia uses. Making sure our matrix values are powers
      // of 2 reduces, but does not eliminate, these slight differences
      // in calculation when we are comparing rendering with an alpha
      // to rendering opaque colors in the group opacity tests, for
      // example.
      DlScalar tweak = 1.0 / 16.0;
      DlMatrix matrix = DlMatrix::MakeRow(
          // clang-format off
          1.0 + tweak, tweak,       0, 5,
          tweak,       1.0 + tweak, 0, 10,
          0, 0, 1, 0,
          0, 0, 0, 1
          // clang-format on
      );
      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      RenderWith(
          testP, env, skewed_tolerance,
          CaseParameters(
              "Transform 2D Affine Matrix",
              [=](const DlSetupContext& ctx) {
                ctx.canvas->Transform(matrix);
              }));
      RenderWith(
          testP, env, skewed_tolerance,
          CaseParameters(
              "Transform 2D Affine inline",
              [=](const DlSetupContext& ctx) {
                ctx.canvas->Transform2DAffine(1.0 + tweak, tweak, 5,
                                              tweak, 1.0 + tweak, 10);
              }));
      // clang-format on
    }
    {
      DlMatrix matrix = DlMatrix::MakeRow(1.0f, 0.0f, 0.0f, kRenderCenterX,  //
                                          0.0f, 1.0f, 0.0f, kRenderCenterY,  //
                                          0.0f, 0.0f, 1.0f, 0.0f,            //
                                          0.0f, 0.0f, .001f, 1.0f);
      matrix = matrix * DlMatrix::MakeRotationX(DlDegrees(3));
      matrix = matrix * DlMatrix::MakeRotationY(DlDegrees(4));
      matrix = matrix.Translate({-kRenderCenterX, -kRenderCenterY, 0.0f});
      // clang-format off
      // The following section gets re-formatted on every commit even if it
      // doesn't change.
      RenderWith(
          testP, env, skewed_tolerance,
          CaseParameters(
              "Transform Full Perspective Matrix",
              [=](const DlSetupContext& ctx) {
                ctx.canvas->Transform(matrix);
              }));
      RenderWith(
          testP, env, skewed_tolerance,
          CaseParameters(
              "Transform Full Perspective inline",
              [=](const DlSetupContext& ctx) {
                ctx.canvas->TransformFullPerspective(
                    // These values match what ends up in matrix above
                     0.997564,   0.000000,   0.069756,   0.243591,
                     0.003651,   0.998630,  -0.052208,  -0.228027,
                    -0.069661,   0.052336,   0.996197,   1.732491,
                    -0.000070,   0.000052,   0.000996,   1.001732
                );
              }));
      // clang-format on
    }
  }

  static void RenderWithClips(const TestParameters& testP,
                              const RenderEnvironment& env,
                              const BoundsTolerance& diff_tolerance) {
    // We used to use an inset of 15.5 pixels here, but since Skia's rounding
    // behavior at the center of pixels does not match between HW and SW, we
    // ended up with some clips including different pixels between the two
    // destinations and this interacted poorly with the carefully chosen
    // geometry in some of the tests which was designed to have just the
    // right features fully filling the clips based on the SW rounding. By
    // moving to a 15.4 inset, the edge of the clip is never on the "rounding
    // edge" of a pixel.
    DlRect r_clip = kRenderBounds.Expand(-15.4, -15.4);
    BoundsTolerance intersect_tolerance = diff_tolerance.clip(r_clip);
    intersect_tolerance = intersect_tolerance.addPostClipPadding(1, 1);
    // clang-format off
    // The following section gets re-formatted on every commit even if it
    // doesn't change.
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipRect inset by 15.4",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipRect(r_clip, DlClipOp::kIntersect, false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipRect inset by 15.4",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipRect(r_clip, DlClipOp::kIntersect, true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipRect Diff, inset by 15.4",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipRect(r_clip, DlClipOp::kDifference, false);
                   })
                   .with_diff_clip());
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipOval",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipOval(r_clip, DlClipOp::kIntersect, false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipOval",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipOval(r_clip, DlClipOp::kIntersect, true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipOval Diff",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipOval(r_clip, DlClipOp::kDifference, false);
                   })
                   .with_diff_clip());
    // clang-format on

    // This test RR clip used to use very small radii, but due to
    // optimizations in the HW rrect rasterization, this caused small
    // bulges in the corners of the RRect which were interpreted as
    // "clip overruns" by the clip OOB pixel testing code. Using less
    // abusively small radii fixes the problem.
    DlRoundRect rr_clip = DlRoundRect::MakeRectXY(r_clip, 9, 9);
    // clang-format off
    // The following section gets re-formatted on every commit even if it
    // doesn't change.
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipRRect with radius of 9",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipRoundRect(rr_clip, DlClipOp::kIntersect,
                                               false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipRRect with radius of 9",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipRoundRect(rr_clip, DlClipOp::kIntersect,
                                               true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipRRect Diff, with radius of 9",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipRoundRect(rr_clip, DlClipOp::kDifference,
                                               false);
                   })
                   .with_diff_clip());
    // clang-format on

    DlPathBuilder path_builder;
    path_builder.SetFillType(DlPathFillType::kOdd);
    path_builder.AddRect(r_clip);
    path_builder.AddCircle(DlPoint(kRenderCenterX, kRenderCenterY), 1.0f);
    DlPath path_clip = path_builder.TakePath();
    // clang-format off
    // The following section gets re-formatted on every commit even if it
    // doesn't change.
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipPath inset by 15.4",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipPath(path_clip, DlClipOp::kIntersect,
                                          false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipPath inset by 15.4",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipPath(path_clip, DlClipOp::kIntersect,
                                          true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipPath Diff, inset by 15.4",
                   [=](const DlSetupContext& ctx) {
                     ctx.canvas->ClipPath(path_clip, DlClipOp::kDifference,
                                          false);
                   })
                   .with_diff_clip());
    // clang-format off
  }

  enum class DirectoryStatus {
    kExisted,
    kCreated,
    kFailed,
  };

  static DirectoryStatus CheckDir(const std::string& dir) {
    fml::UniqueFD ret =
        fml::OpenDirectory(dir.c_str(), false, fml::FilePermission::kRead);
    if (ret.is_valid()) {
      return DirectoryStatus::kExisted;
    }
    ret =
        fml::OpenDirectory(dir.c_str(), true, fml::FilePermission::kReadWrite);
    if (ret.is_valid()) {
      return DirectoryStatus::kCreated;
    }
    FML_LOG(ERROR) << "Could not create directory (" << dir
                   << ") for impeller failure images" << ", ret = " << ret.get()
                   << ", errno = " << errno;
    return DirectoryStatus::kFailed;
  }

  static void SetupFailureImageDirectory() {
    std::string base_dir = "./failure_images";
    if (CheckDir(base_dir) == DirectoryStatus::kFailed) {
      return;
    }
    for (int i = 0; i < 10000; i++) {
      std::string sub_dir = std::to_string(i);
      while (sub_dir.length() < 4) {
        sub_dir = "0" + sub_dir;
      }
      std::string try_dir = base_dir + "/" + sub_dir;
      switch (CheckDir(try_dir)) {
        case DirectoryStatus::kExisted:
          break;
        case DirectoryStatus::kCreated:
          failure_image_directory_ = try_dir;
          return;
        case DirectoryStatus::kFailed:
          return;
      }
    }
    FML_LOG(ERROR) << "Too many output directories for failure images";
  }

  static void save_to_png(const RenderResult& result,
                          const std::string& op_desc,
                          const std::string& reason) {
    if (!save_failure_images_) {
      return;
    }
    if (failure_image_directory_.length() == 0) {
      SetupFailureImageDirectory();
      if (failure_image_directory_.length() == 0) {
        save_failure_images_ = false;
        return;
      }
    }

    std::string filename = failure_image_directory_ + "/";
    for (const char& ch : op_desc) {
      filename += (ch == ':' || ch == ' ') ? '_' : ch;
    }
    filename = filename + ".png";
    if (!result.pixel_data->write(filename)) {
      FML_LOG(ERROR) << "Could not write output to " << filename;
    }
    failure_image_filenames_.push_back(filename);
    FML_LOG(ERROR) << reason << ": " << filename;
  }

  /// Run a suite of tests on the indicated parameters to determine if the
  /// output matches various expectations, including:
  /// - The rendering does not exceed the bounds computed by the DisplayList
  ///   into which the operation was recorded.
  /// - If the parameters indicate an attribute (color, filter, stroke) or
  ///   and environmental condition (clip, transform, save layer) which
  ///   should affect the rendering, that it does affect the rendering,
  ///   and conversely that it does not if it should not.
  ///
  /// testP - The parameters of the basic rendering operation being tested
  ///         such as DrawRect, DrawPath, DrawText, etc.
  /// env - The parameters of the test environment for this suite of tests
  ///       such as the Surface Provider that determines which backend is
  ///       being used.
  /// tolerance_in - A first approximation of how tight the bounds might
  ///                be for the indicated test and case parameters. Some
  ///                issues that might require a higher bounds tolerance
  ///                would include the fact that text glyphs do not consume
  ///                most of their measured bounds, or that antialiasing is
  ///                enabled which allows pixels outside the theoretical
  ///                bounds of the operation's geometry to be rendered.
  /// caseP - The parameters under which the test is being rendered, which
  ///         includes information such as transform, clip, and attributes.
  static void RenderWith(const TestParameters& testP,
                         const RenderEnvironment& env,
                         const BoundsTolerance& tolerance_in,
                         const CaseParameters& caseP) {
    std::string test_name =
        ::testing::UnitTest::GetInstance()->current_test_info()->name();
    const std::string info =
        env.GetBackendName() + ": " + test_name + " (" + caseP.info() + ")";
    const DlColor bg = caseP.bg();
    RenderJobInfo base_info = {
        .bg = bg,
    };

    // This is the basic rendering of the specified job. We combine the
    // rendering from the test, with the attribute and environment mutations
    // from the case
    DlJobRenderer dl_job(caseP.dl_setup(),     //
                         testP.dl_renderer(),  //
                         caseP.dl_restore());
    RenderResult dl_result = env.GetResult(base_info, dl_job);

    ASSERT_EQ(dl_result.pixel_data->width(), kTestWidth) << info;
    ASSERT_EQ(dl_result.pixel_data->height(), kTestHeight) << info;

    // We construct a display list from the rendering operations which will
    // estimate the bounds we expect from the operation, among other properties.
    const sk_sp<DisplayList> display_list =
        dl_job.MakeDisplayList(env, base_info);

    // We now test the result of rendering the operations to verify that:
    // - it did render something (pixels touched > 0)
    // - no pixels were rendered outside the computed bounds (pixels_oob == 0)
    DlRect dl_bounds = display_list->GetBounds();
    bool success = checkPixels(dl_result, dl_bounds,
                               info + " (DisplayList reference)", bg);

    // Now we test if the operation should have rendered something different
    // compared to the default reference rendering that has no attributes
    // applied. Some operations ignore some attributes and so we need to
    // examine the test case properties to see if the rendering should or
    // should not match the default reference rendering.
    //
    // quickCompareToReference does both jobs (matches or does not match)
    // and we provide it with a boolean indicating if we expect the two
    // results to match and a string that prints out the expectation that
    // was violated.
    if (testP.should_match(env, caseP, dl_job.GetSetupPaint(), dl_job)) {
      success = quickCompareToReference(
                    env.GetReferenceResult(), dl_result, true,
                    info + " (attribute should not have effect)") &&
                success;
    } else {
      success = quickCompareToReference(
                    env.GetReferenceResult(), dl_result, false,
                    info + " (attribute should affect rendering)") &&
                success;
    }

    if (save_failure_images_ && !success) {
      FML_LOG(ERROR) << "Rendering issue encountered for: " << *display_list;
      save_to_png(dl_result, info + " (Test Result)", "output saved in");
      save_to_png(env.GetReferenceResult(), info + " (Test Reference)",
                  "compare to reference without attributes");
    }

    // We now determine if the display list is compatible with distributing
    // a group opacity to its individual rendering operations. If the
    // display list believes that can be done, we double check by asking
    // the canvas to render the display list with a group opacity value
    // and then see if the results really match a faded version of the
    // original rendering results.
    //
    // If the display list does not promise that it can apply group opacity
    // then we do not verify that condition, we allow it the freedom to
    // answer "false" conservatively.
    if (display_list->can_apply_group_opacity()) {
      checkGroupOpacity(env, display_list, dl_result,
                        info + " with Group Opacity", bg);
    }
  }

  static bool fuzzyCompare(uint32_t pixel_a, uint32_t pixel_b, int fudge) {
    for (int i = 0; i < 32; i += 8) {
      int comp_a = (pixel_a >> i) & 0xff;
      int comp_b = (pixel_b >> i) & 0xff;
      if (std::abs(comp_a - comp_b) > fudge) {
        return false;
      }
    }
    return true;
  }

  static int groupOpacityFudgeFactor(const RenderEnvironment& env) {
    if (env.GetPixelFormat() == PixelFormat::k565) {
      return 9;
    }
    if (env.GetProvider()->GetBackendType() == BackendType::kSkiaOpenGL) {
      // OpenGL gets a little fuzzy at times. Still, "within 5" (aka +/-4)
      // for byte samples is not bad, though the other backends give +/-1
      return 5;
    }
    return 2;
  }

  static void checkGroupOpacity(const RenderEnvironment& env,
                                const sk_sp<DisplayList>& display_list,
                                const RenderResult& ref_result,
                                const std::string& info,
                                DlColor bg) {
    DlScalar opacity = 128.0 / 255.0;

    if (opacity > 0) {
      return;
    }
    DisplayListJobRenderer opacity_job(display_list);
    RenderJobInfo opacity_info = {
        .bg = bg,
        .opacity = opacity,
    };
    RenderResult group_opacity_result =
        env.GetResult(opacity_info, opacity_job);

    ASSERT_EQ(group_opacity_result.pixel_data->width(), kTestWidth) << info;
    ASSERT_EQ(group_opacity_result.pixel_data->height(), kTestHeight) << info;

    ASSERT_EQ(ref_result.pixel_data->width(), kTestWidth) << info;
    ASSERT_EQ(ref_result.pixel_data->height(), kTestHeight) << info;

    int pixels_touched = 0;
    int pixels_different = 0;
    int max_diff = 0;
    // We need to allow some slight differences per component due to the
    // fact that rearranging discrete calculations can compound round off
    // errors. Off-by-2 is enough for 8 bit components, but for the 565
    // tests we allow at least 9 which is the maximum distance between
    // samples when converted to 8 bits. (You might think it would be a
    // max step of 8 converting 5 bits to 8 bits, but it is really
    // converting 31 steps to 255 steps with an average step size of
    // 8.23 - 24 of the steps are by 8, but 7 of them are by 9.)
    int fudge = groupOpacityFudgeFactor(env);
    for (uint32_t y = 0; y < kTestHeight; y++) {
      const uint32_t* ref_row = ref_result.pixel_data->addr32(0, y);
      const uint32_t* test_row = group_opacity_result.pixel_data->addr32(0, y);
      for (uint32_t x = 0; x < kTestWidth; x++) {
        uint32_t ref_pixel = ref_row[x];
        uint32_t test_pixel = test_row[x];
        if (ref_pixel != bg.argb() || test_pixel != bg.argb()) {
          pixels_touched++;
          for (int i = 0; i < 32; i += 8) {
            int ref_comp = (ref_pixel >> i) & 0xff;
            int bg_comp = (bg.argb() >> i) & 0xff;
            DlScalar faded_comp = bg_comp + (ref_comp - bg_comp) * opacity;
            int test_comp = (test_pixel >> i) & 0xff;
            if (std::abs(faded_comp - test_comp) > fudge) {
              int diff = std::abs(faded_comp - test_comp);
              if (max_diff < diff) {
                max_diff = diff;
              }
              pixels_different++;
              break;
            }
          }
        }
      }
    }
    ASSERT_GT(pixels_touched, 20) << info;
    if (pixels_different > 1) {
      FML_LOG(ERROR) << "max diff == " << max_diff << " for " << info;
    }
    ASSERT_LE(pixels_different, 1) << info;
  }

  static bool checkPixels(const RenderResult& ref_result,
                          const DlRect ref_bounds,
                          const std::string& info,
                          const DlColor bg = DlColor::kTransparent()) {
    uint32_t untouched = PremultipliedArgb(bg);
    int pixels_touched = 0;
    int pixels_oob = 0;
    DlIRect i_bounds = DlIRect::RoundOut(ref_bounds);
    EXPECT_EQ(ref_result.pixel_data->width(), kTestWidth) << info;
    EXPECT_EQ(ref_result.pixel_data->height(), kTestWidth) << info;
    for (uint32_t y = 0; y < kTestHeight; y++) {
      const uint32_t* ref_row = ref_result.pixel_data->addr32(0, y);
      for (uint32_t x = 0; x < kTestWidth; x++) {
        if (ref_row[x] != untouched) {
          pixels_touched++;
          if (!i_bounds.Contains(DlIPoint(x, y))) {
            pixels_oob++;
          }
        }
      }
    }
    EXPECT_EQ(pixels_oob, 0) << info;
    EXPECT_GT(pixels_touched, 0) << info;
    return pixels_oob == 0 && pixels_touched > 0;
  }

  static int countModifiedTransparentPixels(const RenderResult& ref_result,
                                            const RenderResult& test_result) {
    int count = 0;
    for (uint32_t y = 0; y < kTestHeight; y++) {
      const uint32_t* ref_row = ref_result.pixel_data->addr32(0, y);
      const uint32_t* test_row = test_result.pixel_data->addr32(0, y);
      for (uint32_t x = 0; x < kTestWidth; x++) {
        if (ref_row[x] != test_row[x]) {
          if (ref_row[x] == 0) {
            count++;
          }
        }
      }
    }
    return count;
  }

  static bool quickCompareToReference(const RenderResult& ref_result,
                                      const RenderResult& test_result,
                                      bool should_match,
                                      const std::string& info) {
    uint32_t w = test_result.pixel_data->width();
    uint32_t h = test_result.pixel_data->height();
    EXPECT_EQ(w, ref_result.pixel_data->width()) << info;
    EXPECT_EQ(h, ref_result.pixel_data->height()) << info;
    int pixels_different = 0;
    for (uint32_t y = 0; y < h; y++) {
      const uint32_t* ref_row = ref_result.pixel_data->addr32(0, y);
      const uint32_t* test_row = test_result.pixel_data->addr32(0, y);
      for (uint32_t x = 0; x < w; x++) {
        if (ref_row[x] != test_row[x]) {
          if (should_match && pixels_different < 5) {
            FML_LOG(ERROR) << std::hex << ref_row[x] << " != " << test_row[x];
          }
          pixels_different++;
        }
      }
    }
    if (should_match) {
      EXPECT_EQ(pixels_different, 0) << info;
      return pixels_different == 0;
    } else {
      EXPECT_NE(pixels_different, 0) << info;
      return pixels_different != 0;
    }
  }

  static void compareToReference(const RenderResult& test_result,
                                 const RenderResult& ref_result,
                                 const std::string& info,
                                 const DlRect* bounds,
                                 const BoundsTolerance* tolerance,
                                 const DlColor bg,
                                 bool fuzzyCompares = false,
                                 uint32_t width = kTestWidth,
                                 uint32_t height = kTestHeight,
                                 bool printMismatches = false) {
    uint32_t untouched = PremultipliedArgb(bg);
    ASSERT_EQ(test_result.pixel_data->width(), width) << info;
    ASSERT_EQ(test_result.pixel_data->height(), height) << info;
    DlIRect i_bounds =
        bounds ? DlIRect::RoundOut(*bounds) : DlIRect::MakeWH(width, height);

    int pixels_different = 0;
    int pixels_oob = 0;
    uint32_t min_x = width;
    uint32_t min_y = height;
    uint32_t max_x = 0;
    uint32_t max_y = 0;
    for (uint32_t y = 0; y < height; y++) {
      const uint32_t* ref_row = ref_result.pixel_data->addr32(0, y);
      const uint32_t* test_row = test_result.pixel_data->addr32(0, y);
      for (uint32_t x = 0; x < width; x++) {
        if (bounds && test_row[x] != untouched) {
          if (min_x > x) {
            min_x = x;
          }
          if (min_y > y) {
            min_y = y;
          }
          if (max_x <= x) {
            max_x = x + 1;
          }
          if (max_y <= y) {
            max_y = y + 1;
          }
          if (!i_bounds.Contains(DlIPoint(x, y))) {
            pixels_oob++;
          }
        }
        bool match = fuzzyCompares ? fuzzyCompare(test_row[x], ref_row[x], 1)
                                   : test_row[x] == ref_row[x];
        if (!match) {
          if (printMismatches && pixels_different < 5) {
            FML_LOG(ERROR) << "pix[" << x << ", " << y
                           << "] mismatch: " << std::hex << test_row[x]
                           << "(test) != (ref)" << ref_row[x] << std::dec;
          }
          pixels_different++;
        }
      }
    }
    if (pixels_oob > 0) {
      FML_LOG(ERROR) << "pix bounds["
                     << DlIRect::MakeLTRB(min_x, min_y, max_x, max_y)  //
                     << "]";
      FML_LOG(ERROR) << "dl_bounds[" << bounds << "]";
    } else if (bounds) {
      showBoundsOverflow(info, i_bounds, tolerance, min_x, min_y, max_x, max_y);
    }
    ASSERT_EQ(pixels_oob, 0) << info;
    ASSERT_EQ(pixels_different, 0) << info;
  }

  static void showBoundsOverflow(const std::string& info,
                                 DlIRect& bounds,
                                 const BoundsTolerance* tolerance,
                                 int pixLeft,
                                 int pixTop,
                                 int pixRight,
                                 int pixBottom) {
    int pad_left = std::max(0, pixLeft - bounds.GetLeft());
    int pad_top = std::max(0, pixTop - bounds.GetTop());
    int pad_right = std::max(0, bounds.GetRight() - pixRight);
    int pad_bottom = std::max(0, bounds.GetBottom() - pixBottom);
    DlIRect pix_bounds =
        DlIRect::MakeLTRB(pixLeft, pixTop, pixRight, pixBottom);
    DlISize pix_size = pix_bounds.GetSize();
    int pix_width = pix_size.width;
    int pix_height = pix_size.height;
    int worst_pad_x = std::max(pad_left, pad_right);
    int worst_pad_y = std::max(pad_top, pad_bottom);
    if (tolerance->overflows(pix_bounds, worst_pad_x, worst_pad_y)) {
      FML_LOG(ERROR) << "Computed bounds for " << info;
      FML_LOG(ERROR) << "pix bounds["                        //
                     << pixLeft << ", " << pixTop << " => "  //
                     << pixRight << ", " << pixBottom        //
                     << "]";
      FML_LOG(ERROR) << "dl_bounds[" << bounds << "]";
      FML_LOG(ERROR) << "Bounds overly conservative by up to "     //
                     << worst_pad_x << ", " << worst_pad_y         //
                     << " (" << (worst_pad_x * 100.0 / pix_width)  //
                     << "%, " << (worst_pad_y * 100.0 / pix_height) << "%)";
      int pix_area = pix_size.Area();
      int dl_area = bounds.Area();
      FML_LOG(ERROR) << "Total overflow area: " << (dl_area - pix_area)  //
                     << " (+" << (dl_area * 100.0 / pix_area - 100.0)    //
                     << "% larger)";
      FML_LOG(ERROR);
    }
  }
};

std::string CanvasCompareTester::failure_image_directory_ = "";
bool CanvasCompareTester::save_failure_images_ = false;
std::vector<std::string> CanvasCompareTester::failure_image_filenames_;

BoundsTolerance CanvasCompareTester::DefaultTolerance =
    BoundsTolerance().addAbsolutePadding(1, 1);

// Eventually this bare bones testing::Test fixture will subsume the
// CanvasCompareTester and the TestParameters could then become just
// configuration calls made upon the fixture.
class DisplayListRendering : public ::testing::Test,
                             protected DisplayListOpFlags {
 public:
  DisplayListRendering() = default;

  static void SetUpTestSuite() {
    // Multiple test suites use this test base. Make sure that they don't
    // double-register the supported providers.
    test_backends_.clear();

    std::vector<std::string> args = ::testing::internal::GetArgvs();
    fml::CommandLine command_line =
        fml::CommandLineFromIterators(args.begin(), args.end());

    if (command_line.HasOption("--save-failure-images")) {
      CanvasCompareTester::EnableSaveImagesOnFailures();
    }

    std::vector<BackendType> enable_backends =
        ParseBackendList(command_line.GetOptionValues("enable"));
    for (BackendType backend : enable_backends) {
      AddProvider(backend);
    }

    std::vector<BackendType> disable_backends =
        ParseBackendList(command_line.GetOptionValues("disable"));
    for (BackendType backend : disable_backends) {
      RemoveProvider(backend);
    }

    if (GetTestBackends().empty()) {
      AddProvider(BackendType::kSkiaSoftware);
    }

    std::string providers = "";
    for (BackendType back_end : GetTestBackends()) {
      providers += " " + DlSurfaceProvider::BackendName(back_end);
    }
    FML_LOG(INFO) << "Running tests on [" << providers << " ]";
  }

  static void TearDownTestSuite() {
    CanvasCompareTester::PrintFailureImageFileNames();
  }

  static const std::vector<BackendType>& GetTestBackends() {
    return test_backends_;
  }

  static std::unique_ptr<DlSurfaceProvider> GetProvider(BackendType type) {
    std::unique_ptr<DlSurfaceProvider> provider =
        DlSurfaceProvider::Create(type);
    if (provider == nullptr) {
      FML_LOG(ERROR) << "provider " << DlSurfaceProvider::BackendName(type)
                     << " not supported (ignoring)";
      return nullptr;
    }
    provider->InitializeSurface(kTestWidth, kTestHeight,
                                PixelFormat::kN32Premul);
    return provider;
  }

  static void RenderAll(const TestParameters& params,
                        const BoundsTolerance& tolerance =
                            CanvasCompareTester::DefaultTolerance) {
    for (BackendType backend : test_backends_) {
      std::unique_ptr<DlSurfaceProvider> provider = GetProvider(backend);
      CanvasCompareTester::RenderAll(provider, params, tolerance);
    }
  }

 private:
  static std::vector<BackendType> test_backends_;

  static bool AddProvider(BackendType type) {
    std::unique_ptr<DlSurfaceProvider> provider = GetProvider(type);
    if (!provider) {
      // Error already reported by GetProvider.
      return false;
    }
    for (BackendType existing : test_backends_) {
      if (existing == type) {
        FML_LOG(ERROR) << "Backend " << provider->GetBackendName()
                       << " already added";
        return false;
      }
    }
    test_backends_.push_back(type);
    return true;
  }

  static bool RemoveProvider(BackendType type) {
    std::unique_ptr<DlSurfaceProvider> provider = GetProvider(type);
    if (!provider) {
      // Error already reported by GetProvider.
      return false;
    }
    for (auto it = test_backends_.begin(); it < test_backends_.end(); it++) {
      if (*it == type) {
        test_backends_.erase(it);
        return true;
      }
    }
    FML_LOG(ERROR) << "Backend " << provider->GetBackendName()
                   << " was not present to remove";
    return false;
  }

  static std::vector<BackendType> ParseBackendList(
      const std::vector<std::string_view>& arg_list) {
    std::vector<BackendType> value_list;
    for (const std::string_view& name_list : arg_list) {
      std::vector<std::string> names = absl::StrSplit(name_list, ',');
      for (const std::string& name : names) {
        std::optional<BackendType> backend =
            DlSurfaceProvider::NameToBackend(name);
        if (backend.has_value()) {
          value_list.push_back(backend.value());
        } else {
          FML_LOG(ERROR) << "Unrecognized backend name: " << name;
        }
      }
    }
    return value_list;
  }

  FML_DISALLOW_COPY_AND_ASSIGN(DisplayListRendering);
};

std::vector<BackendType> DisplayListRendering::test_backends_;

TEST_F(DisplayListRendering, DrawPaint) {
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawPaint(ctx.paint);
          },
          kDrawPaintFlags));
}

TEST_F(DisplayListRendering, DrawOpaqueColor) {
  // We use a non-opaque color to avoid obliterating any backdrop filter output
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            // DrawColor is not tested against attributes because it is supposed
            // to ignore them. So, if the paint has an alpha, it is because we
            // are doing a saveLayer+backdrop test and we need to not flood over
            // the backdrop output with a solid color. So, we transfer the alpha
            // from the paint for that case only.
            ctx.canvas->DrawColor(
                DlColor::kMagenta().withAlpha(ctx.paint.getAlpha()));
          },
          kDrawColorFlags));
}

TEST_F(DisplayListRendering, DrawAlphaColor) {
  // We use a non-opaque color to avoid obliterating any backdrop filter output
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawColor(DlColor(0x7FFF00FF));
          },
          kDrawColorFlags));
}

TEST_F(DisplayListRendering, DrawDiagonalLines) {
  DlPoint p1 = DlPoint(kRenderLeft, kRenderTop);
  DlPoint p2 = DlPoint(kRenderRight, kRenderBottom);
  DlPoint p3 = DlPoint(kRenderLeft, kRenderBottom);
  DlPoint p4 = DlPoint(kRenderRight, kRenderTop);
  // Adding some edge to edge diagonals that run through the points about
  // 16 units in from the center of that edge.
  // Adding some edge center to edge center diagonals to better fill
  // out the RRect Clip so bounds checking sees less empty bounds space.
  DlPoint p5 = DlPoint(kRenderCenterX, kRenderTop + 15);
  DlPoint p6 = DlPoint(kRenderRight - 15, kRenderCenterY);
  DlPoint p7 = DlPoint(kRenderCenterX, kRenderBottom - 15);
  DlPoint p8 = DlPoint(kRenderLeft + 15, kRenderCenterY);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawLine(p1, p2, ctx.paint);
            ctx.canvas->DrawLine(p3, p4, ctx.paint);
            ctx.canvas->DrawLine(p5, p6, ctx.paint);
            ctx.canvas->DrawLine(p7, p8, ctx.paint);
          },
          kDrawLineFlags)
          .set_draw_line());
}

TEST_F(DisplayListRendering, DrawHorizontalLines) {
  DlPoint p1 = DlPoint(kRenderLeft, kRenderTop + 16);
  DlPoint p2 = DlPoint(kRenderRight, kRenderTop + 16);
  DlPoint p3 = DlPoint(kRenderLeft, kRenderCenterY);
  DlPoint p4 = DlPoint(kRenderRight, kRenderCenterY);
  DlPoint p5 = DlPoint(kRenderLeft, kRenderBottom - 16);
  DlPoint p6 = DlPoint(kRenderRight, kRenderBottom - 16);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawLine(p1, p2, ctx.paint);
            ctx.canvas->DrawLine(p3, p4, ctx.paint);
            ctx.canvas->DrawLine(p5, p6, ctx.paint);
          },
          kDrawHVLineFlags)
          .set_draw_line()
          .set_horizontal_line());
}

TEST_F(DisplayListRendering, DrawVerticalLines) {
  DlPoint p1 = DlPoint(kRenderLeft + 16, kRenderTop);
  DlPoint p2 = DlPoint(kRenderLeft + 16, kRenderBottom);
  DlPoint p3 = DlPoint(kRenderCenterX, kRenderTop);
  DlPoint p4 = DlPoint(kRenderCenterX, kRenderBottom);
  DlPoint p5 = DlPoint(kRenderRight - 16, kRenderTop);
  DlPoint p6 = DlPoint(kRenderRight - 16, kRenderBottom);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawLine(p1, p2, ctx.paint);
            ctx.canvas->DrawLine(p3, p4, ctx.paint);
            ctx.canvas->DrawLine(p5, p6, ctx.paint);
          },
          kDrawHVLineFlags)
          .set_draw_line()
          .set_vertical_line());
}

TEST_F(DisplayListRendering, DrawDiagonalDashedLines) {
  DlPoint p1 = DlPoint(kRenderLeft, kRenderTop);
  DlPoint p2 = DlPoint(kRenderRight, kRenderBottom);
  DlPoint p3 = DlPoint(kRenderLeft, kRenderBottom);
  DlPoint p4 = DlPoint(kRenderRight, kRenderTop);
  // Adding some edge to edge diagonals that run through the points about
  // 16 units in from the center of that edge.
  // Adding some edge center to edge center diagonals to better fill
  // out the RRect Clip so bounds checking sees less empty bounds space.
  DlPoint p5 = DlPoint(kRenderCenterX, kRenderTop + 15);
  DlPoint p6 = DlPoint(kRenderRight - 15, kRenderCenterY);
  DlPoint p7 = DlPoint(kRenderCenterX, kRenderBottom - 15);
  DlPoint p8 = DlPoint(kRenderLeft + 15, kRenderCenterY);

  // Full diagonals are 100x100 which are 140 in length
  // Dashing them with 25 on, 5 off means that the last
  // dash goes from 120 to 145 which means both ends of the
  // diagonals will be in an "on" dash for maximum bounds

  // Edge to edge diagonals are 50x50 which are 70 in length
  // Dashing them with 25 on, 5 off means that the last
  // dash goes from 60 to 85 which means both ends of the
  // edge diagonals will be in a dash segment

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawDashedLine(p1, p2, 25.0f, 5.0f, ctx.paint);
            ctx.canvas->DrawDashedLine(p3, p4, 25.0f, 5.0f, ctx.paint);
            ctx.canvas->DrawDashedLine(p5, p6, 25.0f, 5.0f, ctx.paint);
            ctx.canvas->DrawDashedLine(p7, p8, 25.0f, 5.0f, ctx.paint);
          },
          kDrawLineFlags)
          .set_draw_line());
}

TEST_F(DisplayListRendering, DrawRect) {
  // Bounds are offset by 0.5 pixels to induce AA
  DlRect rect = kRenderBounds.Shift(0.5f, 0.5f);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawRect(rect, ctx.paint);
          },
          kDrawRectFlags));
}

TEST_F(DisplayListRendering, DrawOval) {
  DlRect rect = kRenderBounds.Expand(0, -10);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawOval(rect, ctx.paint);
          },
          kDrawOvalFlags));
}

TEST_F(DisplayListRendering, DrawCircle) {
  DlPoint center = kRenderBounds.GetCenter();

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawCircle(center, kRenderRadius, ctx.paint);
          },
          kDrawCircleFlags));
}

TEST_F(DisplayListRendering, DrawRoundRect) {
  DlRoundRect rrect = DlRoundRect::MakeRectXY(kRenderBounds,        //
                                              kRenderCornerRadius,  //
                                              kRenderCornerRadius);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawRoundRect(rrect, ctx.paint);
          },
          kDrawRRectFlags));
}

TEST_F(DisplayListRendering, DrawDiffRoundRect) {
  DlRoundRect outer = DlRoundRect::MakeRectXY(kRenderBounds,        //
                                              kRenderCornerRadius,  //
                                              kRenderCornerRadius);
  DlRect inner_bounds = kRenderBounds.Expand(-30.0f, -30.0f);
  DlRoundRect inner = DlRoundRect::MakeRectXY(inner_bounds,         //
                                              kRenderCornerRadius,  //
                                              kRenderCornerRadius);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawDiffRoundRect(outer, inner, ctx.paint);
          },
          kDrawDRRectFlags));
}

TEST_F(DisplayListRendering, DrawPath) {
  DlPathBuilder path_builder;

  // unclosed lines to show some caps
  path_builder.MoveTo(DlPoint(kRenderLeft + 15, kRenderTop + 15));
  path_builder.LineTo(DlPoint(kRenderRight - 15, kRenderBottom - 15));
  path_builder.MoveTo(DlPoint(kRenderLeft + 15, kRenderBottom - 15));
  path_builder.LineTo(DlPoint(kRenderRight - 15, kRenderTop + 15));

  path_builder.AddRect(kRenderBounds);

  // miter diamonds horizontally and vertically to show miters
  path_builder.MoveTo(kVerticalMiterDiamondPoints[0]);
  for (int i = 1; i < kVerticalMiterDiamondPointCount; i++) {
    path_builder.LineTo(kVerticalMiterDiamondPoints[i]);
  }
  path_builder.Close();
  path_builder.MoveTo(kHorizontalMiterDiamondPoints[0]);
  for (int i = 1; i < kHorizontalMiterDiamondPointCount; i++) {
    path_builder.LineTo(kHorizontalMiterDiamondPoints[i]);
  }
  path_builder.Close();

  DlPath path = path_builder.TakePath();

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawPath(path, ctx.paint);
          },
          kDrawPathFlags)
          .set_draw_path());
}

TEST_F(DisplayListRendering, DrawArc) {
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawArc(kRenderBounds, 60, 330, false, ctx.paint);
          },
          kDrawArcNoCenterFlags));
}

TEST_F(DisplayListRendering, DrawArcCenter) {
  // Center arcs that inscribe nearly a whole circle except for a small
  // arc extent gap have 2 angles that may appear or disappear at the
  // various miter limits tested (0, 4, and 10).
  // The center angle here is 12 degrees which shows a miter
  // at limit=10, but not 0 or 4.
  // The arcs at the corners where it turns in towards the
  // center show miters at 4 and 10, but not 0.
  // Limit == 0, neither corner does a miter
  // Limit == 4, only the edge "turn-in" corners miter
  // Limit == 10, edge and center corners all miter
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawArc(kRenderBounds, 60, 360 - 12, true, ctx.paint);
          },
          kDrawArcWithCenterFlags)
          .set_draw_arc_center());
}

TEST_F(DisplayListRendering, DrawPointsAsPoints) {
  // The +/- 16 points are designed to fall just inside the clips
  // that are tested against so we avoid lots of undrawn pixels
  // in the accumulated bounds.
  const DlScalar x0 = kRenderLeft;
  const DlScalar x1 = kRenderLeft + 16;
  const DlScalar x2 = (kRenderLeft + kRenderCenterX) * 0.5;
  const DlScalar x3 = kRenderCenterX + 0.1;
  const DlScalar x4 = (kRenderRight + kRenderCenterX) * 0.5;
  const DlScalar x5 = kRenderRight - 16;
  const DlScalar x6 = kRenderRight - 1;

  const DlScalar y0 = kRenderTop;
  const DlScalar y1 = kRenderTop + 16;
  const DlScalar y2 = (kRenderTop + kRenderCenterY) * 0.5;
  const DlScalar y3 = kRenderCenterY + 0.1;
  const DlScalar y4 = (kRenderBottom + kRenderCenterY) * 0.5;
  const DlScalar y5 = kRenderBottom - 16;
  const DlScalar y6 = kRenderBottom - 1;

  // clang-format off
  const DlPoint points[] = {
      {x0, y0}, {x1, y0}, {x2, y0}, {x3, y0}, {x4, y0}, {x5, y0}, {x6, y0},
      {x0, y1}, {x1, y1}, {x2, y1}, {x3, y1}, {x4, y1}, {x5, y1}, {x6, y1},
      {x0, y2}, {x1, y2}, {x2, y2}, {x3, y2}, {x4, y2}, {x5, y2}, {x6, y2},
      {x0, y3}, {x1, y3}, {x2, y3}, {x3, y3}, {x4, y3}, {x5, y3}, {x6, y3},
      {x0, y4}, {x1, y4}, {x2, y4}, {x3, y4}, {x4, y4}, {x5, y4}, {x6, y4},
      {x0, y5}, {x1, y5}, {x2, y5}, {x3, y5}, {x4, y5}, {x5, y5}, {x6, y5},
      {x0, y6}, {x1, y6}, {x2, y6}, {x3, y6}, {x4, y6}, {x5, y6}, {x6, y6},
  };
  // clang-format on
  const int count = sizeof(points) / sizeof(points[0]);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            DlPointMode mode = DlPointMode::kPoints;
            ctx.canvas->DrawPoints(mode, count, points, ctx.paint);
          },
          kDrawPointsAsPointsFlags)
          .set_draw_line()
          .set_ignores_dashes());
}

TEST_F(DisplayListRendering, DrawPointsAsLines) {
  const DlScalar x0 = kRenderLeft + 1;
  const DlScalar x1 = kRenderLeft + 16;
  const DlScalar x2 = kRenderRight - 16;
  const DlScalar x3 = kRenderRight - 1;

  const DlScalar y0 = kRenderTop;
  const DlScalar y1 = kRenderTop + 16;
  const DlScalar y2 = kRenderBottom - 16;
  const DlScalar y3 = kRenderBottom - 1;

  // clang-format off
  const DlPoint points[] = {
      // Outer box
      {x0, y0}, {x3, y0},
      {x3, y0}, {x3, y3},
      {x3, y3}, {x0, y3},
      {x0, y3}, {x0, y0},

      // Diagonals
      {x0, y0}, {x3, y3}, {x3, y0}, {x0, y3},

      // Inner box
      {x1, y1}, {x2, y1},
      {x2, y1}, {x2, y2},
      {x2, y2}, {x1, y2},
      {x1, y2}, {x1, y1},
  };
  // clang-format on

  const int count = sizeof(points) / sizeof(points[0]);
  ASSERT_TRUE((count & 1) == 0);
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            DlPointMode mode = DlPointMode::kLines;
            ctx.canvas->DrawPoints(mode, count, points, ctx.paint);
          },
          kDrawPointsAsLinesFlags));
}

TEST_F(DisplayListRendering, DrawPointsAsPolygon) {
  const DlPoint points1[] = {
      // RenderBounds box with a diamond
      DlPoint(kRenderLeft, kRenderTop),
      DlPoint(kRenderRight, kRenderTop),
      DlPoint(kRenderRight, kRenderBottom),
      DlPoint(kRenderLeft, kRenderBottom),
      DlPoint(kRenderLeft, kRenderTop),

      DlPoint(kRenderCenterX, kRenderTop + 15),
      DlPoint(kRenderRight - 15, kRenderCenterY),
      DlPoint(kRenderCenterX, kRenderBottom - 15),
      DlPoint(kRenderLeft + 15, kRenderCenterY),
      DlPoint(kRenderCenterX, kRenderTop + 15),
  };
  const int count1 = sizeof(points1) / sizeof(points1[0]);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            DlPointMode mode = DlPointMode::kPolygon;
            ctx.canvas->DrawPoints(mode, count1, points1, ctx.paint);
          },
          kDrawPointsAsPolygonFlags));
}

TEST_F(DisplayListRendering, DrawVerticesWithColors) {
  // Cover as many sides of the box with only 6 vertices:
  // +----------+
  // |xxxxxxxxxx|
  // |    xxxxxx|
  // |       xxx|
  // |xxx       |
  // |xxxxxx    |
  // |xxxxxxxxxx|
  // +----------|
  const DlPoint pts[6] = {
      // Upper-Right corner, full top, half right coverage
      DlPoint(kRenderLeft, kRenderTop),
      DlPoint(kRenderRight, kRenderTop),
      DlPoint(kRenderRight, kRenderCenterY),
      // Lower-Left corner, full bottom, half left coverage
      DlPoint(kRenderLeft, kRenderBottom),
      DlPoint(kRenderLeft, kRenderCenterY),
      DlPoint(kRenderRight, kRenderBottom),
  };
  const DlColor dl_colors[6] = {
      DlColor::kRed(),  DlColor::kBlue(),   DlColor::kGreen(),
      DlColor::kCyan(), DlColor::kYellow(), DlColor::kMagenta(),
  };
  const std::shared_ptr<DlVertices> dl_vertices =
      DlVertices::Make(DlVertexMode::kTriangles, 6, pts, nullptr, dl_colors);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawVertices(dl_vertices, DlBlendMode::kSrcOver,
                                     ctx.paint);
          },
          kDrawVerticesFlags));
}

TEST_F(DisplayListRendering, DrawVerticesWithImage) {
  // Cover as many sides of the box with only 6 vertices:
  // +----------+
  // |xxxxxxxxxx|
  // |    xxxxxx|
  // |       xxx|
  // |xxx       |
  // |xxxxxx    |
  // |xxxxxxxxxx|
  // +----------|
  const DlPoint pts[6] = {
      // Upper-Right corner, full top, half right coverage
      DlPoint(kRenderLeft, kRenderTop),
      DlPoint(kRenderRight, kRenderTop),
      DlPoint(kRenderRight, kRenderCenterY),
      // Lower-Left corner, full bottom, half left coverage
      DlPoint(kRenderLeft, kRenderBottom),
      DlPoint(kRenderLeft, kRenderCenterY),
      DlPoint(kRenderRight, kRenderBottom),
  };
  const DlPoint tex[6] = {
      DlPoint(kRenderWidth / 2.0, 0),
      DlPoint(0, kRenderHeight),
      DlPoint(kRenderWidth, kRenderHeight),
      DlPoint(kRenderWidth / 2, kRenderHeight),
      DlPoint(0, 0),
      DlPoint(kRenderWidth, 0),
  };
  const std::shared_ptr<DlVertices> dl_vertices =
      DlVertices::Make(DlVertexMode::kTriangles, 6, pts, tex, nullptr);

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            DlPaint v_paint = ctx.paint;
            if (v_paint.getColorSource() == nullptr) {
              v_paint.setColorSource(MakeColorSource(ctx.env.GetTestImage()));
            }
            ctx.canvas->DrawVertices(dl_vertices, DlBlendMode::kSrcOver,
                                     v_paint);
          },
          kDrawVerticesFlags));
}

TEST_F(DisplayListRendering, DrawImageNearest) {
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawImage(
                ctx.env.GetTestImage(), DlPoint(kRenderLeft, kRenderTop),
                DlImageSampling::kNearestNeighbor, &ctx.paint);
          },
          kDrawImageWithPaintFlags));
}

TEST_F(DisplayListRendering, DrawImageNearestNoPaint) {
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawImage(ctx.env.GetTestImage(),
                                  DlPoint(kRenderLeft, kRenderTop),
                                  DlImageSampling::kNearestNeighbor, nullptr);
          },
          kDrawImageFlags));
}

TEST_F(DisplayListRendering, DrawImageLinear) {
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawImage(ctx.env.GetTestImage(),
                                  DlPoint(kRenderLeft, kRenderTop),
                                  DlImageSampling::kLinear, &ctx.paint);
          },
          kDrawImageWithPaintFlags));
}

TEST_F(DisplayListRendering, DrawImageRectNearest) {
  DlRect src = DlRect::MakeWH(kRenderWidth, kRenderHeight).Expand(-5, -5);
  DlRect dst = kRenderBounds.Expand(-10.5f, -10.5f);
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawImageRect(ctx.env.GetTestImage(), src, dst,
                                      DlImageSampling::kNearestNeighbor,
                                      &ctx.paint, DlSrcRectConstraint::kFast);
          },
          kDrawImageRectWithPaintFlags));
}

TEST_F(DisplayListRendering, DrawImageRectNearestNoPaint) {
  DlRect src = DlRect::MakeWH(kRenderWidth, kRenderHeight).Expand(-5, -5);
  DlRect dst = kRenderBounds.Expand(-10.5f, -10.5f);
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawImageRect(ctx.env.GetTestImage(), src, dst,
                                      DlImageSampling::kNearestNeighbor,  //
                                      nullptr, DlSrcRectConstraint::kFast);
          },
          kDrawImageRectFlags));
}

TEST_F(DisplayListRendering, DrawImageRectLinear) {
  DlRect src = DlRect::MakeWH(kRenderWidth, kRenderHeight).Expand(-5, -5);
  DlRect dst = kRenderBounds.Expand(-10.5f, -10.5f);
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawImageRect(ctx.env.GetTestImage(), src, dst,
                                      DlImageSampling::kLinear,  //
                                      &ctx.paint, DlSrcRectConstraint::kFast);
          },
          kDrawImageRectWithPaintFlags));
}

TEST_F(DisplayListRendering, DrawImageNineNearest) {
  DlIRect src = DlIRect::MakeWH(kRenderWidth, kRenderHeight).Expand(-25, -25);
  DlRect dst = kRenderBounds.Expand(-10.5f, -10.5f);
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawImageNine(ctx.env.GetTestImage(), src, dst,
                                      DlFilterMode::kNearest, &ctx.paint);
          },
          kDrawImageNineWithPaintFlags));
}

TEST_F(DisplayListRendering, DrawImageNineNearestNoPaint) {
  DlIRect src = DlIRect::MakeWH(kRenderWidth, kRenderHeight).Expand(-25, -25);
  DlRect dst = kRenderBounds.Expand(-10.5f, -10.5f);
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawImageNine(ctx.env.GetTestImage(), src, dst,
                                      DlFilterMode::kNearest, nullptr);
          },
          kDrawImageNineFlags));
}

TEST_F(DisplayListRendering, DrawImageNineLinear) {
  DlIRect src = DlIRect::MakeWH(kRenderWidth, kRenderHeight).Expand(-25, -25);
  DlRect dst = kRenderBounds.Expand(-10.5f, -10.5f);
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawImageNine(ctx.env.GetTestImage(), src, dst,
                                      DlFilterMode::kLinear, &ctx.paint);
          },
          kDrawImageNineWithPaintFlags));
}

TEST_F(DisplayListRendering, DrawAtlasNearest) {
  auto relative_rect = [](DlScalar relative_left, DlScalar relative_top,
                          DlScalar relative_right,
                          DlScalar relative_bottom) -> DlRect {
    return DlRect::MakeLTRB(
        kRenderWidth * relative_left, kRenderHeight * relative_top,
        kRenderWidth * relative_right, kRenderHeight * relative_bottom);
  };

  const DlRSTransform dl_xform[] = {
      // clang-format off
      { 1.2f,  0.0f, kRenderLeft,  kRenderTop},
      { 0.0f,  1.2f, kRenderRight, kRenderTop},
      {-1.2f,  0.0f, kRenderRight, kRenderBottom},
      { 0.0f, -1.2f, kRenderLeft,  kRenderBottom},
      // clang-format on
  };
  const DlRect tex[] = {
      relative_rect(0.0f, 0.0f, 0.5f, 0.5f),
      relative_rect(0.5f, 0.0f, 1.0f, 0.5f),
      relative_rect(0.5f, 0.5f, 1.0f, 1.0f),
      relative_rect(0.0f, 0.5f, 0.5f, 1.0f),
  };
  const DlColor dl_colors[] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::kYellow(),
      DlColor::kMagenta(),
  };
  const DlImageSampling dl_sampling = DlImageSampling::kNearestNeighbor;
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawAtlas(ctx.env.GetTestImage(), dl_xform, tex,
                                  dl_colors, 4, DlBlendMode::kSrcOver,
                                  dl_sampling, nullptr, &ctx.paint);
          },
          kDrawAtlasWithPaintFlags));
}

TEST_F(DisplayListRendering, DrawAtlasNearestNoPaint) {
  auto relative_rect = [](DlScalar relative_left, DlScalar relative_top,
                          DlScalar relative_right,
                          DlScalar relative_bottom) -> DlRect {
    return DlRect::MakeLTRB(
        kRenderWidth * relative_left, kRenderHeight * relative_top,
        kRenderWidth * relative_right, kRenderHeight * relative_bottom);
  };

  const DlRSTransform dl_xform[] = {
      // clang-format off
      { 1.2f,  0.0f, kRenderLeft,  kRenderTop},
      { 0.0f,  1.2f, kRenderRight, kRenderTop},
      {-1.2f,  0.0f, kRenderRight, kRenderBottom},
      { 0.0f, -1.2f, kRenderLeft,  kRenderBottom},
      // clang-format on
  };
  const DlRect tex[] = {
      relative_rect(0.0f, 0.0f, 0.5f, 0.5f),
      relative_rect(0.5f, 0.0f, 1.0f, 0.5f),
      relative_rect(0.5f, 0.5f, 1.0f, 1.0f),
      relative_rect(0.0f, 0.5f, 0.5f, 1.0f),
  };
  const DlColor dl_colors[] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::kYellow(),
      DlColor::kMagenta(),
  };
  const DlImageSampling dl_sampling = DlImageSampling::kNearestNeighbor;
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawAtlas(ctx.env.GetTestImage(), dl_xform, tex,
                                  dl_colors, 4, DlBlendMode::kSrcOver,
                                  dl_sampling, nullptr, nullptr);
          },
          kDrawAtlasFlags));
}

TEST_F(DisplayListRendering, DrawAtlasLinear) {
  auto relative_rect = [](DlScalar relative_left, DlScalar relative_top,
                          DlScalar relative_right,
                          DlScalar relative_bottom) -> DlRect {
    return DlRect::MakeLTRB(
        kRenderWidth * relative_left, kRenderHeight * relative_top,
        kRenderWidth * relative_right, kRenderHeight * relative_bottom);
  };

  const DlRSTransform dl_xform[] = {
      // clang-format off
      { 1.2f,  0.0f, kRenderLeft,  kRenderTop},
      { 0.0f,  1.2f, kRenderRight, kRenderTop},
      {-1.2f,  0.0f, kRenderRight, kRenderBottom},
      { 0.0f, -1.2f, kRenderLeft,  kRenderBottom},
      // clang-format on
  };
  const DlRect tex[] = {
      relative_rect(0.0f, 0.0f, 0.5f, 0.5f),
      relative_rect(0.5f, 0.0f, 1.0f, 0.5f),
      relative_rect(0.5f, 0.5f, 1.0f, 1.0f),
      relative_rect(0.0f, 0.5f, 0.5f, 1.0f),
  };
  const DlColor dl_colors[] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::kYellow(),
      DlColor::kMagenta(),
  };
  const DlImageSampling dl_sampling = DlImageSampling::kLinear;
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            ctx.canvas->DrawAtlas(ctx.env.GetTestImage(), dl_xform, tex,
                                  dl_colors, 2, DlBlendMode::kSrcOver,
                                  dl_sampling, nullptr, &ctx.paint);
          },
          kDrawAtlasWithPaintFlags));
}

sk_sp<DisplayList> makeTestDisplayList() {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setDrawStyle(DlDrawStyle::kFill);
  paint.setColor(DlColor(SK_ColorRED));
  builder.DrawRect(DlRect::MakeLTRB(kRenderLeft, kRenderTop,  //
                                    kRenderCenterX, kRenderCenterY),
                   paint);
  paint.setColor(DlColor(SK_ColorBLUE));
  builder.DrawRect(DlRect::MakeLTRB(kRenderCenterX, kRenderTop,  //
                                    kRenderRight, kRenderCenterY),
                   paint);
  paint.setColor(DlColor(SK_ColorGREEN));
  builder.DrawRect(DlRect::MakeLTRB(kRenderLeft, kRenderCenterY,  //
                                    kRenderCenterX, kRenderBottom),
                   paint);
  paint.setColor(DlColor(SK_ColorYELLOW));
  builder.DrawRect(DlRect::MakeLTRB(kRenderCenterX, kRenderCenterY,  //
                                    kRenderRight, kRenderBottom),
                   paint);
  return builder.Build();
}

TEST_F(DisplayListRendering, DrawDisplayList) {
  sk_sp<DisplayList> display_list = makeTestDisplayList();
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawDisplayList(display_list);
          },
          kDrawDisplayListFlags)
          .set_draw_display_list());
}

TEST_F(DisplayListRendering, DrawText) {
  // TODO(https://github.com/flutter/flutter/issues/82202): Remove once the
  // performance overlay can use Fuchsia's font manager instead of the empty
  // default.
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Rendering comparisons require a valid default font manager";
#else
  DlScalar render_y_1_3 = kRenderTop + kRenderHeight * 0.3;
  DlScalar render_y_2_3 = kRenderTop + kRenderHeight * 0.6;
  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {
            DlPaint paint = ctx.paint;
            ctx.canvas->DrawText(ctx.env.GetTestText(), kRenderLeft,
                                 render_y_1_3, paint);
            ctx.canvas->DrawText(ctx.env.GetTestText(), kRenderLeft,
                                 render_y_2_3, paint);
            ctx.canvas->DrawText(ctx.env.GetTestText(), kRenderLeft,
                                 kRenderBottom, paint);
          },
          kDrawTextFlags)
          .set_draw_text_blob(),
      // From examining the bounds differential for the "Default" case, the
      // SkTextBlob adds a padding of ~32 on the left, ~30 on the right,
      // ~12 on top and ~8 on the bottom, so we add 33h & 13v allowed
      // padding to the tolerance
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(33, 13));
#endif  // OS_FUCHSIA
}

TEST_F(DisplayListRendering, DrawShadow) {
  DlPathBuilder path_builder;
  path_builder.AddRoundRect(DlRoundRect::MakeRectXY(
      DlRect::MakeLTRB(kRenderLeft + 10, kRenderTop,  //
                       kRenderRight - 10, kRenderBottom - 20),
      kRenderCornerRadius, kRenderCornerRadius));
  DlPath path = path_builder.TakePath();

  const DlColor color = DlColor::kDarkGrey();
  const DlScalar elevation = 7;

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawShadow(path, color, elevation, false, 1.0);
          },
          kDrawShadowFlags),
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

TEST_F(DisplayListRendering, DrawShadowTransparentOccluder) {
  DlPathBuilder path_builder;
  path_builder.AddRoundRect(DlRoundRect::MakeRectXY(
      DlRect::MakeLTRB(kRenderLeft + 10, kRenderTop,  //
                       kRenderRight - 10, kRenderBottom - 20),
      kRenderCornerRadius, kRenderCornerRadius));
  DlPath path = path_builder.TakePath();

  const DlColor color = DlColor::kDarkGrey();
  const DlScalar elevation = 7;

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawShadow(path, color, elevation, true, 1.0);
          },
          kDrawShadowFlags),
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

TEST_F(DisplayListRendering, DrawShadowDpr) {
  DlPathBuilder path_builder;
  path_builder.AddRoundRect(DlRoundRect::MakeRectXY(
      DlRect::MakeLTRB(kRenderLeft + 10, kRenderTop,  //
                       kRenderRight - 10, kRenderBottom - 20),
      kRenderCornerRadius, kRenderCornerRadius));
  DlPath path = path_builder.TakePath();

  const DlColor color = DlColor::kDarkGrey();
  const DlScalar elevation = 7;

  RenderAll(  //
      TestParameters(
          [=](const DlRenderContext& ctx) {  //
            ctx.canvas->DrawShadow(path, color, elevation, false, 1.5);
          },
          kDrawShadowFlags),
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

TEST_F(DisplayListRendering, SaveLayerClippedContentStillFilters) {
  // draw rect is just outside of render bounds on the right
  const DlRect draw_rect = DlRect::MakeLTRB(  //
      kRenderRight + 1,                       //
      kRenderTop,                             //
      kTestBounds2.GetRight(),                //
      kRenderBottom                           //
  );
  TestParameters test_params(
      [=](const DlRenderContext& ctx) {
        std::shared_ptr<DlImageFilter> layer_filter =
            DlImageFilter::MakeBlur(10.0f, 10.0f, DlTileMode::kDecal);
        DlPaint layer_paint;
        layer_paint.setImageFilter(layer_filter);
        ctx.canvas->Save();
        ctx.canvas->ClipRect(kRenderBounds, DlClipOp::kIntersect, false);
        ctx.canvas->SaveLayer(kTestBounds2, &layer_paint);
        ctx.canvas->DrawRect(draw_rect, ctx.paint);
        ctx.canvas->Restore();
        ctx.canvas->Restore();
      },
      kSaveLayerWithPaintFlags);
  CaseParameters case_params("Filtered SaveLayer with clipped content");
  BoundsTolerance tolerance = BoundsTolerance().addAbsolutePadding(6.0f, 6.0f);

  for (BackendType back_end : GetTestBackends()) {
    std::unique_ptr<DlSurfaceProvider> provider = GetProvider(back_end);
    RenderEnvironment env = RenderEnvironment::MakeN32(provider.get());
    env.InitializeReference(kEmptyDlSetup, test_params.dl_renderer());

    CanvasCompareTester::RenderWith(test_params, env, tolerance, case_params);
  }
}

TEST_F(DisplayListRendering, SaveLayerConsolidation) {
  float commutable_color_matrix[]{
      // clang-format off
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      1, 0, 0, 0, 0,
      0, 0, 0, 1, 0,
      // clang-format on
  };
  float non_commutable_color_matrix[]{
      // clang-format off
      0, 1, 0, .1, 0,
      0, 0, 1, .1, 0,
      1, 0, 0, .1, 0,
      0, 0, 0, .7, 0,
      // clang-format on
  };
  DlMatrix contract_matrix;
  contract_matrix.Translate({kRenderCenterX, kRenderCenterY});
  contract_matrix.Scale({0.9f, 0.9f});
  contract_matrix.Translate({kRenderCenterX, kRenderCenterY});

  std::vector<DlScalar> opacities = {
      0,
      0.5f,
      SK_Scalar1,
  };
  std::vector<std::shared_ptr<const DlColorFilter>> color_filters = {
      DlColorFilter::MakeBlend(DlColor::kCyan(), DlBlendMode::kSrcATop),
      DlColorFilter::MakeMatrix(commutable_color_matrix),
      DlColorFilter::MakeMatrix(non_commutable_color_matrix),
      DlColorFilter::MakeSrgbToLinearGamma(),
      DlColorFilter::MakeLinearToSrgbGamma(),
  };
  std::vector<std::shared_ptr<DlImageFilter>> image_filters = {
      DlImageFilter::MakeBlur(5.0f, 5.0f, DlTileMode::kDecal),
      DlImageFilter::MakeDilate(5.0f, 5.0f),
      DlImageFilter::MakeErode(5.0f, 5.0f),
      DlImageFilter::MakeMatrix(contract_matrix, DlImageSampling::kLinear),
  };

  auto render_content = [](DisplayListBuilder& builder) -> void {
    builder.DrawRect(DlRect::MakeLTRB(kRenderLeft, kRenderTop,  //
                                      kRenderCenterX, kRenderCenterY),
                     DlPaint(DlColor::kYellow()));
    builder.DrawRect(DlRect::MakeLTRB(kRenderCenterX, kRenderTop,  //
                                      kRenderRight, kRenderCenterY),
                     DlPaint(DlColor::kRed()));
    builder.DrawRect(DlRect::MakeLTRB(kRenderLeft, kRenderCenterY,  //
                                      kRenderCenterX, kRenderBottom),
                     DlPaint(DlColor::kBlue()));
    builder.DrawRect(DlRect::MakeLTRB(kRenderCenterX, kRenderCenterY,  //
                                      kRenderRight, kRenderBottom),
                     DlPaint(DlColor::kRed().modulateOpacity(0.5f)));
  };

  // clang-format off
  // The following section gets re-formatted on every commit even if it
  // doesn't change.
  auto test_attributes_env =
      [render_content](DlPaint& paint1, DlPaint& paint2,
                       const DlPaint& paint_both, bool same, bool rev_same,
                       const std::string& desc1, const std::string& desc2,
                       const RenderEnvironment* env) -> void {
        DisplayListBuilder nested_builder;
        nested_builder.SaveLayer(kTestBounds2, &paint1);
        nested_builder.SaveLayer(kTestBounds2, &paint2);
        render_content(nested_builder);
        RenderResult nested_results = env->GetResult(nested_builder.Build());

        DisplayListBuilder reverse_builder;
        reverse_builder.SaveLayer(kTestBounds2, &paint2);
        reverse_builder.SaveLayer(kTestBounds2, &paint1);
        render_content(reverse_builder);
        RenderResult reverse_results = env->GetResult(reverse_builder.Build());

        DisplayListBuilder combined_builder;
        combined_builder.SaveLayer(kTestBounds2, &paint_both);
        render_content(combined_builder);
        RenderResult combined_results =
            env->GetResult(combined_builder.Build());

        // Set this boolean to true to test if combinations that are marked
        // as incompatible actually are compatible despite our predictions.
        // Some of the combinations that we treat as incompatible actually
        // are compatible with swapping the order of the operations, but
        // it would take a bit of new infrastructure to really identify
        // those combinations. The only hard constraint to test here is
        // when we claim that they are compatible and they aren't.
        const bool always = false;

        // In some circumstances, Skia can combine image filter evaluations
        // and elide a renderpass. In this case rounding and precision of inputs
        // to color filters may cause the output to differ by 1.
        if (always || same) {
          CanvasCompareTester::compareToReference(
              nested_results, combined_results,
              "nested " + desc1 + " then " + desc2, /*bounds=*/nullptr,
              /*tolerance=*/nullptr, DlColor::kTransparent(),
              /*fuzzyCompares=*/true, combined_results.pixel_data->width(),
              combined_results.pixel_data->height(), /*printMismatches=*/true);
        }
        if (always || rev_same) {
          CanvasCompareTester::compareToReference(
              reverse_results, combined_results,
              "nested " + desc2 + " then " + desc1, /*bounds=*/nullptr,
              /*tolerance=*/nullptr, DlColor::kTransparent(),
              /*fuzzyCompares=*/true, combined_results.pixel_data->width(),
              combined_results.pixel_data->height(), /*printMismatches=*/true);
        }
      };
  // clang-format on

  auto test_attributes = [test_attributes_env](
                             DlPaint& paint1, DlPaint& paint2,
                             const DlPaint& paint_both, bool same,
                             bool rev_same, const std::string& desc1,
                             const std::string& desc2) -> void {
    for (BackendType back_end : GetTestBackends()) {
      std::unique_ptr<DlSurfaceProvider> provider = GetProvider(back_end);
      std::unique_ptr<RenderEnvironment> env =
          std::make_unique<RenderEnvironment>(provider.get(),
                                              PixelFormat::kN32Premul);
      test_attributes_env(paint1, paint2, paint_both,  //
                          same, rev_same, desc1, desc2, env.get());
    }
  };

  // CF then Opacity should always work.
  // The reverse sometimes works.
  for (size_t cfi = 0; cfi < color_filters.size(); cfi++) {
    std::shared_ptr<const DlColorFilter>& color_filter = color_filters[cfi];
    std::string cf_desc = "color filter #" + std::to_string(cfi + 1);
    DlPaint nested_paint1 = DlPaint().setColorFilter(color_filter);

    for (size_t oi = 0; oi < opacities.size(); oi++) {
      DlScalar opacity = opacities[oi];
      std::string op_desc = "opacity " + std::to_string(opacity);
      DlPaint nested_paint2 = DlPaint().setOpacity(opacity);

      DlPaint combined_paint = nested_paint1;
      combined_paint.setOpacity(opacity);

      bool op_then_cf_works = opacity <= 0.0 || opacity >= 1.0 ||
                              color_filter->can_commute_with_opacity();

      test_attributes(nested_paint1, nested_paint2, combined_paint, true,
                      op_then_cf_works, cf_desc, op_desc);
    }
  }

  // Opacity then IF should always work.
  // The reverse can also work for some values of opacity.
  // The reverse should also theoretically work for some IFs, but we
  // get some rounding errors that are more than just trivial.
  for (size_t oi = 0; oi < opacities.size(); oi++) {
    DlScalar opacity = opacities[oi];
    std::string op_desc = "opacity " + std::to_string(opacity);
    DlPaint nested_paint1 = DlPaint().setOpacity(opacity);

    for (size_t ifi = 0; ifi < image_filters.size(); ifi++) {
      std::shared_ptr<DlImageFilter>& image_filter = image_filters[ifi];
      std::string if_desc = "image filter #" + std::to_string(ifi + 1);
      DlPaint nested_paint2 = DlPaint().setImageFilter(image_filter);

      DlPaint combined_paint = nested_paint1;
      combined_paint.setImageFilter(image_filter);

      bool if_then_op_works = opacity <= 0.0 || opacity >= 1.0;
      test_attributes(nested_paint1, nested_paint2, combined_paint, true,
                      if_then_op_works, op_desc, if_desc);
    }
  }

  // CF then IF should always work.
  // The reverse might work, but we lack the infrastructure to check it.
  for (size_t cfi = 0; cfi < color_filters.size(); cfi++) {
    std::shared_ptr<const DlColorFilter>& color_filter = color_filters[cfi];
    std::string cf_desc = "color filter #" + std::to_string(cfi + 1);
    DlPaint nested_paint1 = DlPaint().setColorFilter(color_filter);

    for (size_t ifi = 0; ifi < image_filters.size(); ifi++) {
      std::shared_ptr<DlImageFilter>& image_filter = image_filters[ifi];
      std::string if_desc = "image filter #" + std::to_string(ifi + 1);
      DlPaint nested_paint2 = DlPaint().setImageFilter(image_filter);

      DlPaint combined_paint = nested_paint1;
      combined_paint.setImageFilter(image_filter);

      test_attributes(nested_paint1, nested_paint2, combined_paint, true, false,
                      cf_desc, if_desc);
    }
  }
}

TEST_F(DisplayListRendering, MatrixColorFilterModifyTransparencyCheck) {
  auto test_matrix = [](int element, DlScalar value) -> void {
    // clang-format off
    float matrix[] = {
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
    };
    // clang-format on
    std::string desc =
        "matrix[" + std::to_string(element) + "] = " + std::to_string(value);
    float original_value = matrix[element];
    matrix[element] = value;
    // Here we instantiate a DlMatrixColorFilter directly so that it is
    // not affected by the "NOP" detection in the factory. We sould not
    // need to do this if we tested by just rendering the filter color
    // over the source color with the filter blend mode instead of
    // rendering via a ColorFilter, but this test is more "black box".
    DlMatrixColorFilter filter(matrix);
    std::shared_ptr<const DlColorFilter> dl_filter =
        DlColorFilter::MakeMatrix(matrix);
    bool is_identity = (dl_filter == nullptr || original_value == value);

    DlPaint paint(DlColor(0x7f7f7f7f));
    DlPaint filter_save_paint = DlPaint().setColorFilter(&filter);

    DisplayListBuilder builder1;
    builder1.Translate(kTestCenter2.x, kTestCenter2.y);
    builder1.Rotate(45);
    builder1.Translate(-kTestCenter2.x, -kTestCenter2.y);
    builder1.DrawRect(kRenderBounds, paint);
    sk_sp<DisplayList> display_list1 = builder1.Build();

    DisplayListBuilder builder2;
    builder2.Translate(kTestCenter2.x, kTestCenter2.y);
    builder2.Rotate(45);
    builder2.Translate(-kTestCenter2.x, -kTestCenter2.y);
    builder2.SaveLayer(kTestBounds2, &filter_save_paint);
    builder2.DrawRect(kRenderBounds, paint);
    builder2.Restore();
    sk_sp<DisplayList> display_list2 = builder2.Build();

    for (BackendType back_end : GetTestBackends()) {
      std::unique_ptr<DlSurfaceProvider> provider = GetProvider(back_end);
      std::unique_ptr<RenderEnvironment> env =
          std::make_unique<RenderEnvironment>(provider.get(),
                                              PixelFormat::kN32Premul);
      RenderResult results1 = env->GetResult(display_list1);
      RenderResult results2 = env->GetResult(display_list2);
      CanvasCompareTester::quickCompareToReference(
          results1, results2, is_identity, desc + " filter affects rendering");
      int modified_transparent_pixels =
          CanvasCompareTester::countModifiedTransparentPixels(results1,
                                                              results2);
      EXPECT_EQ(filter.modifies_transparent_black(),
                modified_transparent_pixels != 0)
          << desc;
    }
  };

  // Tests identity (matrix[0] already == 1 in an identity filter)
  test_matrix(0, 1);
  // test_matrix(19, 1);
  for (int i = 0; i < 20; i++) {
    test_matrix(i, -0.25);
    test_matrix(i, 0);
    test_matrix(i, 0.25);
    test_matrix(i, 1);
    test_matrix(i, 1.25);
    test_matrix(i, SK_ScalarNaN);
    test_matrix(i, SK_ScalarInfinity);
    test_matrix(i, -SK_ScalarInfinity);
  }
}

TEST_F(DisplayListRendering, MatrixColorFilterOpacityCommuteCheck) {
  auto test_matrix = [](int element, DlScalar value) -> void {
    // clang-format off
    float matrix[] = {
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
    };
    // clang-format on
    std::string desc =
        "matrix[" + std::to_string(element) + "] = " + std::to_string(value);
    matrix[element] = value;
    std::shared_ptr<const DlColorFilter> filter =
        DlColorFilter::MakeMatrix(matrix);
    EXPECT_EQ(std::isfinite(value), filter != nullptr);

    DlPaint paint(DlColor(0x80808080));
    DlPaint opacity_save_paint = DlPaint().setOpacity(0.5);
    DlPaint filter_save_paint = DlPaint().setColorFilter(filter);

    DisplayListBuilder builder1;
    builder1.SaveLayer(kTestBounds2, &opacity_save_paint);
    builder1.SaveLayer(kTestBounds2, &filter_save_paint);
    // builder1.DrawRect(kRenderBounds.makeOffset(20, 20), DlPaint());
    builder1.DrawRect(kRenderBounds, paint);
    builder1.Restore();
    builder1.Restore();
    sk_sp<DisplayList> display_list1 = builder1.Build();

    DisplayListBuilder builder2;
    builder2.SaveLayer(kTestBounds2, &filter_save_paint);
    builder2.SaveLayer(kTestBounds2, &opacity_save_paint);
    // builder1.DrawRect(kRenderBounds.makeOffset(20, 20), DlPaint());
    builder2.DrawRect(kRenderBounds, paint);
    builder2.Restore();
    builder2.Restore();
    sk_sp<DisplayList> display_list2 = builder2.Build();

    for (BackendType back_end : GetTestBackends()) {
      std::unique_ptr<DlSurfaceProvider> provider = GetProvider(back_end);
      std::unique_ptr<RenderEnvironment> env =
          std::make_unique<RenderEnvironment>(provider.get(),
                                              PixelFormat::kN32Premul);
      RenderResult results1 = env->GetResult(display_list1);
      RenderResult results2 = env->GetResult(display_list2);
      if (!filter || filter->can_commute_with_opacity()) {
        CanvasCompareTester::compareToReference(
            results2, results1, desc, nullptr, nullptr, DlColor::kTransparent(),
            true, kTestWidth, kTestHeight, true);
      } else {
        CanvasCompareTester::quickCompareToReference(results1, results2, false,
                                                     desc);
      }
    }
  };

  // Tests identity (matrix[0] already == 1 in an identity filter)
  test_matrix(0, 1);
  // test_matrix(19, 1);
  for (int i = 0; i < 20; i++) {
    test_matrix(i, -0.25);
    test_matrix(i, 0);
    test_matrix(i, 0.25);
    test_matrix(i, 1);
    test_matrix(i, 1.1);
    test_matrix(i, SK_ScalarNaN);
    test_matrix(i, SK_ScalarInfinity);
    test_matrix(i, -SK_ScalarInfinity);
  }
}

#define FOR_EACH_BLEND_MODE_ENUM(FUNC) \
  FUNC(kClear)                         \
  FUNC(kSrc)                           \
  FUNC(kDst)                           \
  FUNC(kSrcOver)                       \
  FUNC(kDstOver)                       \
  FUNC(kSrcIn)                         \
  FUNC(kDstIn)                         \
  FUNC(kSrcOut)                        \
  FUNC(kDstOut)                        \
  FUNC(kSrcATop)                       \
  FUNC(kDstATop)                       \
  FUNC(kXor)                           \
  FUNC(kPlus)                          \
  FUNC(kModulate)                      \
  FUNC(kScreen)                        \
  FUNC(kOverlay)                       \
  FUNC(kDarken)                        \
  FUNC(kLighten)                       \
  FUNC(kColorDodge)                    \
  FUNC(kColorBurn)                     \
  FUNC(kHardLight)                     \
  FUNC(kSoftLight)                     \
  FUNC(kDifference)                    \
  FUNC(kExclusion)                     \
  FUNC(kMultiply)                      \
  FUNC(kHue)                           \
  FUNC(kSaturation)                    \
  FUNC(kColor)                         \
  FUNC(kLuminosity)

TEST_F(DisplayListRendering, BlendColorFilterModifyTransparencyCheck) {
  auto test_mode_color = [](DlBlendMode mode, DlColor color) -> void {
    std::stringstream desc_str;
    std::string mode_string = BlendModeToString(mode);
    desc_str << "blend[" << mode_string << ", " << color << "]";
    std::string desc = desc_str.str();
    DlBlendColorFilter filter(color, mode);
    if (filter.modifies_transparent_black()) {
      ASSERT_NE(DlColorFilter::MakeBlend(color, mode), nullptr) << desc;
    }

    DlPaint paint(DlColor(0x7f7f7f7f));
    DlPaint filter_save_paint = DlPaint().setColorFilter(&filter);

    DisplayListBuilder builder1;
    builder1.Translate(kTestCenter2.x, kTestCenter2.y);
    builder1.Rotate(45);
    builder1.Translate(-kTestCenter2.x, -kTestCenter2.y);
    builder1.DrawRect(kRenderBounds, paint);
    sk_sp<DisplayList> display_list1 = builder1.Build();

    DisplayListBuilder builder2;
    builder2.Translate(kTestCenter2.x, kTestCenter2.y);
    builder2.Rotate(45);
    builder2.Translate(-kTestCenter2.x, -kTestCenter2.y);
    builder2.SaveLayer(kTestBounds2, &filter_save_paint);
    builder2.DrawRect(kRenderBounds, paint);
    builder2.Restore();
    sk_sp<DisplayList> display_list2 = builder2.Build();

    for (BackendType back_end : GetTestBackends()) {
      std::unique_ptr<DlSurfaceProvider> provider = GetProvider(back_end);
      std::unique_ptr<RenderEnvironment> env =
          std::make_unique<RenderEnvironment>(provider.get(),
                                              PixelFormat::kN32Premul);
      RenderResult results1 = env->GetResult(display_list1);
      RenderResult results2 = env->GetResult(display_list2);
      int modified_transparent_pixels =
          CanvasCompareTester::countModifiedTransparentPixels(results1,
                                                              results2);
      EXPECT_EQ(filter.modifies_transparent_black(),
                modified_transparent_pixels != 0)
          << provider->GetBackendName() << ": " << desc;
    }
  };

  auto test_mode = [&test_mode_color](DlBlendMode mode) -> void {
    test_mode_color(mode, DlColor::kTransparent());
    test_mode_color(mode, DlColor::kWhite());
    test_mode_color(mode, DlColor::kWhite().modulateOpacity(0.5));
    test_mode_color(mode, DlColor::kBlack());
    test_mode_color(mode, DlColor::kBlack().modulateOpacity(0.5));
  };

#define TEST_MODE(V) test_mode(DlBlendMode::V);
  FOR_EACH_BLEND_MODE_ENUM(TEST_MODE)
#undef TEST_MODE
}

TEST_F(DisplayListRendering, BlendColorFilterOpacityCommuteCheck) {
  auto test_mode_color = [](DlBlendMode mode, DlColor color) -> void {
    std::stringstream desc_str;
    std::string mode_string = BlendModeToString(mode);
    desc_str << "blend[" << mode_string << ", " << color << "]";
    std::string desc = desc_str.str();
    DlBlendColorFilter filter(color, mode);
    if (filter.can_commute_with_opacity()) {
      // If it can commute with opacity, then it might also be a NOP,
      // so we won't necessarily get a non-null return from |::Make()|
    } else {
      ASSERT_NE(DlColorFilter::MakeBlend(color, mode), nullptr) << desc;
    }

    DlPaint paint(DlColor(0x80808080));
    DlPaint opacity_save_paint = DlPaint().setOpacity(0.5);
    DlPaint filter_save_paint = DlPaint().setColorFilter(&filter);

    DisplayListBuilder builder1;
    builder1.SaveLayer(kTestBounds2, &opacity_save_paint);
    builder1.SaveLayer(kTestBounds2, &filter_save_paint);
    // builder1.DrawRect(kRenderBounds.makeOffset(20, 20), DlPaint());
    builder1.DrawRect(kRenderBounds, paint);
    builder1.Restore();
    builder1.Restore();
    sk_sp<DisplayList> display_list1 = builder1.Build();

    DisplayListBuilder builder2;
    builder2.SaveLayer(kTestBounds2, &filter_save_paint);
    builder2.SaveLayer(kTestBounds2, &opacity_save_paint);
    // builder1.DrawRect(kRenderBounds.makeOffset(20, 20), DlPaint());
    builder2.DrawRect(kRenderBounds, paint);
    builder2.Restore();
    builder2.Restore();
    sk_sp<DisplayList> display_list2 = builder2.Build();

    for (BackendType back_end : GetTestBackends()) {
      std::unique_ptr<DlSurfaceProvider> provider = GetProvider(back_end);
      std::string provider_desc = " " + provider->GetBackendName() + " " + desc;
      std::unique_ptr<RenderEnvironment> env =
          std::make_unique<RenderEnvironment>(provider.get(),
                                              PixelFormat::kN32Premul);

      RenderResult results1 = env->GetResult(display_list1);
      RenderResult results2 = env->GetResult(display_list2);
      if (filter.can_commute_with_opacity()) {
        CanvasCompareTester::compareToReference(
            results2, results1, provider_desc, nullptr, nullptr,
            DlColor::kTransparent(), true, kTestWidth, kTestHeight, true);
      } else {
        CanvasCompareTester::quickCompareToReference(results1, results2, false,
                                                     provider_desc);
      }
    }
  };

  auto test_mode = [&test_mode_color](DlBlendMode mode) -> void {
    test_mode_color(mode, DlColor::kTransparent());
    test_mode_color(mode, DlColor::kWhite());
    test_mode_color(mode, DlColor::kWhite().modulateOpacity(0.5));
    test_mode_color(mode, DlColor::kBlack());
    test_mode_color(mode, DlColor::kBlack().modulateOpacity(0.5));
  };

#define TEST_MODE(V) test_mode(DlBlendMode::V);
  FOR_EACH_BLEND_MODE_ENUM(TEST_MODE)
#undef TEST_MODE
}

class DisplayListNopTest : public DisplayListRendering {
  // The following code uses the acronym MTB for "modifies_transparent_black"

 protected:
  DisplayListNopTest() : DisplayListRendering() {
    test_src_colors = {
        DlColor::kBlack().withAlpha(0),     // transparent black
        DlColor::kBlack().withAlpha(0x7f),  // half transparent black
        DlColor::kWhite().withAlpha(0x7f),  // half transparent white
        DlColor::kBlack(),                  // opaque black
        DlColor::kWhite(),                  // opaque white
        DlColor::kRed(),                    // opaque red
        DlColor::kGreen(),                  // opaque green
        DlColor::kBlue(),                   // opaque blue
        DlColor::kDarkGrey(),               // dark grey
        DlColor::kLightGrey(),              // light grey
    };

    // We test against a color cube of 3x3x3x3 colors [55,aa,ff]
    // plus transparency as the first color/pixel
    test_dst_colors.push_back(DlColor::kTransparent());
    const int step = 0x55;
    static_assert(step * 3 == 255);
    for (int a = step; a < 256; a += step) {
      for (int r = step; r < 256; r += step) {
        for (int g = step; g < 256; g += step) {
          for (int b = step; b < 256; b += step) {
            test_dst_colors.push_back(DlColor(a << 24 | r << 16 | g << 8 | b));
          }
        }
      }
    }

    static constexpr float color_filter_matrix_nomtb[] = {
        0.0001, 0.0001, 0.0001, 0.9997, 0.0,  //
        0.0001, 0.0001, 0.0001, 0.9997, 0.0,  //
        0.0001, 0.0001, 0.0001, 0.9997, 0.0,  //
        0.0001, 0.0001, 0.0001, 0.9997, 0.0,  //
    };
    static constexpr float color_filter_matrix_mtb[] = {
        0.0001, 0.0001, 0.0001, 0.9997, 0.0,  //
        0.0001, 0.0001, 0.0001, 0.9997, 0.0,  //
        0.0001, 0.0001, 0.0001, 0.9997, 0.0,  //
        0.0001, 0.0001, 0.0001, 0.9997, 0.1,  //
    };
    color_filter_nomtb = DlColorFilter::MakeMatrix(color_filter_matrix_nomtb);
    color_filter_mtb = DlColorFilter::MakeMatrix(color_filter_matrix_mtb);
    EXPECT_FALSE(color_filter_nomtb->modifies_transparent_black());
    EXPECT_TRUE(color_filter_mtb->modifies_transparent_black());
  }

  struct TestData {
    // A 1-row image containing every color in test_dst_colors
    // RenderResult test_data;
    sk_sp<DlImage> test_image_1d;
    RenderResult test_pixels;

    // A square image containing test_data duplicated in each row
    // RenderResult test_image_dst_data;
    sk_sp<DlImage> dst_image_2d;
    RenderResult dst_pixels;

    // A square image containing test_data duplicated in each column
    // RenderResult test_image_src_data;
    sk_sp<DlImage> src_image_2d;
    RenderResult src_pixels;
  };

  const TestData make_test_data(DlSurfaceProvider* provider) {
    std::shared_ptr<DlSurfaceInstance> test_surface = get_output(
        provider, test_dst_colors.size(), 1, true, [this](DlCanvas* canvas) {
          int x = 0;
          DlPaint paint;
          paint.setBlendMode(DlBlendMode::kSrc);
          for (DlColor color : test_dst_colors) {
            paint.setColor(color);
            canvas->DrawRect(DlRect::MakeXYWH(x, 0, 1, 1), paint);
            x++;
          }
        });
    sk_sp<DlImage> test_image = test_surface->SnapshotToImage();
    std::shared_ptr<DlPixelData> test_pixels =
        test_surface->SnapshotToPixelData();

    // For image-on-image tests, the src and dest images will have repeated
    // rows/columns that have every color, but laid out at right angles to
    // each other so we see an interaction with every test color against
    // every other test color.
    int data_count = test_image->width();
    std::shared_ptr<DlSurfaceInstance> dst_surface =
        get_output(provider, data_count, data_count, true,
                   [&test_image, data_count](DlCanvas* canvas) {
                     ASSERT_EQ(test_image->width(), data_count);
                     ASSERT_EQ(test_image->height(), 1);
                     for (int y = 0; y < data_count; y++) {
                       canvas->DrawImage(test_image, DlPoint(0, y),
                                         DlImageSampling::kNearestNeighbor);
                     }
                   });
    std::shared_ptr<DlPixelData> dst_pixels =
        dst_surface->SnapshotToPixelData();

    std::shared_ptr<DlSurfaceInstance> src_surface =
        get_output(provider, data_count, data_count, true,
                   [&test_image, data_count](DlCanvas* canvas) {
                     ASSERT_EQ(test_image->width(), data_count);
                     ASSERT_EQ(test_image->height(), 1);
                     canvas->Translate(data_count, 0);
                     canvas->Rotate(90);
                     for (int y = 0; y < data_count; y++) {
                       canvas->DrawImage(test_image, DlPoint(0, y),
                                         DlImageSampling::kNearestNeighbor);
                     }
                   });
    std::shared_ptr<DlPixelData> src_pixels =
        src_surface->SnapshotToPixelData();

    // Double check that the pixel data is laid out in orthogonal stripes
    for (int y = 0; y < data_count; y++) {
      for (int x = 0; x < data_count; x++) {
        EXPECT_EQ(*dst_pixels->addr32(x, y), *test_pixels->addr32(x, 0));
        EXPECT_EQ(*src_pixels->addr32(x, y), *test_pixels->addr32(y, 0));
      }
    }

    return {
        .test_image_1d = test_surface->SnapshotToImage(),
        .test_pixels = RenderResult::Make(test_pixels),

        .dst_image_2d = dst_surface->SnapshotToImage(),
        .dst_pixels = RenderResult::Make(dst_pixels),

        .src_image_2d = src_surface->SnapshotToImage(),
        .src_pixels = RenderResult::Make(src_pixels),
    };
  }

  // These flags are 0 by default until they encounter a counter-example
  // result and get set.
  static constexpr int kWasNotNop = 0x1;  // Some tested pixel was modified
  static constexpr int kWasMTB = 0x2;     // A transparent pixel was modified

  std::vector<DlColor> test_src_colors;
  std::vector<DlColor> test_dst_colors;

  std::shared_ptr<const DlColorFilter> color_filter_nomtb;
  std::shared_ptr<const DlColorFilter> color_filter_mtb;

  std::map<DlSurfaceProvider::BackendType, TestData> test_datas;

  const TestData GetTestData(DlSurfaceProvider* provider) {
    auto entry = test_datas.find(provider->GetBackendType());
    if (entry == test_datas.end()) {
      TestData test_data = make_test_data(provider);
      test_datas[provider->GetBackendType()] = test_data;
      return test_data;
    }
    return entry->second;
  }

  std::shared_ptr<DlSurfaceInstance> get_output(
      DlSurfaceProvider* provider,
      int w,
      int h,
      bool snapshot,
      const std::function<void(DlCanvas*)>& renderer) {
    std::shared_ptr<DlSurfaceInstance> surface =
        provider->MakeOffscreenSurface(w, h, DlSurfaceProvider::kN32Premul);
    DisplayListBuilder builder;
    renderer(&builder);
    surface->RenderDisplayList(builder.Build());
    surface->FlushSubmitCpuSync();
    return surface;
  }

  int check_color_result(DlColor dst_color,
                         DlColor result_color,
                         int x,
                         int y,
                         const sk_sp<DisplayList>& dl,
                         const std::string& desc) {
    int ret = 0;
    bool is_error = false;
    if (dst_color.isTransparent() && !result_color.isTransparent()) {
      ret |= kWasMTB;
      is_error = !dl->modifies_transparent_black();
    }
    if (result_color != dst_color) {
      ret |= kWasNotNop;
      is_error = (dl->op_count() == 0u);
    }
    if (is_error) {
      FML_LOG(ERROR) << std::hex << dst_color                       //
                     << std::dec << " at " << x << ", " << y        //
                     << " filters to " << std::hex << result_color  //
                     << desc;
    }
    return ret;
  }

  int check_image_result(const RenderResult& dst_data,
                         const RenderResult& result_data,
                         const sk_sp<DisplayList>& dl,
                         const std::string& desc) {
    EXPECT_EQ(dst_data.pixel_data->width(), result_data.pixel_data->width());
    EXPECT_EQ(dst_data.pixel_data->height(), result_data.pixel_data->height());
    int all_flags = 0;
    for (uint32_t y = 0; y < dst_data.pixel_data->height(); y++) {
      const uint32_t* dst_pixels = dst_data.pixel_data->addr32(0, y);
      const uint32_t* result_pixels = result_data.pixel_data->addr32(0, y);
      for (uint32_t x = 0; x < dst_data.pixel_data->width(); x++) {
        all_flags |= check_color_result(
            DlColor(dst_pixels[x]), DlColor(result_pixels[x]), x, y, dl, desc);
      }
    }
    return all_flags;
  }

  void report_results(int all_flags,
                      const sk_sp<DisplayList>& dl,
                      const std::string& desc) {
    if (!dl->modifies_transparent_black()) {
      EXPECT_TRUE((all_flags & kWasMTB) == 0);
    } else if ((all_flags & kWasMTB) == 0) {
      FML_LOG(INFO) << "combination does not affect transparency: " << desc;
    }
    if (dl->op_count() == 0u) {
      EXPECT_TRUE((all_flags & kWasNotNop) == 0);
    } else if ((all_flags & kWasNotNop) == 0) {
      FML_LOG(INFO) << "combination could be classified as a nop: " << desc;
    }
  };

  void test_mode_color_via_filter(DlBlendMode mode, DlColor color) {
    std::stringstream desc_stream;
    desc_stream << " using SkColorFilter::filterColor() with: ";
    desc_stream << BlendModeToString(mode);
    desc_stream << "/" << color;
    std::string desc = desc_stream.str();
    DisplayListBuilder builder(DlRect::MakeWH(100.0f, 100.0f));
    DlPaint paint = DlPaint(color).setBlendMode(mode);
    builder.DrawRect(DlRect::MakeLTRB(0.0f, 0.0f, 10.0f, 10.0f), paint);
    sk_sp<DisplayList> dl = builder.Build();
    if (dl->modifies_transparent_black()) {
      ASSERT_TRUE(dl->op_count() != 0u);
    }

    SkBlendMode sk_mode = static_cast<SkBlendMode>(mode);
    sk_sp<SkColorFilter> sk_color_filter =
        SkColorFilters::Blend(ToSkColor4f(color), nullptr, sk_mode);
    sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
    int all_flags = 0;
    if (sk_color_filter) {
      for (DlColor dst_color : test_dst_colors) {
        SkColor4f dst_color_f = ToSkColor4f(dst_color);
        DlColor result = DlColor(
            sk_color_filter->filterColor4f(dst_color_f, srgb.get(), srgb.get())
                .toSkColor());
        all_flags |=
            check_color_result(dst_color, result, /*x=*/0, /*y=*/0, dl, desc);
      }
      if ((all_flags & kWasMTB) != 0) {
        EXPECT_FALSE(sk_color_filter->isAlphaUnchanged());
      }
    }
    report_results(all_flags, dl, desc);
  };

  void test_mode_color_via_rendering(DlBlendMode mode, DlColor color) {
    std::stringstream desc_stream;
    desc_stream << " rendering with: ";
    desc_stream << BlendModeToString(mode);
    desc_stream << "/" << color;
    std::string desc = desc_stream.str();
    DisplayListBuilder builder_for_properties;
    DlPaint dl_paint = DlPaint(color).setBlendMode(mode);
    builder_for_properties.DrawRect(DlRect::MakeWH(100, 100), dl_paint);
    sk_sp<DisplayList> properties_display_list = builder_for_properties.Build();
    bool dl_is_elided = properties_display_list->op_count() == 0u;
    bool dl_affects_transparent_pixels =
        properties_display_list->modifies_transparent_black();
    ASSERT_TRUE(!dl_is_elided || !dl_affects_transparent_pixels);

    DlPaint paint;
    paint.setBlendMode(mode);
    paint.setColor(color);
    for (BackendType back_end : GetTestBackends()) {
      std::unique_ptr<DlSurfaceProvider> provider = GetProvider(back_end);
      const TestData test_data = GetTestData(provider.get());
      std::string provider_desc = " " + provider->GetBackendName() + desc;

      sk_sp<DlImage> test_image = test_data.test_image_1d;
      DlRect test_bounds =
          DlRect::MakeWH(test_image->width(), test_image->height());
      std::shared_ptr<DlSurfaceInstance> result_surface =
          provider->MakeOffscreenSurface(test_image->width(),
                                         test_image->height(),
                                         DlSurfaceProvider::kN32Premul);
      DisplayListBuilder builder_for_rendering;
      builder_for_rendering.Clear(DlColor::kTransparent());
      builder_for_rendering.DrawImage(test_image, DlPoint(0, 0),
                                      DlImageSampling::kNearestNeighbor);
      builder_for_rendering.DrawRect(test_bounds, paint);
      result_surface->RenderDisplayList(builder_for_rendering.Build());
      result_surface->FlushSubmitCpuSync();
      RenderResult result_pixels = RenderResult::Make(result_surface);

      int all_flags =
          check_image_result(test_data.test_pixels, result_pixels,
                             properties_display_list, provider_desc);
      report_results(all_flags, properties_display_list, provider_desc);
    }
  };

  void test_attributes_image(DlBlendMode mode,
                             DlColor color,
                             const DlColorFilter* color_filter,
                             DlImageFilter* image_filter) {
    // if (true) { return; }
    std::stringstream desc_stream;
    desc_stream << " rendering with: ";
    desc_stream << BlendModeToString(mode);
    desc_stream << "/" << color;
    std::string cf_mtb = color_filter
                             ? color_filter->modifies_transparent_black()
                                   ? "modifies transparency"
                                   : "preserves transparency"
                             : "no filter";
    desc_stream << ", CF: " << cf_mtb;
    std::string if_mtb = image_filter
                             ? image_filter->modifies_transparent_black()
                                   ? "modifies transparency"
                                   : "preserves transparency"
                             : "no filter";
    desc_stream << ", IF: " << if_mtb;
    std::string desc = desc_stream.str();

    for (BackendType back_end : GetTestBackends()) {
      std::unique_ptr<DlSurfaceProvider> provider = GetProvider(back_end);
      const TestData test_data = GetTestData(provider.get());
      std::string provider_desc = " " + provider->GetBackendName() + desc;

      DisplayListBuilder builder_for_properties(DlRect::MakeWH(100.0f, 100.0f));
      DlPaint paint = DlPaint(color)                     //
                          .setBlendMode(mode)            //
                          .setColorFilter(color_filter)  //
                          .setImageFilter(image_filter);
      builder_for_properties.DrawImage(test_data.src_image_2d, DlPoint(0, 0),
                                       DlImageSampling::kNearestNeighbor,
                                       &paint);
      sk_sp<DisplayList> properties_display_list =
          builder_for_properties.Build();

      int w = test_data.src_image_2d->width();
      int h = test_data.src_image_2d->height();
      std::shared_ptr<DlSurfaceInstance> result_surface =
          provider->MakeOffscreenSurface(w, h, DlSurfaceProvider::kN32Premul);
      DisplayListBuilder builder_for_rendering;
      builder_for_rendering.Clear(DlColor::kTransparent());
      builder_for_rendering.DrawImage(test_data.dst_image_2d, DlPoint(0, 0),
                                      DlImageSampling::kNearestNeighbor);
      builder_for_rendering.DrawImage(test_data.src_image_2d, DlPoint(0, 0),
                                      DlImageSampling::kNearestNeighbor,
                                      &paint);
      result_surface->RenderDisplayList(builder_for_rendering.Build());
      result_surface->FlushSubmitCpuSync();
      RenderResult result_pixels = RenderResult::Make(result_surface);

      int all_flags =
          check_image_result(test_data.dst_pixels, result_pixels,
                             properties_display_list, provider_desc);
      report_results(all_flags, properties_display_list, provider_desc);
    }
  };
};

TEST_F(DisplayListNopTest, BlendModeAndColorViaColorFilter) {
  auto test_mode_filter = [this](DlBlendMode mode) -> void {
    for (DlColor color : test_src_colors) {
      test_mode_color_via_filter(mode, color);
    }
  };

#define TEST_MODE(V) test_mode_filter(DlBlendMode::V);
  FOR_EACH_BLEND_MODE_ENUM(TEST_MODE)
#undef TEST_MODE
}

TEST_F(DisplayListNopTest, BlendModeAndColorByRendering) {
  auto test_mode_render = [this](DlBlendMode mode) -> void {
    // First check rendering a variety of colors onto image
    for (DlColor color : test_src_colors) {
      test_mode_color_via_rendering(mode, color);
    }
  };

#define TEST_MODE(V) test_mode_render(DlBlendMode::V);
  FOR_EACH_BLEND_MODE_ENUM(TEST_MODE)
#undef TEST_MODE
}

TEST_F(DisplayListNopTest, BlendModeAndColorAndFiltersByRendering) {
  auto test_mode_render = [this](DlBlendMode mode) -> void {
    DlColorFilterImageFilter image_filter_nomtb(color_filter_nomtb);
    DlColorFilterImageFilter image_filter_mtb(color_filter_mtb);
    for (DlColor color : test_src_colors) {
      test_attributes_image(mode, color, nullptr, nullptr);
      test_attributes_image(mode, color, color_filter_nomtb.get(), nullptr);
      test_attributes_image(mode, color, color_filter_mtb.get(), nullptr);
      test_attributes_image(mode, color, nullptr, &image_filter_nomtb);
      test_attributes_image(mode, color, nullptr, &image_filter_mtb);
    }
  };

#define TEST_MODE(V) test_mode_render(DlBlendMode::V);
  FOR_EACH_BLEND_MODE_ENUM(TEST_MODE)
#undef TEST_MODE
}

#undef FOR_EACH_BLEND_MODE_ENUM

}  // namespace testing
}  // namespace flutter

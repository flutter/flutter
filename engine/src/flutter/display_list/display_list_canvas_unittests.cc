// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <utility>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/display_list/display_list_comparable.h"
#include "flutter/display_list/display_list_flags.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/display_list/skia/dl_sk_canvas.h"
#include "flutter/display_list/testing/dl_test_surface_provider.h"
#include "flutter/fml/math.h"
#include "flutter/testing/display_list_testing.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkDiscretePathEffect.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

namespace flutter {
namespace testing {

using ClipOp = DlCanvas::ClipOp;
using PointMode = DlCanvas::PointMode;

constexpr int kTestWidth = 200;
constexpr int kTestHeight = 200;
constexpr int kRenderWidth = 100;
constexpr int kRenderHeight = 100;
constexpr int kRenderHalfWidth = 50;
constexpr int kRenderHalfHeight = 50;
constexpr int kRenderLeft = (kTestWidth - kRenderWidth) / 2;
constexpr int kRenderTop = (kTestHeight - kRenderHeight) / 2;
constexpr int kRenderRight = kRenderLeft + kRenderWidth;
constexpr int kRenderBottom = kRenderTop + kRenderHeight;
constexpr int kRenderCenterX = (kRenderLeft + kRenderRight) / 2;
constexpr int kRenderCenterY = (kRenderTop + kRenderBottom) / 2;
constexpr SkScalar kRenderRadius = std::min(kRenderWidth, kRenderHeight) / 2.0;
constexpr SkScalar kRenderCornerRadius = kRenderRadius / 5.0;

constexpr SkPoint kTestCenter = SkPoint::Make(kTestWidth / 2, kTestHeight / 2);
constexpr SkRect kTestBounds = SkRect::MakeWH(kTestWidth, kTestHeight);
constexpr SkRect kRenderBounds =
    SkRect::MakeLTRB(kRenderLeft, kRenderTop, kRenderRight, kRenderBottom);

// The tests try 3 miter limit values, 0.0, 4.0 (the default), and 10.0
// These values will allow us to construct a diamond that spans the
// width or height of the render box and still show the miter for 4.0
// and 10.0.
// These values were discovered by drawing a diamond path in Skia fiddle
// and then playing with the cross-axis size until the miter was about
// as large as it could get before it got cut off.

// The X offsets which will be used for tall vertical diamonds are
// expressed in terms of the rendering height to obtain the proper angle
constexpr SkScalar kMiterExtremeDiamondOffsetX = kRenderHeight * 0.04;
constexpr SkScalar kMiter10DiamondOffsetX = kRenderHeight * 0.051;
constexpr SkScalar kMiter4DiamondOffsetX = kRenderHeight * 0.14;

// The Y offsets which will be used for long horizontal diamonds are
// expressed in terms of the rendering width to obtain the proper angle
constexpr SkScalar kMiterExtremeDiamondOffsetY = kRenderWidth * 0.04;
constexpr SkScalar kMiter10DiamondOffsetY = kRenderWidth * 0.051;
constexpr SkScalar kMiter4DiamondOffsetY = kRenderWidth * 0.14;

// Render 3 vertical and horizontal diamonds each
// designed to break at the tested miter limits
// 0.0, 4.0 and 10.0
// Center is biased by 0.5 to include more pixel centers in the
// thin miters
constexpr SkScalar kXOffset0 = kRenderCenterX + 0.5;
constexpr SkScalar kXOffsetL1 = kXOffset0 - kMiter4DiamondOffsetX;
constexpr SkScalar kXOffsetL2 = kXOffsetL1 - kMiter10DiamondOffsetX;
constexpr SkScalar kXOffsetL3 = kXOffsetL2 - kMiter10DiamondOffsetX;
constexpr SkScalar kXOffsetR1 = kXOffset0 + kMiter4DiamondOffsetX;
constexpr SkScalar kXOffsetR2 = kXOffsetR1 + kMiterExtremeDiamondOffsetX;
constexpr SkScalar kXOffsetR3 = kXOffsetR2 + kMiterExtremeDiamondOffsetX;
constexpr SkPoint kVerticalMiterDiamondPoints[] = {
    // Vertical diamonds:
    //  M10   M4  Mextreme
    //   /\   /|\   /\       top of RenderBounds
    //  /  \ / | \ /  \              to
    // <----X--+--X---->         RenderCenter
    //  \  / \ | / \  /              to
    //   \/   \|/   \/      bottom of RenderBounds
    // clang-format off
    SkPoint::Make(kXOffsetL3, kRenderCenterY),
    SkPoint::Make(kXOffsetL2, kRenderTop),
    SkPoint::Make(kXOffsetL1, kRenderCenterY),
    SkPoint::Make(kXOffset0,  kRenderTop),
    SkPoint::Make(kXOffsetR1, kRenderCenterY),
    SkPoint::Make(kXOffsetR2, kRenderTop),
    SkPoint::Make(kXOffsetR3, kRenderCenterY),
    SkPoint::Make(kXOffsetR2, kRenderBottom),
    SkPoint::Make(kXOffsetR1, kRenderCenterY),
    SkPoint::Make(kXOffset0,  kRenderBottom),
    SkPoint::Make(kXOffsetL1, kRenderCenterY),
    SkPoint::Make(kXOffsetL2, kRenderBottom),
    SkPoint::Make(kXOffsetL3, kRenderCenterY),
    // clang-format on
};
const int kVerticalMiterDiamondPointCount =
    sizeof(kVerticalMiterDiamondPoints) /
    sizeof(kVerticalMiterDiamondPoints[0]);

constexpr SkScalar kYOffset0 = kRenderCenterY + 0.5;
constexpr SkScalar kYOffsetU1 = kXOffset0 - kMiter4DiamondOffsetY;
constexpr SkScalar kYOffsetU2 = kYOffsetU1 - kMiter10DiamondOffsetY;
constexpr SkScalar kYOffsetU3 = kYOffsetU2 - kMiter10DiamondOffsetY;
constexpr SkScalar kYOffsetD1 = kXOffset0 + kMiter4DiamondOffsetY;
constexpr SkScalar kYOffsetD2 = kYOffsetD1 + kMiterExtremeDiamondOffsetY;
constexpr SkScalar kYOffsetD3 = kYOffsetD2 + kMiterExtremeDiamondOffsetY;
const SkPoint kHorizontalMiterDiamondPoints[] = {
    // Horizontal diamonds
    // Same configuration as Vertical diamonds above but
    // rotated 90 degrees
    // clang-format off
    SkPoint::Make(kRenderCenterX, kYOffsetU3),
    SkPoint::Make(kRenderLeft,    kYOffsetU2),
    SkPoint::Make(kRenderCenterX, kYOffsetU1),
    SkPoint::Make(kRenderLeft,    kYOffset0),
    SkPoint::Make(kRenderCenterX, kYOffsetD1),
    SkPoint::Make(kRenderLeft,    kYOffsetD2),
    SkPoint::Make(kRenderCenterX, kYOffsetD3),
    SkPoint::Make(kRenderRight,   kYOffsetD2),
    SkPoint::Make(kRenderCenterX, kYOffsetD1),
    SkPoint::Make(kRenderRight,   kYOffset0),
    SkPoint::Make(kRenderCenterX, kYOffsetU1),
    SkPoint::Make(kRenderRight,   kYOffsetU2),
    SkPoint::Make(kRenderCenterX, kYOffsetU3),
    // clang-format on
};
const int kHorizontalMiterDiamondPointCount =
    (sizeof(kHorizontalMiterDiamondPoints) /
     sizeof(kHorizontalMiterDiamondPoints[0]));

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

  BoundsTolerance addBoundsPadding(SkScalar bounds_pad_x,
                                   SkScalar bounds_pad_y) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.bounds_pad_.offset(bounds_pad_x, bounds_pad_y);
    return copy;
  }

  BoundsTolerance mulScale(SkScalar scale_x, SkScalar scale_y) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.scale_.fX *= scale_x;
    copy.scale_.fY *= scale_y;
    return copy;
  }

  BoundsTolerance addAbsolutePadding(SkScalar absolute_pad_x,
                                     SkScalar absolute_pad_y) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.absolute_pad_.offset(absolute_pad_x, absolute_pad_y);
    return copy;
  }

  BoundsTolerance addPostClipPadding(SkScalar absolute_pad_x,
                                     SkScalar absolute_pad_y) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.clip_pad_.offset(absolute_pad_x, absolute_pad_y);
    return copy;
  }

  BoundsTolerance addDiscreteOffset(SkScalar discrete_offset) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    copy.discrete_offset_ += discrete_offset;
    return copy;
  }

  BoundsTolerance clip(SkRect clip) const {
    BoundsTolerance copy = BoundsTolerance(*this);
    if (!copy.clip_.intersect(clip)) {
      copy.clip_.setEmpty();
    }
    return copy;
  }

  static SkRect Scale(const SkRect& rect, const SkPoint& scales) {
    SkScalar outset_x = rect.width() * (scales.fX - 1);
    SkScalar outset_y = rect.height() * (scales.fY - 1);
    return rect.makeOutset(outset_x, outset_y);
  }

  bool overflows(SkIRect pix_bounds,
                 int worst_bounds_pad_x,
                 int worst_bounds_pad_y) const {
    SkRect allowed = SkRect::Make(pix_bounds);
    allowed.outset(bounds_pad_.fX, bounds_pad_.fY);
    allowed = Scale(allowed, scale_);
    allowed.outset(absolute_pad_.fX, absolute_pad_.fY);
    if (!allowed.intersect(clip_)) {
      allowed.setEmpty();
    }
    allowed.outset(clip_pad_.fX, clip_pad_.fY);
    SkIRect rounded = allowed.roundOut();
    int pad_left = std::max(0, pix_bounds.fLeft - rounded.fLeft);
    int pad_top = std::max(0, pix_bounds.fTop - rounded.fTop);
    int pad_right = std::max(0, pix_bounds.fRight - rounded.fRight);
    int pad_bottom = std::max(0, pix_bounds.fBottom - rounded.fBottom);
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

  SkScalar discrete_offset() const { return discrete_offset_; }

  bool operator==(BoundsTolerance const& other) const {
    return bounds_pad_ == other.bounds_pad_ && scale_ == other.scale_ &&
           absolute_pad_ == other.absolute_pad_ && clip_ == other.clip_ &&
           clip_pad_ == other.clip_pad_ &&
           discrete_offset_ == other.discrete_offset_;
  }

 private:
  SkPoint bounds_pad_ = {0, 0};
  SkPoint scale_ = {1, 1};
  SkPoint absolute_pad_ = {0, 0};
  SkRect clip_ = {-1E9, -1E9, 1E9, 1E9};
  SkPoint clip_pad_ = {0, 0};

  SkScalar discrete_offset_ = 0;
};

using SkSetup = const std::function<void(SkCanvas*, SkPaint&)>;
using SkRenderer = const std::function<void(SkCanvas*, const SkPaint&)>;
using DlSetup = const std::function<void(DlCanvas*, DlPaint&)>;
using DlRenderer = const std::function<void(DlCanvas*, const DlPaint&)>;
static const SkSetup kEmptySkSetup = [](SkCanvas*, SkPaint&) {};
static const SkRenderer kEmptySkRenderer = [](SkCanvas*, const SkPaint&) {};
static const DlSetup kEmptyDlSetup = [](DlCanvas*, DlPaint&) {};
static const DlRenderer kEmptyDlRenderer = [](DlCanvas*, const DlPaint&) {};

using PixelFormat = DlSurfaceProvider::PixelFormat;
using BackendType = DlSurfaceProvider::BackendType;

class RenderResult {
 public:
  explicit RenderResult(const sk_sp<SkSurface>& surface) {
    SkImageInfo info = surface->imageInfo();
    info = SkImageInfo::MakeN32Premul(info.dimensions());
    addr_ = malloc(info.computeMinByteSize() * info.height());
    pixmap_.reset(info, addr_, info.minRowBytes());
    EXPECT_TRUE(surface->readPixels(pixmap_, 0, 0));
  }
  ~RenderResult() { free(addr_); }

  int width() const { return pixmap_.width(); }
  int height() const { return pixmap_.height(); }
  const uint32_t* addr32(int x, int y) const { return pixmap_.addr32(x, y); }

 private:
  SkPixmap pixmap_;
  void* addr_ = nullptr;
};

struct RenderJobInfo {
  int width = kTestWidth;
  int height = kTestHeight;
  DlColor bg = DlColor::kTransparent();
  SkScalar scale = SK_Scalar1;
  SkScalar opacity = SK_Scalar1;
};

struct JobRenderer {
  virtual void Render(SkCanvas* canvas, const RenderJobInfo& info) = 0;
};

struct MatrixClipJobRenderer : public JobRenderer {
 public:
  const SkMatrix& setup_matrix() const {
    FML_CHECK(is_setup_);
    return setup_matrix_;
  }

  const SkIRect& setup_clip_bounds() const {
    FML_CHECK(is_setup_);
    return setup_clip_bounds_;
  }

 protected:
  bool is_setup_ = false;
  SkMatrix setup_matrix_;
  SkIRect setup_clip_bounds_;
};

struct SkJobRenderer : public MatrixClipJobRenderer {
  explicit SkJobRenderer(const SkSetup& sk_setup = kEmptySkSetup,
                         const SkRenderer& sk_render = kEmptySkRenderer,
                         const SkRenderer& sk_restore = kEmptySkRenderer)
      : sk_setup_(sk_setup), sk_render_(sk_render), sk_restore_(sk_restore) {}

  void Render(SkCanvas* canvas, const RenderJobInfo& info) override {
    FML_DCHECK(info.opacity == SK_Scalar1);
    SkPaint paint;
    sk_setup_(canvas, paint);
    setup_paint_ = paint;
    setup_matrix_ = canvas->getTotalMatrix();
    setup_clip_bounds_ = canvas->getDeviceClipBounds();
    is_setup_ = true;
    sk_render_(canvas, paint);
    sk_restore_(canvas, paint);
  }

  sk_sp<SkPicture> MakePicture(const RenderJobInfo& info) {
    SkPictureRecorder recorder;
    SkRTreeFactory rtree_factory;
    SkCanvas* cv = recorder.beginRecording(kTestBounds, &rtree_factory);
    Render(cv, info);
    return recorder.finishRecordingAsPicture();
  }

  const SkPaint& setup_paint() const {
    FML_CHECK(is_setup_);
    return setup_paint_;
  }

 private:
  const SkSetup sk_setup_;
  const SkRenderer sk_render_;
  const SkRenderer sk_restore_;
  SkPaint setup_paint_;
};

struct DlJobRenderer : public MatrixClipJobRenderer {
  explicit DlJobRenderer(const DlSetup& dl_setup = kEmptyDlSetup,
                         const DlRenderer& dl_render = kEmptyDlRenderer,
                         const DlRenderer& dl_restore = kEmptyDlRenderer)
      : dl_setup_(dl_setup), dl_render_(dl_render), dl_restore_(dl_restore) {}

  void Render(SkCanvas* sk_canvas, const RenderJobInfo& info) override {
    DlSkCanvasAdapter canvas(sk_canvas);
    Render(&canvas, info);
  }

  void Render(DlCanvas* canvas, const RenderJobInfo& info) {
    FML_DCHECK(info.opacity == SK_Scalar1);
    DlPaint paint;
    dl_setup_(canvas, paint);
    setup_paint_ = paint;
    setup_matrix_ = canvas->GetTransform();
    setup_clip_bounds_ = canvas->GetDestinationClipBounds().roundOut();
    is_setup_ = true;
    dl_render_(canvas, paint);
    dl_restore_(canvas, paint);
  }

  sk_sp<DisplayList> MakeDisplayList(const RenderJobInfo& info) {
    DisplayListBuilder builder(kTestBounds);
    Render(&builder, info);
    return builder.Build();
  }

  const DlPaint& setup_paint() const {
    FML_CHECK(is_setup_);
    return setup_paint_;
  }

 private:
  const DlSetup dl_setup_;
  const DlRenderer dl_render_;
  const DlRenderer dl_restore_;
  DlPaint setup_paint_;
};

struct SkPictureJobRenderer : public JobRenderer {
  explicit SkPictureJobRenderer(sk_sp<SkPicture> picture)
      : picture_(std::move(picture)) {}

  void Render(SkCanvas* canvas, const RenderJobInfo& info) {
    FML_DCHECK(info.opacity == SK_Scalar1);
    picture_->playback(canvas);
  }

 private:
  sk_sp<SkPicture> picture_;
};

struct DisplayListJobRenderer : public JobRenderer {
  explicit DisplayListJobRenderer(sk_sp<DisplayList> display_list)
      : display_list_(std::move(display_list)) {}

  void Render(SkCanvas* canvas, const RenderJobInfo& info) {
    display_list_->RenderTo(canvas, info.opacity);
  }

 private:
  sk_sp<DisplayList> display_list_;
};

class RenderEnvironment {
 public:
  RenderEnvironment(const DlSurfaceProvider* provider, PixelFormat format)
      : provider_(provider), format_(format) {
    if (provider->supports(format)) {
      surface_1x_ =
          provider->MakeOffscreenSurface(kTestWidth, kTestHeight, format);
      surface_2x_ = provider->MakeOffscreenSurface(kTestWidth * 2,
                                                   kTestHeight * 2, format);
    }
  }

  static RenderEnvironment Make565(const DlSurfaceProvider* provider) {
    return RenderEnvironment(provider, PixelFormat::k565_PixelFormat);
  }

  static RenderEnvironment MakeN32(const DlSurfaceProvider* provider) {
    return RenderEnvironment(provider, PixelFormat::kN32Premul_PixelFormat);
  }

  void init_ref(SkRenderer& sk_renderer,
                DlRenderer& dl_renderer,
                DlColor bg = DlColor::kTransparent()) {
    init_ref(kEmptySkSetup, sk_renderer, kEmptyDlSetup, dl_renderer, bg);
  }

  void init_ref(SkSetup& sk_setup,
                SkRenderer& sk_renderer,
                DlSetup& dl_setup,
                DlRenderer& dl_renderer,
                DlColor bg = DlColor::kTransparent()) {
    SkJobRenderer sk_job(sk_setup, sk_renderer);
    RenderJobInfo info = {
        .bg = bg,
    };
    ref_sk_result_ = getResult(info, sk_job);
    DlJobRenderer dl_job(dl_setup, dl_renderer);
    ref_dl_result_ = getResult(info, dl_job);
    ref_dl_paint_ = dl_job.setup_paint();
    ref_matrix_ = dl_job.setup_matrix();
    ref_clip_bounds_ = dl_job.setup_clip_bounds();
    ASSERT_EQ(sk_job.setup_matrix(), ref_matrix_);
    ASSERT_EQ(sk_job.setup_clip_bounds(), ref_clip_bounds_);
  }

  std::unique_ptr<RenderResult> getResult(const RenderJobInfo& info,
                                          JobRenderer& renderer) const {
    auto surface = getSurface(info.width, info.height);
    FML_DCHECK(surface != nullptr);
    auto canvas = surface->getCanvas();
    canvas->clear(info.bg);

    int restore_count = canvas->save();
    canvas->scale(info.scale, info.scale);
    renderer.Render(canvas, info);
    canvas->restoreToCount(restore_count);

    canvas->flush();
    surface->flushAndSubmit(true);
    return std::make_unique<RenderResult>(surface);
  }

  std::unique_ptr<RenderResult> getResult(sk_sp<DisplayList> dl) const {
    DisplayListJobRenderer job(std::move(dl));
    RenderJobInfo info = {};
    return getResult(info, job);
  }

  const DlSurfaceProvider* provider() const { return provider_; }
  bool valid() const { return provider_->supports(format_); }
  const std::string backend_name() const { return provider_->backend_name(); }

  PixelFormat format() const { return format_; }
  const DlPaint& ref_dl_paint() const { return ref_dl_paint_; }
  const SkMatrix& ref_matrix() const { return ref_matrix_; }
  const SkIRect& ref_clip_bounds() const { return ref_clip_bounds_; }
  const RenderResult* ref_sk_result() const { return ref_sk_result_.get(); }
  const RenderResult* ref_dl_result() const { return ref_dl_result_.get(); }

 private:
  sk_sp<SkSurface> getSurface(int width, int height) const {
    FML_DCHECK(valid());
    FML_DCHECK(surface_1x_ != nullptr);
    FML_DCHECK(surface_2x_ != nullptr);
    if (width == kTestWidth && height == kTestHeight) {
      return surface_1x_->sk_surface();
    }
    if (width == kTestWidth * 2 && height == kTestHeight * 2) {
      return surface_2x_->sk_surface();
    }
    FML_LOG(ERROR) << "Test surface size (" << width << " x " << height
                   << ") not supported.";
    FML_DCHECK(false);
    return nullptr;
  }

  const DlSurfaceProvider* provider_;
  const PixelFormat format_;
  std::shared_ptr<DlSurfaceInstance> surface_1x_;
  std::shared_ptr<DlSurfaceInstance> surface_2x_;

  DlPaint ref_dl_paint_;
  SkMatrix ref_matrix_;
  SkIRect ref_clip_bounds_;
  std::unique_ptr<RenderResult> ref_sk_result_;
  std::unique_ptr<RenderResult> ref_dl_result_;
};

class CaseParameters {
 public:
  explicit CaseParameters(std::string info)
      : CaseParameters(std::move(info), kEmptySkSetup, kEmptyDlSetup) {}

  CaseParameters(std::string info, SkSetup& sk_setup, DlSetup& dl_setup)
      : CaseParameters(std::move(info),
                       sk_setup,
                       dl_setup,
                       kEmptySkRenderer,
                       kEmptyDlRenderer,
                       SK_ColorTRANSPARENT,
                       false,
                       false,
                       false) {}

  CaseParameters(std::string info,
                 SkSetup& sk_setup,
                 DlSetup& dl_setup,
                 SkRenderer& sk_restore,
                 DlRenderer& dl_restore,
                 DlColor bg,
                 bool has_diff_clip,
                 bool has_mutating_save_layer,
                 bool fuzzy_compare_components)
      : info_(std::move(info)),
        bg_(bg),
        sk_setup_(sk_setup),
        dl_setup_(dl_setup),
        sk_restore_(sk_restore),
        dl_restore_(dl_restore),
        has_diff_clip_(has_diff_clip),
        has_mutating_save_layer_(has_mutating_save_layer),
        fuzzy_compare_components_(fuzzy_compare_components) {}

  CaseParameters with_restore(SkRenderer& sk_restore,
                              DlRenderer& dl_restore,
                              bool mutating_layer,
                              bool fuzzy_compare_components = false) {
    return CaseParameters(info_, sk_setup_, dl_setup_, sk_restore, dl_restore,
                          bg_, has_diff_clip_, mutating_layer,
                          fuzzy_compare_components);
  }

  CaseParameters with_bg(DlColor bg) {
    return CaseParameters(info_, sk_setup_, dl_setup_, sk_restore_, dl_restore_,
                          bg, has_diff_clip_, has_mutating_save_layer_,
                          fuzzy_compare_components_);
  }

  CaseParameters with_diff_clip() {
    return CaseParameters(info_, sk_setup_, dl_setup_, sk_restore_, dl_restore_,
                          bg_, true, has_mutating_save_layer_,
                          fuzzy_compare_components_);
  }

  std::string info() const { return info_; }
  DlColor bg() const { return bg_; }
  bool has_diff_clip() const { return has_diff_clip_; }
  bool has_mutating_save_layer() const { return has_mutating_save_layer_; }
  bool fuzzy_compare_components() const { return fuzzy_compare_components_; }

  SkSetup sk_setup() const { return sk_setup_; }
  DlSetup dl_setup() const { return dl_setup_; }
  SkRenderer sk_restore() const { return sk_restore_; }
  DlRenderer dl_restore() const { return dl_restore_; }

 private:
  const std::string info_;
  const DlColor bg_;
  const SkSetup sk_setup_;
  const DlSetup dl_setup_;
  const SkRenderer sk_restore_;
  const DlRenderer dl_restore_;
  const bool has_diff_clip_;
  const bool has_mutating_save_layer_;
  const bool fuzzy_compare_components_;
};

class TestParameters {
 public:
  TestParameters(const SkRenderer& sk_renderer,
                 const DlRenderer& dl_renderer,
                 const DisplayListAttributeFlags& flags)
      : sk_renderer_(sk_renderer), dl_renderer_(dl_renderer), flags_(flags) {}

  bool uses_paint() const { return !flags_.ignores_paint(); }

  bool should_match(const RenderEnvironment& env,
                    const CaseParameters& caseP,
                    const DlPaint& attr,
                    const MatrixClipJobRenderer& renderer) const {
    if (caseP.has_mutating_save_layer()) {
      return false;
    }
    if (env.ref_clip_bounds() != renderer.setup_clip_bounds() ||
        caseP.has_diff_clip()) {
      return false;
    }
    if (env.ref_matrix() != renderer.setup_matrix() && !flags_.is_flood()) {
      return false;
    }
    if (flags_.ignores_paint()) {
      return true;
    }
    const DlPaint& ref_attr = env.ref_dl_paint();
    if (flags_.applies_anti_alias() &&  //
        ref_attr.isAntiAlias() != attr.isAntiAlias()) {
      return false;
    }
    if (flags_.applies_dither() &&  //
        ref_attr.isDither() != attr.isDither()) {
      return false;
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

    DisplayListSpecialGeometryFlags geo_flags =
        flags_.WithPathEffect(attr.getPathEffect().get());
    if (flags_.applies_path_effect() &&  //
        ref_attr.getPathEffect() != attr.getPathEffect()) {
      if (attr.getPathEffect()->asDash() == nullptr) {
        return false;
      }
      if (!ignores_dashes()) {
        return false;
      }
    }
    bool is_stroked = flags_.is_stroked(ref_attr.getDrawStyle());
    if (flags_.is_stroked(attr.getDrawStyle()) != is_stroked) {
      return false;
    }
    if (!is_stroked) {
      return true;
    }
    if (ref_attr.getStrokeWidth() != attr.getStrokeWidth()) {
      return false;
    }
    if (geo_flags.may_have_end_caps() &&  //
        getCap(ref_attr, geo_flags) != getCap(attr, geo_flags)) {
      return false;
    }
    if (geo_flags.may_have_joins()) {
      if (ref_attr.getStrokeJoin() != attr.getStrokeJoin()) {
        return false;
      }
      if (ref_attr.getStrokeJoin() == DlStrokeJoin::kMiter) {
        SkScalar ref_miter = ref_attr.getStrokeMiter();
        SkScalar test_miter = attr.getStrokeMiter();
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
                               const SkMatrix& matrix) const {
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
        SkScalar miter_pad =
            paint.getStrokeMiter() * paint.getStrokeWidth() * 0.5f;
        return tolerance.addBoundsPadding(miter_pad, miter_pad);
      }
    }
    return tolerance;
  }

  const BoundsTolerance lineAdjust(const BoundsTolerance& tolerance,
                                   const DlPaint& paint,
                                   const SkMatrix& matrix) const {
    SkScalar adjust = 0.0;
    SkScalar half_width = paint.getStrokeWidth() * 0.5f;
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
    auto path_effect = paint.getPathEffect();

    DisplayListSpecialGeometryFlags geo_flags =
        flags_.WithPathEffect(path_effect.get());
    if (paint.getStrokeCap() == DlStrokeCap::kButt &&
        !geo_flags.butt_cap_becomes_square()) {
      adjust = std::max(adjust, half_width);
    }
    if (adjust == 0) {
      return tolerance;
    }
    SkScalar h_tolerance;
    SkScalar v_tolerance;
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

  const SkRenderer& sk_renderer() const { return sk_renderer_; }
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
  const SkRenderer& sk_renderer_;
  const DlRenderer& dl_renderer_;
  const DisplayListAttributeFlags& flags_;

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
 public:
  static std::vector<std::unique_ptr<DlSurfaceProvider>> kTestProviders;

  static BoundsTolerance DefaultTolerance;

  static void RenderAll(const TestParameters& params,
                        const BoundsTolerance& tolerance = DefaultTolerance) {
    for (auto& provider : kTestProviders) {
      RenderEnvironment env = RenderEnvironment::MakeN32(provider.get());
      env.init_ref(params.sk_renderer(), params.dl_renderer());
      quickCompareToReference(env, "default");
      RenderWithTransforms(params, env, tolerance);
      RenderWithClips(params, env, tolerance);
      RenderWithSaveRestore(params, env, tolerance);
      // Only test attributes if the canvas version uses the paint object
      if (params.uses_paint()) {
        RenderWithAttributes(params, env, tolerance);
      }
    }
  }

  static void RenderWithSaveRestore(const TestParameters& testP,
                                    const RenderEnvironment& env,
                                    const BoundsTolerance& tolerance) {
    SkRect clip =
        SkRect::MakeXYWH(kRenderCenterX - 1, kRenderCenterY - 1, 2, 2);
    SkRect rect = SkRect::MakeXYWH(kRenderCenterX, kRenderCenterY, 10, 10);
    DlColor alpha_layer_color = DlColor::kCyan().withAlpha(0x7f);
    SkRenderer sk_safe_restore = [=](SkCanvas* cv, const SkPaint& p) {
      // Draw another primitive to disable peephole optimizations
      cv->drawRect(kRenderBounds.makeOffset(500, 500), SkPaint());
      cv->restore();
    };
    DlRenderer dl_safe_restore = [=](DlCanvas* cv, const DlPaint& p) {
      // Draw another primitive to disable peephole optimizations
      cv->DrawRect(kRenderBounds.makeOffset(500, 500), DlPaint());
      cv->Restore();
    };
    SkRenderer sk_opt_restore = [=](SkCanvas* cv, const SkPaint& p) {
      // Just a simple restore to allow peephole optimizations to occur
      cv->restore();
    };
    DlRenderer dl_opt_restore = [=](DlCanvas* cv, const DlPaint& p) {
      // Just a simple restore to allow peephole optimizations to occur
      cv->Restore();
    };
    SkRect layer_bounds = kRenderBounds.makeInset(15, 15);
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "With prior save/clip/restore",
                   [=](SkCanvas* cv, SkPaint& p) {
                     cv->save();
                     cv->clipRect(clip, SkClipOp::kIntersect, false);
                     SkPaint p2;
                     cv->drawRect(rect, p2);
                     p2.setBlendMode(SkBlendMode::kClear);
                     cv->drawRect(rect, p2);
                     cv->restore();
                   },
                   [=](DlCanvas* cv, DlPaint& p) {
                     cv->Save();
                     cv->ClipRect(clip, ClipOp::kIntersect, false);
                     DlPaint p2;
                     cv->DrawRect(rect, p2);
                     p2.setBlendMode(DlBlendMode::kClear);
                     cv->DrawRect(rect, p2);
                     cv->Restore();
                   }));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer no paint, no bounds",
                   [=](SkCanvas* cv, SkPaint& p) {  //
                     cv->saveLayer(nullptr, nullptr);
                   },
                   [=](DlCanvas* cv, DlPaint& p) {  //
                     cv->SaveLayer(nullptr, nullptr);
                   })
                   .with_restore(sk_safe_restore, dl_safe_restore, false));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer no paint, with bounds",
                   [=](SkCanvas* cv, SkPaint& p) {  //
                     cv->saveLayer(layer_bounds, nullptr);
                   },
                   [=](DlCanvas* cv, DlPaint& p) {  //
                     cv->SaveLayer(&layer_bounds, nullptr);
                   })
                   .with_restore(sk_safe_restore, dl_safe_restore, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with alpha, no bounds",
                   [=](SkCanvas* cv, SkPaint& p) {
                     SkPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->saveLayer(nullptr, &save_p);
                   },
                   [=](DlCanvas* cv, DlPaint& p) {
                     DlPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->SaveLayer(nullptr, &save_p);
                   })
                   .with_restore(sk_safe_restore, dl_safe_restore, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with peephole alpha, no bounds",
                   [=](SkCanvas* cv, SkPaint& p) {
                     SkPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->saveLayer(nullptr, &save_p);
                   },
                   [=](DlCanvas* cv, DlPaint& p) {
                     DlPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->SaveLayer(nullptr, &save_p);
                   })
                   .with_restore(sk_opt_restore, dl_opt_restore, true, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with alpha and bounds",
                   [=](SkCanvas* cv, SkPaint& p) {
                     SkPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->saveLayer(layer_bounds, &save_p);
                   },
                   [=](DlCanvas* cv, DlPaint& p) {
                     DlPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->SaveLayer(&layer_bounds, &save_p);
                   })
                   .with_restore(sk_safe_restore, dl_safe_restore, true));
    {
      // Being able to see a backdrop blur requires a non-default background
      // so we create a new environment for these tests that has a checkerboard
      // background that can be blurred by the backdrop filter. We also want
      // to avoid the rendered primitive from obscuring the blurred background
      // so we set an alpha value which works for all primitives except for
      // drawColor which can override the alpha with its color, but it now uses
      // a non-opaque color to avoid that problem.
      RenderEnvironment backdrop_env =
          RenderEnvironment::MakeN32(env.provider());
      SkSetup sk_backdrop_setup = [=](SkCanvas* cv, SkPaint& p) {
        SkPaint setup_p;
        setup_p.setShader(kTestImageColorSource.skia_object());
        cv->drawPaint(setup_p);
      };
      DlSetup dl_backdrop_setup = [=](DlCanvas* cv, DlPaint& p) {
        DlPaint setup_p;
        setup_p.setColorSource(&kTestImageColorSource);
        cv->DrawPaint(setup_p);
      };
      SkSetup sk_content_setup = [=](SkCanvas* cv, SkPaint& p) {
        p.setAlpha(p.getAlpha() / 2);
      };
      DlSetup dl_content_setup = [=](DlCanvas* cv, DlPaint& p) {
        p.setAlpha(p.getAlpha() / 2);
      };
      backdrop_env.init_ref(sk_backdrop_setup, testP.sk_renderer(),
                            dl_backdrop_setup, testP.dl_renderer());
      quickCompareToReference(backdrop_env, "backdrop");

      DlBlurImageFilter backdrop(5, 5, DlTileMode::kDecal);
      RenderWith(testP, backdrop_env, tolerance,
                 CaseParameters(
                     "saveLayer with backdrop",
                     [=](SkCanvas* cv, SkPaint& p) {
                       sk_backdrop_setup(cv, p);
                       cv->saveLayer(SkCanvas::SaveLayerRec(
                           nullptr, nullptr, backdrop.skia_object().get(), 0));
                       sk_content_setup(cv, p);
                     },
                     [=](DlCanvas* cv, DlPaint& p) {
                       dl_backdrop_setup(cv, p);
                       cv->SaveLayer(nullptr, nullptr, &backdrop);
                       dl_content_setup(cv, p);
                     })
                     .with_restore(sk_safe_restore, dl_safe_restore, true));
      RenderWith(
          testP, backdrop_env, tolerance,
          CaseParameters(
              "saveLayer with bounds and backdrop",
              [=](SkCanvas* cv, SkPaint& p) {
                sk_backdrop_setup(cv, p);
                cv->saveLayer(SkCanvas::SaveLayerRec(
                    &layer_bounds, nullptr, backdrop.skia_object().get(), 0));
                sk_content_setup(cv, p);
              },
              [=](DlCanvas* cv, DlPaint& p) {
                dl_backdrop_setup(cv, p);
                cv->SaveLayer(&layer_bounds, nullptr, &backdrop);
                dl_content_setup(cv, p);
              })
              .with_restore(sk_safe_restore, dl_safe_restore, true));
      RenderWith(testP, backdrop_env, tolerance,
                 CaseParameters(
                     "clipped saveLayer with backdrop",
                     [=](SkCanvas* cv, SkPaint& p) {
                       sk_backdrop_setup(cv, p);
                       cv->clipRect(layer_bounds);
                       cv->saveLayer(SkCanvas::SaveLayerRec(
                           nullptr, nullptr, backdrop.skia_object().get(), 0));
                       sk_content_setup(cv, p);
                     },
                     [=](DlCanvas* cv, DlPaint& p) {
                       dl_backdrop_setup(cv, p);
                       cv->ClipRect(layer_bounds);
                       cv->SaveLayer(nullptr, nullptr, &backdrop);
                       dl_content_setup(cv, p);
                     })
                     .with_restore(sk_safe_restore, dl_safe_restore, true));
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
      DlMatrixColorFilter filter(rotate_alpha_color_matrix);
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ColorFilter, no bounds",
                       [=](SkCanvas* cv, SkPaint& p) {
                         SkPaint save_p;
                         save_p.setColorFilter(filter.skia_object());
                         cv->saveLayer(nullptr, &save_p);
                         p.setStrokeWidth(5.0);
                       },
                       [=](DlCanvas* cv, DlPaint& p) {
                         DlPaint save_p;
                         save_p.setColorFilter(&filter);
                         cv->SaveLayer(nullptr, &save_p);
                         p.setStrokeWidth(5.0);
                       })
                       .with_restore(sk_safe_restore, dl_safe_restore, true));
      }
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ColorFilter and bounds",
                       [=](SkCanvas* cv, SkPaint& p) {
                         SkPaint save_p;
                         save_p.setColorFilter(filter.skia_object());
                         cv->saveLayer(kRenderBounds, &save_p);
                         p.setStrokeWidth(5.0);
                       },
                       [=](DlCanvas* cv, DlPaint& p) {
                         DlPaint save_p;
                         save_p.setColorFilter(&filter);
                         cv->SaveLayer(&kRenderBounds, &save_p);
                         p.setStrokeWidth(5.0);
                       })
                       .with_restore(sk_safe_restore, dl_safe_restore, true));
      }
    }
    {
      sk_sp<SkImageFilter> sk_filter = SkImageFilters::Arithmetic(
          0.1, 0.1, 0.1, 0.25, true, nullptr, nullptr);
      DlUnknownImageFilter filter(sk_filter);
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ImageFilter, no bounds",
                       [=](SkCanvas* cv, SkPaint& p) {
                         SkPaint save_p;
                         save_p.setImageFilter(filter.skia_object());
                         cv->saveLayer(nullptr, &save_p);
                         p.setStrokeWidth(5.0);
                       },
                       [=](DlCanvas* cv, DlPaint& p) {
                         DlPaint save_p;
                         save_p.setImageFilter(&filter);
                         cv->SaveLayer(nullptr, &save_p);
                         p.setStrokeWidth(5.0);
                       })
                       .with_restore(sk_safe_restore, dl_safe_restore, true));
      }
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ImageFilter and bounds",
                       [=](SkCanvas* cv, SkPaint& p) {
                         SkPaint save_p;
                         save_p.setImageFilter(filter.skia_object());
                         cv->saveLayer(kRenderBounds, &save_p);
                         p.setStrokeWidth(5.0);
                       },
                       [=](DlCanvas* cv, DlPaint& p) {
                         DlPaint save_p;
                         save_p.setImageFilter(&filter);
                         cv->SaveLayer(&kRenderBounds, &save_p);
                         p.setStrokeWidth(5.0);
                       })
                       .with_restore(sk_safe_restore, dl_safe_restore, true));
      }
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
      RenderEnvironment aa_env = RenderEnvironment::MakeN32(env.provider());
      // Tweak the bounds tolerance for the displacement of 1/10 of a pixel
      const BoundsTolerance aa_tolerance = tolerance.addBoundsPadding(1, 1);
      auto sk_aa_setup = [=](SkCanvas* cv, SkPaint& p, bool is_aa) {
        cv->translate(0.1, 0.1);
        p.setAntiAlias(is_aa);
        p.setStrokeWidth(5.0);
      };
      auto dl_aa_setup = [=](DlCanvas* cv, DlPaint& p, bool is_aa) {
        cv->Translate(0.1, 0.1);
        p.setAntiAlias(is_aa);
        p.setStrokeWidth(5.0);
      };
      aa_env.init_ref(
          [=](SkCanvas* cv, SkPaint& p) { sk_aa_setup(cv, p, false); },
          testP.sk_renderer(),
          [=](DlCanvas* cv, DlPaint& p) { dl_aa_setup(cv, p, false); },
          testP.dl_renderer());
      quickCompareToReference(aa_env, "AntiAlias");
      RenderWith(
          testP, aa_env, aa_tolerance,
          CaseParameters(
              "AntiAlias == True",
              [=](SkCanvas* cv, SkPaint& p) { sk_aa_setup(cv, p, true); },
              [=](DlCanvas* cv, DlPaint& p) { dl_aa_setup(cv, p, true); }));
      RenderWith(
          testP, aa_env, aa_tolerance,
          CaseParameters(
              "AntiAlias == False",
              [=](SkCanvas* cv, SkPaint& p) { sk_aa_setup(cv, p, false); },
              [=](DlCanvas* cv, DlPaint& p) { dl_aa_setup(cv, p, false); }));
    }

    {
      // The CPU renderer does not always dither for solid colors and we
      // need to use a non-default color (default is black) on an opaque
      // surface, so we use a shader instead of a color. Also, thin stroked
      // primitives (mainly drawLine and drawPoints) do not show much
      // dithering so we use a non-trivial stroke width as well.
      RenderEnvironment dither_env = RenderEnvironment::Make565(env.provider());
      if (!dither_env.valid()) {
        // Currently only happens on Metal backend
        static std::set<std::string> warnings_sent;
        std::string name = dither_env.backend_name();
        if (warnings_sent.find(name) == warnings_sent.end()) {
          warnings_sent.insert(name);
          FML_LOG(INFO) << "Skipping Dithering tests on " << name;
        }
      } else {
        DlColor dither_bg = DlColor::kBlack();
        SkSetup sk_dither_setup = [=](SkCanvas*, SkPaint& p) {
          p.setShader(kTestImageColorSource.skia_object());
          p.setAlpha(0xf0);
          p.setStrokeWidth(5.0);
        };
        DlSetup dl_dither_setup = [=](DlCanvas*, DlPaint& p) {
          p.setColorSource(&kTestImageColorSource);
          p.setAlpha(0xf0);
          p.setStrokeWidth(5.0);
        };
        dither_env.init_ref(sk_dither_setup, testP.sk_renderer(),
                            dl_dither_setup, testP.dl_renderer(), dither_bg);
        quickCompareToReference(dither_env, "dither");
        RenderWith(testP, dither_env, tolerance,
                   CaseParameters(
                       "Dither == True",
                       [=](SkCanvas* cv, SkPaint& p) {
                         sk_dither_setup(cv, p);
                         p.setDither(true);
                       },
                       [=](DlCanvas* cv, DlPaint& p) {
                         dl_dither_setup(cv, p);
                         p.setDither(true);
                       })
                       .with_bg(dither_bg));
        RenderWith(testP, dither_env, tolerance,
                   CaseParameters(
                       "Dither = False",
                       [=](SkCanvas* cv, SkPaint& p) {
                         sk_dither_setup(cv, p);
                         p.setDither(false);
                       },
                       [=](DlCanvas* cv, DlPaint& p) {
                         dl_dither_setup(cv, p);
                         p.setDither(false);
                       })
                       .with_bg(dither_bg));
      }
    }

    RenderWith(
        testP, env, tolerance,
        CaseParameters(
            "Color == Blue",
            [=](SkCanvas*, SkPaint& p) { p.setColor(SK_ColorBLUE); },
            [=](DlCanvas*, DlPaint& p) { p.setColor(DlColor::kBlue()); }));
    RenderWith(
        testP, env, tolerance,
        CaseParameters(
            "Color == Green",
            [=](SkCanvas*, SkPaint& p) { p.setColor(SK_ColorGREEN); },
            [=](DlCanvas*, DlPaint& p) { p.setColor(DlColor::kGreen()); }));

    RenderWithStrokes(testP, env, tolerance);

    {
      // half opaque cyan
      DlColor blendable_color = DlColor::kCyan().withAlpha(0x7f);
      DlColor bg = DlColor::kWhite();

      RenderWith(testP, env, tolerance,
                 CaseParameters(
                     "Blend == SrcIn",
                     [=](SkCanvas*, SkPaint& p) {
                       p.setBlendMode(SkBlendMode::kSrcIn);
                       p.setColor(blendable_color);
                     },
                     [=](DlCanvas*, DlPaint& p) {
                       p.setBlendMode(DlBlendMode::kSrcIn);
                       p.setColor(blendable_color);
                     })
                     .with_bg(bg));
      RenderWith(testP, env, tolerance,
                 CaseParameters(
                     "Blend == DstIn",
                     [=](SkCanvas*, SkPaint& p) {
                       p.setBlendMode(SkBlendMode::kDstIn);
                       p.setColor(blendable_color);
                     },
                     [=](DlCanvas*, DlPaint& p) {
                       p.setBlendMode(DlBlendMode::kDstIn);
                       p.setColor(blendable_color);
                     })
                     .with_bg(bg));
    }

    {
      // Being able to see a blur requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment blur_env = RenderEnvironment::MakeN32(env.provider());
      SkSetup sk_blur_setup = [=](SkCanvas*, SkPaint& p) {
        p.setShader(kTestImageColorSource.skia_object());
        p.setStrokeWidth(5.0);
      };
      DlSetup dl_blur_setup = [=](DlCanvas*, DlPaint& p) {
        p.setColorSource(&kTestImageColorSource);
        p.setStrokeWidth(5.0);
      };
      blur_env.init_ref(sk_blur_setup, testP.sk_renderer(),  //
                        dl_blur_setup, testP.dl_renderer());
      quickCompareToReference(blur_env, "blur");
      DlBlurImageFilter filter_decal_5(5.0, 5.0, DlTileMode::kDecal);
      BoundsTolerance blur_5_tolerance = tolerance.addBoundsPadding(4, 4);
      {
        RenderWith(testP, blur_env, blur_5_tolerance,
                   CaseParameters(
                       "ImageFilter == Decal Blur 5",
                       [=](SkCanvas* cv, SkPaint& p) {
                         sk_blur_setup(cv, p);
                         p.setImageFilter(filter_decal_5.skia_object());
                       },
                       [=](DlCanvas* cv, DlPaint& p) {
                         dl_blur_setup(cv, p);
                         p.setImageFilter(&filter_decal_5);
                       }));
      }
      DlBlurImageFilter filter_clamp_5(5.0, 5.0, DlTileMode::kClamp);
      {
        RenderWith(testP, blur_env, blur_5_tolerance,
                   CaseParameters(
                       "ImageFilter == Clamp Blur 5",
                       [=](SkCanvas* cv, SkPaint& p) {
                         sk_blur_setup(cv, p);
                         p.setImageFilter(filter_clamp_5.skia_object());
                       },
                       [=](DlCanvas* cv, DlPaint& p) {
                         dl_blur_setup(cv, p);
                         p.setImageFilter(&filter_clamp_5);
                       }));
      }
    }

    {
      // Being able to see a dilate requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment dilate_env = RenderEnvironment::MakeN32(env.provider());
      SkSetup sk_dilate_setup = [=](SkCanvas*, SkPaint& p) {
        p.setShader(kTestImageColorSource.skia_object());
        p.setStrokeWidth(5.0);
      };
      DlSetup dl_dilate_setup = [=](DlCanvas*, DlPaint& p) {
        p.setColorSource(&kTestImageColorSource);
        p.setStrokeWidth(5.0);
      };
      dilate_env.init_ref(sk_dilate_setup, testP.sk_renderer(),  //
                          dl_dilate_setup, testP.dl_renderer());
      quickCompareToReference(dilate_env, "dilate");
      DlDilateImageFilter filter_5(5.0, 5.0);
      RenderWith(testP, dilate_env, tolerance,
                 CaseParameters(
                     "ImageFilter == Dilate 5",
                     [=](SkCanvas* cv, SkPaint& p) {
                       sk_dilate_setup(cv, p);
                       p.setImageFilter(filter_5.skia_object());
                     },
                     [=](DlCanvas* cv, DlPaint& p) {
                       dl_dilate_setup(cv, p);
                       p.setImageFilter(&filter_5);
                     }));
    }

    {
      // Being able to see an erode requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment erode_env = RenderEnvironment::MakeN32(env.provider());
      SkSetup sk_erode_setup = [=](SkCanvas*, SkPaint& p) {
        p.setShader(kTestImageColorSource.skia_object());
        p.setStrokeWidth(6.0);
      };
      DlSetup dl_erode_setup = [=](DlCanvas*, DlPaint& p) {
        p.setColorSource(&kTestImageColorSource);
        p.setStrokeWidth(6.0);
      };
      erode_env.init_ref(sk_erode_setup, testP.sk_renderer(),  //
                         dl_erode_setup, testP.dl_renderer());
      quickCompareToReference(erode_env, "erode");
      // do not erode too much, because some tests assert there are enough
      // pixels that are changed.
      DlErodeImageFilter filter_1(1.0, 1.0);
      RenderWith(testP, erode_env, tolerance,
                 CaseParameters(
                     "ImageFilter == Erode 1",
                     [=](SkCanvas* cv, SkPaint& p) {
                       sk_erode_setup(cv, p);
                       p.setImageFilter(filter_1.skia_object());
                     },
                     [=](DlCanvas* cv, DlPaint& p) {
                       dl_erode_setup(cv, p);
                       p.setImageFilter(&filter_1);
                     }));
    }

    {
      // clang-format off
      constexpr float rotate_color_matrix[20] = {
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          1, 0, 0, 0, 0,
          0, 0, 0, 1, 0,
      };
      constexpr float invert_color_matrix[20] = {
        -1.0,    0,    0, 1.0,   0,
           0, -1.0,    0, 1.0,   0,
           0,    0, -1.0, 1.0,   0,
         1.0,  1.0,  1.0, 1.0,   0,
      };
      // clang-format on
      DlMatrixColorFilter filter(rotate_color_matrix);
      {
        DlColor bg = DlColor::kWhite();
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "ColorFilter == RotateRGB",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setColor(DlColor::kYellow());
                         p.setColorFilter(filter.skia_object());
                       },
                       [=](DlCanvas*, DlPaint& p) {
                         p.setColor(DlColor::kYellow());
                         p.setColorFilter(&filter);
                       })
                       .with_bg(bg));
      }
      filter = DlMatrixColorFilter(invert_color_matrix);
      {
        DlColor bg = DlColor::kWhite();
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "ColorFilter == Invert",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setColor(DlColor::kYellow());
                         p.setColorFilter(filter.skia_object());
                       },
                       [=](DlCanvas*, DlPaint& p) {
                         p.setColor(DlColor::kYellow());
                         p.setInvertColors(true);
                       })
                       .with_bg(bg));
      }
    }

    {
      sk_sp<SkPathEffect> effect = SkDiscretePathEffect::Make(3, 5);
      {
        // Discrete path effects need a stroke width for drawPointsAsPoints
        // to do something realistic
        // And a Discrete(3, 5) effect produces miters that are near
        // maximal for a miter limit of 3.0.
        BoundsTolerance discrete_tolerance =
            tolerance
                // register the discrete offset so adjusters can compensate
                .addDiscreteOffset(5)
                // the miters in the 3-5 discrete effect don't always fill
                // their conservative bounds, so tolerate a couple of pixels
                .addBoundsPadding(2, 2);
        RenderWith(testP, env, discrete_tolerance,
                   CaseParameters(
                       "PathEffect == Discrete-3-5",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setStrokeMiter(3.0);
                         p.setPathEffect(effect);
                       },
                       [=](DlCanvas*, DlPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setStrokeMiter(3.0);
                         p.setPathEffect(DlPathEffect::From(effect));
                       }));
      }
      EXPECT_TRUE(testP.is_draw_text_blob() || effect->unique())
          << "PathEffect == Discrete-3-5 Cleanup";
      effect = SkDiscretePathEffect::Make(2, 3);
      {
        // Discrete path effects need a stroke width for drawPointsAsPoints
        // to do something realistic
        // And a Discrete(2, 3) effect produces miters that are near
        // maximal for a miter limit of 2.5.
        BoundsTolerance discrete_tolerance =
            tolerance
                // register the discrete offset so adjusters can compensate
                .addDiscreteOffset(3)
                // the miters in the 3-5 discrete effect don't always fill
                // their conservative bounds, so tolerate a couple of pixels
                .addBoundsPadding(2, 2);
        RenderWith(testP, env, discrete_tolerance,
                   CaseParameters(
                       "PathEffect == Discrete-2-3",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setStrokeMiter(2.5);
                         p.setPathEffect(effect);
                       },
                       [=](DlCanvas*, DlPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setStrokeMiter(2.5);
                         p.setPathEffect(DlPathEffect::From(effect));
                       }));
      }
      EXPECT_TRUE(testP.is_draw_text_blob() || effect->unique())
          << "PathEffect == Discrete-2-3 Cleanup";
    }

    {
      const DlBlurMaskFilter filter(kNormal_SkBlurStyle, 5.0);
      BoundsTolerance blur_5_tolerance = tolerance.addBoundsPadding(4, 4);
      {
        // Stroked primitives need some non-trivial stroke size to be blurred
        RenderWith(testP, env, blur_5_tolerance,
                   CaseParameters(
                       "MaskFilter == Blur 5",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setMaskFilter(filter.skia_object());
                       },
                       [=](DlCanvas*, DlPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setMaskFilter(&filter);
                       }));
      }
    }

    {
      SkPoint end_points[] = {
          SkPoint::Make(kRenderBounds.fLeft, kRenderBounds.fTop),
          SkPoint::Make(kRenderBounds.fRight, kRenderBounds.fBottom),
      };
      DlColor colors[] = {
          DlColor::kGreen(),
          DlColor::kYellow().withAlpha(0x7f),
          DlColor::kBlue(),
      };
      float stops[] = {
          0.0,
          0.5,
          1.0,
      };
      std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
          end_points[0], end_points[1], 3, colors, stops, DlTileMode::kMirror);
      {
        RenderWith(
            testP, env, tolerance,
            CaseParameters(
                "LinearGradient GYB",
                [=](SkCanvas*, SkPaint& p) {
                  p.setShader(source->skia_object());
                },
                [=](DlCanvas*, DlPaint& p) { p.setColorSource(source); }));
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
    BoundsTolerance tolerance = tolerance_in.addBoundsPadding(2, 2);
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Fill",
                   [=](SkCanvas*, SkPaint& p) {  //
                     p.setStyle(SkPaint::kFill_Style);
                   },
                   [=](DlCanvas*, DlPaint& p) {  //
                     p.setDrawStyle(DlDrawStyle::kFill);
                   }));
    // Skia on HW produces a strong miter consistent with width=1.0
    // for any width less than a pixel, but the bounds computations of
    // both DL and SkPicture do not account for this. We will get
    // OOB pixel errors for the highly mitered drawPath geometry if
    // we don't set stroke width to 1.0 for that test on HW.
    // See https://bugs.chromium.org/p/skia/issues/detail?id=14046
    bool no_hairlines =
        testP.is_draw_path() &&
        env.provider()->backend_type() != BackendType::kSoftware_Backend;
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Stroke + defaults",
                   [=](SkCanvas*, SkPaint& p) {  //
                     if (no_hairlines) {
                       p.setStrokeWidth(1.0);
                     }
                     p.setStyle(SkPaint::kStroke_Style);
                   },
                   [=](DlCanvas*, DlPaint& p) {  //
                     if (no_hairlines) {
                       p.setStrokeWidth(1.0);
                     }
                     p.setDrawStyle(DlDrawStyle::kStroke);
                   }));

    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Fill + unnecessary StrokeWidth 10",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kFill_Style);
                     p.setStrokeWidth(10.0);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kFill);
                     p.setStrokeWidth(10.0);
                   }));

    RenderEnvironment stroke_base_env =
        RenderEnvironment::MakeN32(env.provider());
    SkSetup sk_stroke_setup = [=](SkCanvas*, SkPaint& p) {
      p.setStyle(SkPaint::kStroke_Style);
      p.setStrokeWidth(5.0);
    };
    DlSetup dl_stroke_setup = [=](DlCanvas*, DlPaint& p) {
      p.setDrawStyle(DlDrawStyle::kStroke);
      p.setStrokeWidth(5.0);
    };
    stroke_base_env.init_ref(sk_stroke_setup, testP.sk_renderer(),
                             dl_stroke_setup, testP.dl_renderer());
    quickCompareToReference(stroke_base_env, "stroke");

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 10",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(10.0);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kStroke);
                     p.setStrokeWidth(10.0);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kStroke);
                     p.setStrokeWidth(5.0);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Square Cap",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeCap(SkPaint::kSquare_Cap);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kStroke);
                     p.setStrokeWidth(5.0);
                     p.setStrokeCap(DlStrokeCap::kSquare);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Round Cap",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeCap(SkPaint::kRound_Cap);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kStroke);
                     p.setStrokeWidth(5.0);
                     p.setStrokeCap(DlStrokeCap::kRound);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Bevel Join",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeJoin(SkPaint::kBevel_Join);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kStroke);
                     p.setStrokeWidth(5.0);
                     p.setStrokeJoin(DlStrokeJoin::kBevel);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Round Join",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeJoin(SkPaint::kRound_Join);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kStroke);
                     p.setStrokeWidth(5.0);
                     p.setStrokeJoin(DlStrokeJoin::kRound);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Miter 10",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeMiter(10.0);
                     p.setStrokeJoin(SkPaint::kMiter_Join);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kStroke);
                     p.setStrokeWidth(5.0);
                     p.setStrokeMiter(10.0);
                     p.setStrokeJoin(DlStrokeJoin::kMiter);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Miter 0",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeMiter(0.0);
                     p.setStrokeJoin(SkPaint::kMiter_Join);
                   },
                   [=](DlCanvas*, DlPaint& p) {
                     p.setDrawStyle(DlDrawStyle::kStroke);
                     p.setStrokeWidth(5.0);
                     p.setStrokeMiter(0.0);
                     p.setStrokeJoin(DlStrokeJoin::kMiter);
                   }));

    {
      const SkScalar test_dashes_1[] = {29.0, 2.0};
      const SkScalar test_dashes_2[] = {17.0, 1.5};
      auto effect = DlDashPathEffect::Make(test_dashes_1, 2, 0.0f);
      {
        RenderWith(testP, stroke_base_env, tolerance,
                   CaseParameters(
                       "PathEffect == Dash-29-2",
                       [=](SkCanvas*, SkPaint& p) {
                         // Need stroke style to see dashing properly
                         p.setStyle(SkPaint::kStroke_Style);
                         // Provide some non-trivial stroke size to get dashed
                         p.setStrokeWidth(5.0);
                         p.setPathEffect(effect->skia_object());
                       },
                       [=](DlCanvas*, DlPaint& p) {
                         // Need stroke style to see dashing properly
                         p.setDrawStyle(DlDrawStyle::kStroke);
                         // Provide some non-trivial stroke size to get dashed
                         p.setStrokeWidth(5.0);
                         p.setPathEffect(effect);
                       }));
      }
      effect = DlDashPathEffect::Make(test_dashes_2, 2, 0.0f);
      {
        RenderWith(testP, stroke_base_env, tolerance,
                   CaseParameters(
                       "PathEffect == Dash-17-1.5",
                       [=](SkCanvas*, SkPaint& p) {
                         // Need stroke style to see dashing properly
                         p.setStyle(SkPaint::kStroke_Style);
                         // Provide some non-trivial stroke size to get dashed
                         p.setStrokeWidth(5.0);
                         p.setPathEffect(effect->skia_object());
                       },
                       [=](DlCanvas*, DlPaint& p) {
                         // Need stroke style to see dashing properly
                         p.setDrawStyle(DlDrawStyle::kStroke);
                         // Provide some non-trivial stroke size to get dashed
                         p.setStrokeWidth(5.0);
                         p.setPathEffect(effect);
                       }));
      }
    }
  }

  static void RenderWithTransforms(const TestParameters& testP,
                                   const RenderEnvironment& env,
                                   const BoundsTolerance& tolerance) {
    // If the rendering method does not fill the corners of the original
    // bounds, then the estimate under rotation or skewing will be off
    // so we scale the padding by about 5% to compensate.
    BoundsTolerance skewed_tolerance = tolerance.mulScale(1.05, 1.05);
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Translate 5, 10",  //
                   [=](SkCanvas* c, SkPaint&) { c->translate(5, 10); },
                   [=](DlCanvas* c, DlPaint&) { c->Translate(5, 10); }));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Scale +5%",  //
                   [=](SkCanvas* c, SkPaint&) { c->scale(1.05, 1.05); },
                   [=](DlCanvas* c, DlPaint&) { c->Scale(1.05, 1.05); }));
    RenderWith(testP, env, skewed_tolerance,
               CaseParameters(
                   "Rotate 5 degrees",  //
                   [=](SkCanvas* c, SkPaint&) { c->rotate(5); },
                   [=](DlCanvas* c, DlPaint&) { c->Rotate(5); }));
    RenderWith(testP, env, skewed_tolerance,
               CaseParameters(
                   "Skew 5%",  //
                   [=](SkCanvas* c, SkPaint&) { c->skew(0.05, 0.05); },
                   [=](DlCanvas* c, DlPaint&) { c->Skew(0.05, 0.05); }));
    {
      // This rather odd transform can cause slight differences in
      // computing in-bounds samples depending on which base rendering
      // routine Skia uses. Making sure our matrix values are powers
      // of 2 reduces, but does not eliminate, these slight differences
      // in calculation when we are comparing rendering with an alpha
      // to rendering opaque colors in the group opacity tests, for
      // example.
      SkScalar tweak = 1.0 / 16.0;
      SkMatrix tx = SkMatrix::MakeAll(1.0 + tweak, tweak, 5,   //
                                      tweak, 1.0 + tweak, 10,  //
                                      0, 0, 1);
      RenderWith(testP, env, skewed_tolerance,
                 CaseParameters(
                     "Transform 2D Affine",
                     [=](SkCanvas* c, SkPaint&) { c->concat(tx); },
                     [=](DlCanvas* c, DlPaint&) { c->Transform(tx); }));
    }
    {
      SkM44 m44 = SkM44(1, 0, 0, kRenderCenterX,  //
                        0, 1, 0, kRenderCenterY,  //
                        0, 0, 1, 0,               //
                        0, 0, .001, 1);
      m44.preConcat(
          SkM44::Rotate({1, 0, 0}, math::kPi / 60));  // 3 degrees around X
      m44.preConcat(
          SkM44::Rotate({0, 1, 0}, math::kPi / 45));  // 4 degrees around Y
      m44.preTranslate(-kRenderCenterX, -kRenderCenterY);
      RenderWith(testP, env, skewed_tolerance,
                 CaseParameters(
                     "Transform Full Perspective",
                     [=](SkCanvas* c, SkPaint&) { c->concat(m44); },
                     [=](DlCanvas* c, DlPaint&) { c->Transform(m44); }));
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
    SkRect r_clip = kRenderBounds.makeInset(15.4, 15.4);
    BoundsTolerance intersect_tolerance = diff_tolerance.clip(r_clip);
    intersect_tolerance = intersect_tolerance.addPostClipPadding(1, 1);
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipRect inset by 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRect(r_clip, SkClipOp::kIntersect, false);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipRect(r_clip, ClipOp::kIntersect, false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipRect inset by 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRect(r_clip, SkClipOp::kIntersect, true);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipRect(r_clip, ClipOp::kIntersect, true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipRect Diff, inset by 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRect(r_clip, SkClipOp::kDifference, false);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipRect(r_clip, ClipOp::kDifference, false);
                   })
                   .with_diff_clip());
    // This test RR clip used to use very small radii, but due to
    // optimizations in the HW rrect rasterization, this caused small
    // bulges in the corners of the RRect which were interpreted as
    // "clip overruns" by the clip OOB pixel testing code. Using less
    // abusively small radii fixes the problem.
    SkRRect rr_clip = SkRRect::MakeRectXY(r_clip, 9, 9);
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipRRect with radius of 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRRect(rr_clip, SkClipOp::kIntersect, false);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipRRect(rr_clip, ClipOp::kIntersect, false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipRRect with radius of 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRRect(rr_clip, SkClipOp::kIntersect, true);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipRRect(rr_clip, ClipOp::kIntersect, true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipRRect Diff, with radius of 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRRect(rr_clip, SkClipOp::kDifference, false);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipRRect(rr_clip, ClipOp::kDifference, false);
                   })
                   .with_diff_clip());
    SkPath path_clip = SkPath();
    path_clip.setFillType(SkPathFillType::kEvenOdd);
    path_clip.addRect(r_clip);
    path_clip.addCircle(kRenderCenterX, kRenderCenterY, 1.0);
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipPath inset by 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipPath(path_clip, SkClipOp::kIntersect, false);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipPath(path_clip, ClipOp::kIntersect, false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipPath inset by 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipPath(path_clip, SkClipOp::kIntersect, true);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipPath(path_clip, ClipOp::kIntersect, true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipPath Diff, inset by 15.4",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipPath(path_clip, SkClipOp::kDifference, false);
                   },
                   [=](DlCanvas* c, DlPaint&) {
                     c->ClipPath(path_clip, ClipOp::kDifference, false);
                   })
                   .with_diff_clip());
  }

  static void RenderWith(const TestParameters& testP,
                         const RenderEnvironment& env,
                         const BoundsTolerance& tolerance_in,
                         const CaseParameters& caseP) {
    const std::string info = env.backend_name() + ": " + caseP.info();
    const DlColor bg = caseP.bg();
    RenderJobInfo base_info = {
        .bg = bg,
    };

    // sk_result is a direct rendering via SkCanvas to SkSurface
    // DisplayList mechanisms are not involved in this operation
    // SkPaint sk_paint;
    SkJobRenderer sk_job(caseP.sk_setup(),     //
                         testP.sk_renderer(),  //
                         caseP.sk_restore());
    auto sk_result = env.getResult(base_info, sk_job);

    DlJobRenderer dl_job(caseP.dl_setup(),     //
                         testP.dl_renderer(),  //
                         caseP.dl_restore());
    auto dl_result = env.getResult(base_info, dl_job);

    EXPECT_EQ(sk_job.setup_matrix(), dl_job.setup_matrix());
    EXPECT_EQ(sk_job.setup_clip_bounds(), dl_job.setup_clip_bounds());
    ASSERT_EQ(sk_result->width(), kTestWidth) << info;
    ASSERT_EQ(sk_result->height(), kTestHeight) << info;
    ASSERT_EQ(dl_result->width(), kTestWidth) << info;
    ASSERT_EQ(dl_result->height(), kTestHeight) << info;

    const BoundsTolerance tolerance =
        testP.adjust(tolerance_in, dl_job.setup_paint(), dl_job.setup_matrix());
    const sk_sp<SkPicture> sk_picture = sk_job.MakePicture(base_info);
    const sk_sp<DisplayList> display_list = dl_job.MakeDisplayList(base_info);

    SkRect sk_bounds = sk_picture->cullRect();
    checkPixels(sk_result.get(), sk_bounds, info + " (Skia reference)", bg);

    if (testP.should_match(env, caseP, dl_job.setup_paint(), dl_job)) {
      quickCompareToReference(env.ref_sk_result(), sk_result.get(), true,
                              info + " (attribute has no effect)");
    } else {
      quickCompareToReference(env.ref_sk_result(), sk_result.get(), false,
                              info + " (attribute affects rendering)");
    }

    quickCompareToReference(sk_result.get(), dl_result.get(), true,
                            info + " (DlCanvas output matches SkCanvas)");

    {
      SkRect dl_bounds = display_list->bounds();
      if (!sk_bounds.roundOut().contains(dl_bounds)) {
        FML_LOG(ERROR) << "For " << info;
        FML_LOG(ERROR) << "sk ref: "  //
                       << sk_bounds.fLeft << ", " << sk_bounds.fTop << " => "
                       << sk_bounds.fRight << ", " << sk_bounds.fBottom;
        FML_LOG(ERROR) << "dl: "  //
                       << dl_bounds.fLeft << ", " << dl_bounds.fTop << " => "
                       << dl_bounds.fRight << ", " << dl_bounds.fBottom;
        if (!dl_bounds.contains(sk_bounds)) {
          FML_LOG(ERROR) << "DisplayList bounds are too small!";
        }
        if (!sk_bounds.roundOut().contains(dl_bounds.roundOut())) {
          FML_LOG(ERROR) << "###### DisplayList bounds larger than reference!";
        }
      }

      // This EXPECT sometimes triggers, but when it triggers and I examine
      // the ref_bounds, they are always unnecessarily large and since the
      // pixel OOB tests in the compare method do not trigger, we will trust
      // the DL bounds.
      // EXPECT_TRUE(dl_bounds.contains(ref_bounds)) << info;

      // When we are drawing a DisplayList, the display_list built above
      // will contain just a single drawDisplayList call plus the case
      // attribute. The sk_picture will, however, contain a list of all
      // of the embedded calls in the display list and so the op counts
      // will not be equal between the two.
      if (!testP.is_draw_display_list()) {
        EXPECT_EQ(static_cast<int>(display_list->op_count()),
                  sk_picture->approximateOpCount())
            << info;
        EXPECT_EQ(static_cast<int>(display_list->op_count()),
                  sk_picture->approximateOpCount())
            << info;
      }

      DisplayListJobRenderer dl_builder_job(display_list);
      auto dl_builder_result = env.getResult(base_info, dl_builder_job);
      if (caseP.fuzzy_compare_components()) {
        compareToReference(
            dl_builder_result.get(), dl_result.get(),
            info + " (DlCanvas DL output close to Builder Dl output)",
            &dl_bounds, &tolerance, bg, true);
      } else {
        quickCompareToReference(
            dl_builder_result.get(), dl_result.get(), true,
            info + " (DlCanvas DL output matches Builder Dl output)");
      }

      compareToReference(dl_result.get(), sk_result.get(),
                         info + " (DisplayList built directly -> surface)",
                         &dl_bounds, &tolerance, bg,
                         caseP.fuzzy_compare_components());

      if (display_list->can_apply_group_opacity()) {
        checkGroupOpacity(env, display_list, dl_result.get(),
                          info + " with Group Opacity", bg);
      }
    }

    {
      // This sequence renders the SkCanvas calls to an SkPictureRecorder and
      // renders the DisplayList calls to a DisplayListBuilder and then
      // renders both back under a transform (scale(2x)) to see if their
      // rendering is affected differently by a change of matrix between
      // recording time and rendering time.
      const int test_width_2 = kTestWidth * 2;
      const int test_height_2 = kTestHeight * 2;
      const SkScalar test_scale = 2.0;

      SkPictureJobRenderer sk_job_x2(sk_picture);
      RenderJobInfo info_2x = {
          .width = test_width_2,
          .height = test_height_2,
          .bg = bg,
          .scale = test_scale,
      };
      auto ref_x2_result = env.getResult(info_2x, sk_job_x2);
      ASSERT_EQ(ref_x2_result->width(), test_width_2) << info;
      ASSERT_EQ(ref_x2_result->height(), test_height_2) << info;

      DisplayListJobRenderer dl_job_x2(display_list);
      auto test_x2_result = env.getResult(info_2x, dl_job_x2);
      compareToReference(test_x2_result.get(), ref_x2_result.get(),
                         info + " (Both rendered scaled 2x)", nullptr, nullptr,
                         bg, caseP.fuzzy_compare_components(),  //
                         test_width_2, test_height_2, false);
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
    if (env.format() == PixelFormat::k565_PixelFormat) {
      return 9;
    }
    if (env.provider()->backend_type() == BackendType::kOpenGL_Backend) {
      // OpenGL gets a little fuzzy at times. Still, "within 5" (aka +/-4)
      // for byte samples is not bad, though the other backends give +/-1
      return 5;
    }
    return 2;
  }
  static void checkGroupOpacity(const RenderEnvironment& env,
                                const sk_sp<DisplayList>& display_list,
                                const RenderResult* ref_result,
                                const std::string& info,
                                DlColor bg) {
    SkScalar opacity = 128.0 / 255.0;

    DisplayListJobRenderer opacity_job(display_list);
    RenderJobInfo opacity_info = {
        .bg = bg,
        .opacity = opacity,
    };
    auto group_opacity_result = env.getResult(opacity_info, opacity_job);

    ASSERT_EQ(group_opacity_result->width(), kTestWidth) << info;
    ASSERT_EQ(group_opacity_result->height(), kTestHeight) << info;

    ASSERT_EQ(ref_result->width(), kTestWidth) << info;
    ASSERT_EQ(ref_result->height(), kTestHeight) << info;

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
    for (int y = 0; y < kTestHeight; y++) {
      const uint32_t* ref_row = ref_result->addr32(0, y);
      const uint32_t* test_row = group_opacity_result->addr32(0, y);
      for (int x = 0; x < kTestWidth; x++) {
        uint32_t ref_pixel = ref_row[x];
        uint32_t test_pixel = test_row[x];
        if (ref_pixel != bg.argb || test_pixel != bg.argb) {
          pixels_touched++;
          for (int i = 0; i < 32; i += 8) {
            int ref_comp = (ref_pixel >> i) & 0xff;
            int bg_comp = (bg.argb >> i) & 0xff;
            SkScalar faded_comp = bg_comp + (ref_comp - bg_comp) * opacity;
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

  static void checkPixels(const RenderResult* ref_result,
                          const SkRect ref_bounds,
                          const std::string& info,
                          const DlColor bg) {
    uint32_t untouched = bg.premultipliedArgb();
    int pixels_touched = 0;
    int pixels_oob = 0;
    SkIRect i_bounds = ref_bounds.roundOut();
    for (int y = 0; y < kTestHeight; y++) {
      const uint32_t* ref_row = ref_result->addr32(0, y);
      for (int x = 0; x < kTestWidth; x++) {
        if (ref_row[x] != untouched) {
          pixels_touched++;
          if (!i_bounds.contains(x, y)) {
            pixels_oob++;
          }
        }
      }
    }
    ASSERT_EQ(pixels_oob, 0) << info;
    ASSERT_GT(pixels_touched, 0) << info;
  }

  static void quickCompareToReference(const RenderEnvironment& env,
                                      const std::string& info) {
    quickCompareToReference(env.ref_sk_result(), env.ref_dl_result(), true,
                            info + " reference rendering");
  }

  static void quickCompareToReference(const RenderResult* ref_result,
                                      const RenderResult* test_result,
                                      bool should_match,
                                      const std::string& info) {
    int w = test_result->width();
    int h = test_result->height();
    ASSERT_EQ(w, ref_result->width()) << info;
    ASSERT_EQ(h, ref_result->height()) << info;
    int pixels_different = 0;
    for (int y = 0; y < h; y++) {
      const uint32_t* ref_row = ref_result->addr32(0, y);
      const uint32_t* test_row = test_result->addr32(0, y);
      for (int x = 0; x < w; x++) {
        if (ref_row[x] != test_row[x]) {
          if (should_match) {
            FML_LOG(ERROR) << std::hex << ref_row[x] << " != " << test_row[x];
          }
          pixels_different++;
        }
      }
    }
    if (should_match) {
      ASSERT_EQ(pixels_different, 0) << info;
    } else {
      ASSERT_NE(pixels_different, 0) << info;
    }
  }

  static void compareToReference(const RenderResult* test_result,
                                 const RenderResult* ref_result,
                                 const std::string& info,
                                 SkRect* bounds,
                                 const BoundsTolerance* tolerance,
                                 const DlColor bg,
                                 bool fuzzyCompares = false,
                                 int width = kTestWidth,
                                 int height = kTestHeight,
                                 bool printMismatches = false) {
    uint32_t untouched = bg.premultipliedArgb();
    ASSERT_EQ(test_result->width(), width) << info;
    ASSERT_EQ(test_result->height(), height) << info;
    SkIRect i_bounds =
        bounds ? bounds->roundOut() : SkIRect::MakeWH(width, height);

    int pixels_different = 0;
    int pixels_oob = 0;
    int min_x = width;
    int min_y = height;
    int max_x = 0;
    int max_y = 0;
    for (int y = 0; y < height; y++) {
      const uint32_t* ref_row = ref_result->addr32(0, y);
      const uint32_t* test_row = test_result->addr32(0, y);
      for (int x = 0; x < width; x++) {
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
          if (!i_bounds.contains(x, y)) {
            pixels_oob++;
          }
        }
        bool match = fuzzyCompares ? fuzzyCompare(test_row[x], ref_row[x], 1)
                                   : test_row[x] == ref_row[x];
        if (!match) {
          if (printMismatches) {
            FML_LOG(ERROR) << "pix[" << x << ", " << y
                           << "] mismatch: " << std::hex << test_row[x]
                           << "(test) != (ref)" << ref_row[x] << std::dec;
          }
          pixels_different++;
        }
      }
    }
    if (pixels_oob > 0) {
      FML_LOG(ERROR) << "pix bounds["  //
                     << min_x << ", " << min_y << " => " << max_x << ", "
                     << max_y << "]";
      FML_LOG(ERROR) << "dl_bounds["                               //
                     << bounds->fLeft << ", " << bounds->fTop      //
                     << " => "                                     //
                     << bounds->fRight << ", " << bounds->fBottom  //
                     << "]";
    } else if (bounds) {
      showBoundsOverflow(info, i_bounds, tolerance, min_x, min_y, max_x, max_y);
    }
    ASSERT_EQ(pixels_oob, 0) << info;
    ASSERT_EQ(pixels_different, 0) << info;
  }

  static void showBoundsOverflow(const std::string& info,
                                 SkIRect& bounds,
                                 const BoundsTolerance* tolerance,
                                 int pixLeft,
                                 int pixTop,
                                 int pixRight,
                                 int pixBottom) {
    int pad_left = std::max(0, pixLeft - bounds.fLeft);
    int pad_top = std::max(0, pixTop - bounds.fTop);
    int pad_right = std::max(0, bounds.fRight - pixRight);
    int pad_bottom = std::max(0, bounds.fBottom - pixBottom);
    SkIRect pix_bounds =
        SkIRect::MakeLTRB(pixLeft, pixTop, pixRight, pixBottom);
    SkISize pix_size = pix_bounds.size();
    int pix_width = pix_size.width();
    int pix_height = pix_size.height();
    int worst_pad_x = std::max(pad_left, pad_right);
    int worst_pad_y = std::max(pad_top, pad_bottom);
    if (tolerance->overflows(pix_bounds, worst_pad_x, worst_pad_y)) {
      FML_LOG(ERROR) << "Computed bounds for " << info;
      FML_LOG(ERROR) << "pix bounds["                        //
                     << pixLeft << ", " << pixTop << " => "  //
                     << pixRight << ", " << pixBottom        //
                     << "]";
      FML_LOG(ERROR) << "dl_bounds["                             //
                     << bounds.fLeft << ", " << bounds.fTop      //
                     << " => "                                   //
                     << bounds.fRight << ", " << bounds.fBottom  //
                     << "]";
      FML_LOG(ERROR) << "Bounds overly conservative by up to "     //
                     << worst_pad_x << ", " << worst_pad_y         //
                     << " (" << (worst_pad_x * 100.0 / pix_width)  //
                     << "%, " << (worst_pad_y * 100.0 / pix_height) << "%)";
      int pix_area = pix_size.area();
      int dl_area = bounds.width() * bounds.height();
      FML_LOG(ERROR) << "Total overflow area: " << (dl_area - pix_area)  //
                     << " (+" << (dl_area * 100.0 / pix_area - 100.0)    //
                     << "% larger)";
      FML_LOG(ERROR);
    }
  }

  static const sk_sp<SkImage> kTestImage;
  static const sk_sp<SkImage> makeTestImage() {
    sk_sp<SkSurface> surface =
        SkSurface::MakeRasterN32Premul(kRenderWidth, kRenderHeight);
    SkCanvas* canvas = surface->getCanvas();
    SkPaint p0, p1;
    p0.setStyle(SkPaint::kFill_Style);
    p0.setColor(SkColorSetARGB(0xff, 0x00, 0xfe, 0x00));  // off-green
    p1.setStyle(SkPaint::kFill_Style);
    p1.setColor(SK_ColorBLUE);
    // Some pixels need some transparency for DstIn testing
    p1.setAlpha(128);
    int cbdim = 5;
    for (int y = 0; y < kRenderHeight; y += cbdim) {
      for (int x = 0; x < kRenderWidth; x += cbdim) {
        SkPaint& cellp = ((x + y) & 1) == 0 ? p0 : p1;
        canvas->drawRect(SkRect::MakeXYWH(x, y, cbdim, cbdim), cellp);
      }
    }
    return surface->makeImageSnapshot();
  }

  static const DlImageColorSource kTestImageColorSource;

  static sk_sp<SkTextBlob> MakeTextBlob(const std::string& string,
                                        SkScalar font_height) {
    SkFont font(SkTypeface::MakeFromName("ahem", SkFontStyle::Normal()),
                font_height);
    return SkTextBlob::MakeFromText(string.c_str(), string.size(), font,
                                    SkTextEncoding::kUTF8);
  }
};

std::vector<std::unique_ptr<DlSurfaceProvider>>
    CanvasCompareTester::kTestProviders;

BoundsTolerance CanvasCompareTester::DefaultTolerance =
    BoundsTolerance().addAbsolutePadding(1, 1);

const sk_sp<SkImage> CanvasCompareTester::kTestImage = makeTestImage();
const DlImageColorSource CanvasCompareTester::kTestImageColorSource(
    DlImage::Make(kTestImage),
    DlTileMode::kRepeat,
    DlTileMode::kRepeat,
    DlImageSampling::kLinear);

// Eventually this bare bones testing::Test fixture will subsume the
// CanvasCompareTester and the TestParameters could then become just
// configuration calls made upon the fixture.
template <typename BaseT>
class DisplayListCanvasTestBase : public BaseT, protected DisplayListOpFlags {
 public:
  DisplayListCanvasTestBase() = default;

  static bool StartsWith(std::string str, std::string prefix) {
    if (prefix.length() > str.length()) {
      return false;
    }
    for (size_t i = 0; i < prefix.length(); i++) {
      if (str[i] != prefix[i]) {
        return false;
      }
    }
    return true;
  }

  static void AddProvider(BackendType type, const std::string& name) {
    auto provider = DlSurfaceProvider::Create(type);
    if (provider == nullptr) {
      FML_LOG(ERROR) << "provider " << name << " not supported (ignoring)";
      return;
    }
    provider->InitializeSurface(kTestWidth, kTestHeight,
                                PixelFormat::kN32Premul_PixelFormat);
    CanvasCompareTester::kTestProviders.push_back(std::move(provider));
  }

  static void SetUpTestSuite() {
    bool do_software = true;
    bool do_opengl = false;
    bool do_metal = false;
    std::vector<std::string> args = ::testing::internal::GetArgvs();
    for (auto p_arg = std::next(args.begin()); p_arg != args.end(); p_arg++) {
      std::string arg = *p_arg;
      bool enable = true;
      if (StartsWith(arg, "--no")) {
        enable = false;
        arg = "-" + arg.substr(4);
      }
      if (arg == "--enable-software") {
        do_software = enable;
      } else if (arg == "--enable-opengl" || arg == "--enable-gl") {
        do_opengl = enable;
      } else if (arg == "--enable-metal") {
        do_metal = enable;
      }
    }
    if (do_software) {
      AddProvider(BackendType::kSoftware_Backend, "Software");
    }
    if (do_opengl) {
      AddProvider(BackendType::kOpenGL_Backend, "OpenGL");
    }
    if (do_metal) {
      AddProvider(BackendType::kMetal_Backend, "Metal");
    }
    std::string providers = "";
    auto begin = CanvasCompareTester::kTestProviders.cbegin();
    auto end = CanvasCompareTester::kTestProviders.cend();
    while (begin != end) {
      providers += " " + (*begin++)->backend_name();
    }
    FML_LOG(INFO) << "Running tests on [" << providers << " ]";
  }

  static void TearDownTestSuite() {
    // Deleting these provider objects allows Metal to clean up its
    // resources before the exit handler reports them as leaks.
    CanvasCompareTester::kTestProviders.clear();
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DisplayListCanvasTestBase);
};
using DisplayListCanvas = DisplayListCanvasTestBase<::testing::Test>;

TEST_F(DisplayListCanvas, DrawPaint) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawPaint(paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawPaint(paint);
          },
          kDrawPaintFlags));
}

TEST_F(DisplayListCanvas, DrawOpaqueColor) {
  // We use a non-opaque color to avoid obliterating any backdrop filter output
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            // DrawColor is not tested against attributes because it is supposed
            // to ignore them. So, if the paint has an alpha, it is because we
            // are doing a saveLayer+backdrop test and we need to not flood over
            // the backdrop output with a solid color. So, we perform an alpha
            // drawColor for that case only.
            SkColor color = SkColorSetA(SK_ColorMAGENTA, paint.getAlpha());
            canvas->drawColor(color);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            // DrawColor is not tested against attributes because it is supposed
            // to ignore them. So, if the paint has an alpha, it is because we
            // are doing a saveLayer+backdrop test and we need to not flood over
            // the backdrop output with a solid color. So, we transfer the alpha
            // from the paint for that case only.
            canvas->DrawColor(DlColor::kMagenta().withAlpha(paint.getAlpha()));
          },
          kDrawColorFlags));
}

TEST_F(DisplayListCanvas, DrawAlphaColor) {
  // We use a non-opaque color to avoid obliterating any backdrop filter output
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawColor(0x7FFF00FF);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawColor(DlColor::kMagenta().withAlpha(0x7f));
          },
          kDrawColorFlags));
}

TEST_F(DisplayListCanvas, DrawDiagonalLines) {
  SkPoint p1 = SkPoint::Make(kRenderLeft, kRenderTop);
  SkPoint p2 = SkPoint::Make(kRenderRight, kRenderBottom);
  SkPoint p3 = SkPoint::Make(kRenderLeft, kRenderBottom);
  SkPoint p4 = SkPoint::Make(kRenderRight, kRenderTop);
  // Adding some edge center to edge center diagonals to better fill
  // out the RRect Clip so bounds checking sees less empty bounds space.
  SkPoint p5 = SkPoint::Make(kRenderCenterX, kRenderTop);
  SkPoint p6 = SkPoint::Make(kRenderRight, kRenderCenterY);
  SkPoint p7 = SkPoint::Make(kRenderLeft, kRenderCenterY);
  SkPoint p8 = SkPoint::Make(kRenderCenterX, kRenderBottom);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            // Skia requires kStroke style on horizontal and vertical
            // lines to get the bounds correct.
            // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
            SkPaint p = paint;
            p.setStyle(SkPaint::kStroke_Style);
            canvas->drawLine(p1, p2, p);
            canvas->drawLine(p3, p4, p);
            canvas->drawLine(p5, p6, p);
            canvas->drawLine(p7, p8, p);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawLine(p1, p2, paint);
            canvas->DrawLine(p3, p4, paint);
            canvas->DrawLine(p5, p6, paint);
            canvas->DrawLine(p7, p8, paint);
          },
          kDrawLineFlags)
          .set_draw_line());
}

TEST_F(DisplayListCanvas, DrawHorizontalLine) {
  SkPoint p1 = SkPoint::Make(kRenderLeft, kRenderCenterY);
  SkPoint p2 = SkPoint::Make(kRenderRight, kRenderCenterY);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            // Skia requires kStroke style on horizontal and vertical
            // lines to get the bounds correct.
            // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
            SkPaint p = paint;
            p.setStyle(SkPaint::kStroke_Style);
            canvas->drawLine(p1, p2, p);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawLine(p1, p2, paint);
          },
          kDrawHVLineFlags)
          .set_draw_line()
          .set_horizontal_line());
}

TEST_F(DisplayListCanvas, DrawVerticalLine) {
  SkPoint p1 = SkPoint::Make(kRenderCenterX, kRenderTop);
  SkPoint p2 = SkPoint::Make(kRenderCenterY, kRenderBottom);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            // Skia requires kStroke style on horizontal and vertical
            // lines to get the bounds correct.
            // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
            SkPaint p = paint;
            p.setStyle(SkPaint::kStroke_Style);
            canvas->drawLine(p1, p2, p);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawLine(p1, p2, paint);
          },
          kDrawHVLineFlags)
          .set_draw_line()
          .set_vertical_line());
}

TEST_F(DisplayListCanvas, DrawRect) {
  // Bounds are offset by 0.5 pixels to induce AA
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawRect(kRenderBounds.makeOffset(0.5, 0.5), paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawRect(kRenderBounds.makeOffset(0.5, 0.5), paint);
          },
          kDrawRectFlags));
}

TEST_F(DisplayListCanvas, DrawOval) {
  SkRect rect = kRenderBounds.makeInset(0, 10);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawOval(rect, paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawOval(rect, paint);
          },
          kDrawOvalFlags));
}

TEST_F(DisplayListCanvas, DrawCircle) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawCircle(kTestCenter, kRenderRadius, paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawCircle(kTestCenter, kRenderRadius, paint);
          },
          kDrawCircleFlags));
}

TEST_F(DisplayListCanvas, DrawRRect) {
  SkRRect rrect = SkRRect::MakeRectXY(kRenderBounds, kRenderCornerRadius,
                                      kRenderCornerRadius);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawRRect(rrect, paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawRRect(rrect, paint);
          },
          kDrawRRectFlags));
}

TEST_F(DisplayListCanvas, DrawDRRect) {
  SkRRect outer = SkRRect::MakeRectXY(kRenderBounds, kRenderCornerRadius,
                                      kRenderCornerRadius);
  SkRect inner_bounds = kRenderBounds.makeInset(30.0, 30.0);
  SkRRect inner = SkRRect::MakeRectXY(inner_bounds, kRenderCornerRadius,
                                      kRenderCornerRadius);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawDRRect(outer, inner, paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawDRRect(outer, inner, paint);
          },
          kDrawDRRectFlags));
}

TEST_F(DisplayListCanvas, DrawPath) {
  SkPath path;

  // unclosed lines to show some caps
  path.moveTo(kRenderLeft + 15, kRenderTop + 15);
  path.lineTo(kRenderRight - 15, kRenderBottom - 15);
  path.moveTo(kRenderLeft + 15, kRenderBottom - 15);
  path.lineTo(kRenderRight - 15, kRenderTop + 15);

  path.addRect(kRenderBounds);

  // miter diamonds horizontally and vertically to show miters
  path.moveTo(kVerticalMiterDiamondPoints[0]);
  for (int i = 1; i < kVerticalMiterDiamondPointCount; i++) {
    path.lineTo(kVerticalMiterDiamondPoints[i]);
  }
  path.close();
  path.moveTo(kHorizontalMiterDiamondPoints[0]);
  for (int i = 1; i < kHorizontalMiterDiamondPointCount; i++) {
    path.lineTo(kHorizontalMiterDiamondPoints[i]);
  }
  path.close();

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawPath(path, paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawPath(path, paint);
          },
          kDrawPathFlags)
          .set_draw_path());
}

TEST_F(DisplayListCanvas, DrawArc) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawArc(kRenderBounds, 60, 330, false, paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawArc(kRenderBounds, 60, 330, false, paint);
          },
          kDrawArcNoCenterFlags));
}

TEST_F(DisplayListCanvas, DrawArcCenter) {
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
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawArc(kRenderBounds, 60, 360 - 12, true, paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawArc(kRenderBounds, 60, 360 - 12, true, paint);
          },
          kDrawArcWithCenterFlags)
          .set_draw_arc_center());
}

TEST_F(DisplayListCanvas, DrawPointsAsPoints) {
  // The +/- 16 points are designed to fall just inside the clips
  // that are tested against so we avoid lots of undrawn pixels
  // in the accumulated bounds.
  const SkScalar x0 = kRenderLeft;
  const SkScalar x1 = kRenderLeft + 16;
  const SkScalar x2 = (kRenderLeft + kRenderCenterX) * 0.5;
  const SkScalar x3 = kRenderCenterX + 0.1;
  const SkScalar x4 = (kRenderRight + kRenderCenterX) * 0.5;
  const SkScalar x5 = kRenderRight - 16;
  const SkScalar x6 = kRenderRight;

  const SkScalar y0 = kRenderTop;
  const SkScalar y1 = kRenderTop + 16;
  const SkScalar y2 = (kRenderTop + kRenderCenterY) * 0.5;
  const SkScalar y3 = kRenderCenterY + 0.1;
  const SkScalar y4 = (kRenderBottom + kRenderCenterY) * 0.5;
  const SkScalar y5 = kRenderBottom - 16;
  const SkScalar y6 = kRenderBottom;

  // clang-format off
  const SkPoint points[] = {
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

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            // Skia requires kStroke style on horizontal and vertical
            // lines to get the bounds correct.
            // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
            SkPaint p = paint;
            p.setStyle(SkPaint::kStroke_Style);
            canvas->drawPoints(SkCanvas::kPoints_PointMode, count, points, p);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawPoints(PointMode::kPoints, count, points, paint);
          },
          kDrawPointsAsPointsFlags)
          .set_draw_line()
          .set_ignores_dashes());
}

TEST_F(DisplayListCanvas, DrawPointsAsLines) {
  const SkScalar x0 = kRenderLeft + 1;
  const SkScalar x1 = kRenderLeft + 16;
  const SkScalar x2 = kRenderRight - 16;
  const SkScalar x3 = kRenderRight - 1;

  const SkScalar y0 = kRenderTop;
  const SkScalar y1 = kRenderTop + 16;
  const SkScalar y2 = kRenderBottom - 16;
  const SkScalar y3 = kRenderBottom;

  // clang-format off
  const SkPoint points[] = {
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
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            // Skia requires kStroke style on horizontal and vertical
            // lines to get the bounds correct.
            // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
            SkPaint p = paint;
            p.setStyle(SkPaint::kStroke_Style);
            canvas->drawPoints(SkCanvas::kLines_PointMode, count, points, p);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawPoints(PointMode::kLines, count, points, paint);
          },
          kDrawPointsAsLinesFlags));
}

TEST_F(DisplayListCanvas, DrawPointsAsPolygon) {
  const SkPoint points1[] = {
      // RenderBounds box with a diamond
      SkPoint::Make(kRenderLeft, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderBottom),
      SkPoint::Make(kRenderLeft, kRenderBottom),
      SkPoint::Make(kRenderLeft, kRenderTop),
      SkPoint::Make(kRenderCenterX, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderCenterY),
      SkPoint::Make(kRenderCenterX, kRenderBottom),
      SkPoint::Make(kRenderLeft, kRenderCenterY),
  };
  const int count1 = sizeof(points1) / sizeof(points1[0]);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            // Skia requires kStroke style on horizontal and vertical
            // lines to get the bounds correct.
            // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
            SkPaint p = paint;
            p.setStyle(SkPaint::kStroke_Style);
            canvas->drawPoints(SkCanvas::kPolygon_PointMode, count1, points1,
                               p);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawPoints(PointMode::kPolygon, count1, points1, paint);
          },
          kDrawPointsAsPolygonFlags));
}

TEST_F(DisplayListCanvas, DrawVerticesWithColors) {
  // Cover as many sides of the box with only 6 vertices:
  // +----------+
  // |xxxxxxxxxx|
  // |    xxxxxx|
  // |       xxx|
  // |xxx       |
  // |xxxxxx    |
  // |xxxxxxxxxx|
  // +----------|
  const SkPoint pts[6] = {
      // Upper-Right corner, full top, half right coverage
      SkPoint::Make(kRenderLeft, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderCenterY),
      // Lower-Left corner, full bottom, half left coverage
      SkPoint::Make(kRenderLeft, kRenderBottom),
      SkPoint::Make(kRenderLeft, kRenderCenterY),
      SkPoint::Make(kRenderRight, kRenderBottom),
  };
  const DlColor colors[6] = {
      SK_ColorRED,  SK_ColorBLUE,   SK_ColorGREEN,
      SK_ColorCYAN, SK_ColorYELLOW, SK_ColorMAGENTA,
  };
  const std::shared_ptr<DlVertices> vertices =
      DlVertices::Make(DlVertexMode::kTriangles, 6, pts, nullptr, colors);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawVertices(vertices->skia_object(), SkBlendMode::kSrcOver,
                                 paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawVertices(vertices, DlBlendMode::kSrcOver, paint);
          },
          kDrawVerticesFlags));
}

TEST_F(DisplayListCanvas, DrawVerticesWithImage) {
  // Cover as many sides of the box with only 6 vertices:
  // +----------+
  // |xxxxxxxxxx|
  // |    xxxxxx|
  // |       xxx|
  // |xxx       |
  // |xxxxxx    |
  // |xxxxxxxxxx|
  // +----------|
  const SkPoint pts[6] = {
      // Upper-Right corner, full top, half right coverage
      SkPoint::Make(kRenderLeft, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderCenterY),
      // Lower-Left corner, full bottom, half left coverage
      SkPoint::Make(kRenderLeft, kRenderBottom),
      SkPoint::Make(kRenderLeft, kRenderCenterY),
      SkPoint::Make(kRenderRight, kRenderBottom),
  };
  const SkPoint tex[6] = {
      SkPoint::Make(kRenderWidth / 2.0, 0),
      SkPoint::Make(0, kRenderHeight),
      SkPoint::Make(kRenderWidth, kRenderHeight),
      SkPoint::Make(kRenderWidth / 2, kRenderHeight),
      SkPoint::Make(0, 0),
      SkPoint::Make(kRenderWidth, 0),
  };
  const std::shared_ptr<DlVertices> vertices =
      DlVertices::Make(DlVertexMode::kTriangles, 6, pts, tex, nullptr);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            SkPaint v_paint = paint;
            if (v_paint.getShader() == nullptr) {
              v_paint.setShader(
                  CanvasCompareTester::kTestImageColorSource.skia_object());
            }
            canvas->drawVertices(vertices->skia_object(), SkBlendMode::kSrcOver,
                                 v_paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            DlPaint v_paint = paint;
            if (v_paint.getColorSource() == nullptr) {
              v_paint.setColorSource(
                  &CanvasCompareTester::kTestImageColorSource);
            }
            canvas->DrawVertices(vertices, DlBlendMode::kSrcOver, v_paint);
          },
          kDrawVerticesFlags));
}

TEST_F(DisplayListCanvas, DrawImageNearest) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {         //
            canvas->drawImage(CanvasCompareTester::kTestImage,  //
                              kRenderLeft, kRenderTop,
                              ToSk(DlImageSampling::kNearestNeighbor), &paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawImage(DlImage::Make(CanvasCompareTester::kTestImage),
                              SkPoint::Make(kRenderLeft, kRenderTop),
                              DlImageSampling::kNearestNeighbor, &paint);
          },
          kDrawImageWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageNearestNoPaint) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {         //
            canvas->drawImage(CanvasCompareTester::kTestImage,  //
                              kRenderLeft, kRenderTop,
                              ToSk(DlImageSampling::kNearestNeighbor), nullptr);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawImage(DlImage::Make(CanvasCompareTester::kTestImage),
                              SkPoint::Make(kRenderLeft, kRenderTop),
                              DlImageSampling::kNearestNeighbor, nullptr);
          },
          kDrawImageFlags));
}

TEST_F(DisplayListCanvas, DrawImageLinear) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {         //
            canvas->drawImage(CanvasCompareTester::kTestImage,  //
                              kRenderLeft, kRenderTop,
                              ToSk(DlImageSampling::kLinear), &paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawImage(DlImage::Make(CanvasCompareTester::kTestImage),
                              SkPoint::Make(kRenderLeft, kRenderTop),
                              DlImageSampling::kLinear, &paint);
          },
          kDrawImageWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageRectNearest) {
  SkRect src = SkRect::MakeIWH(kRenderWidth, kRenderHeight).makeInset(5, 5);
  SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawImageRect(CanvasCompareTester::kTestImage, src, dst,
                                  ToSk(DlImageSampling::kNearestNeighbor),
                                  &paint, SkCanvas::kFast_SrcRectConstraint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawImageRect(
                DlImage::Make(CanvasCompareTester::kTestImage), src, dst,
                DlImageSampling::kNearestNeighbor, &paint, false);
          },
          kDrawImageRectWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageRectNearestNoPaint) {
  SkRect src = SkRect::MakeIWH(kRenderWidth, kRenderHeight).makeInset(5, 5);
  SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawImageRect(CanvasCompareTester::kTestImage, src, dst,
                                  ToSk(DlImageSampling::kNearestNeighbor),
                                  nullptr, SkCanvas::kFast_SrcRectConstraint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawImageRect(
                DlImage::Make(CanvasCompareTester::kTestImage), src, dst,
                DlImageSampling::kNearestNeighbor, nullptr, false);
          },
          kDrawImageRectFlags));
}

TEST_F(DisplayListCanvas, DrawImageRectLinear) {
  SkRect src = SkRect::MakeIWH(kRenderWidth, kRenderHeight).makeInset(5, 5);
  SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawImageRect(CanvasCompareTester::kTestImage, src, dst,
                                  ToSk(DlImageSampling::kLinear), &paint,
                                  SkCanvas::kFast_SrcRectConstraint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawImageRect(
                DlImage::Make(CanvasCompareTester::kTestImage), src, dst,
                DlImageSampling::kLinear, &paint, false);
          },
          kDrawImageRectWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageNineNearest) {
  SkIRect src = SkIRect::MakeWH(kRenderWidth, kRenderHeight).makeInset(25, 25);
  SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageNine(image.get(), src, dst, SkFilterMode::kNearest,
                                  &paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawImageNine(DlImage::Make(image), src, dst,
                                  DlFilterMode::kNearest, &paint);
          },
          kDrawImageNineWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageNineNearestNoPaint) {
  SkIRect src = SkIRect::MakeWH(kRenderWidth, kRenderHeight).makeInset(25, 25);
  SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageNine(image.get(), src, dst, SkFilterMode::kNearest,
                                  nullptr);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawImageNine(DlImage::Make(image), src, dst,
                                  DlFilterMode::kNearest, nullptr);
          },
          kDrawImageNineFlags));
}

TEST_F(DisplayListCanvas, DrawImageNineLinear) {
  SkIRect src = SkIRect::MakeWH(kRenderWidth, kRenderHeight).makeInset(25, 25);
  SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageNine(image.get(), src, dst, SkFilterMode::kLinear,
                                  &paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawImageNine(DlImage::Make(image), src, dst,
                                  DlFilterMode::kLinear, &paint);
          },
          kDrawImageNineWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawAtlasNearest) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, kRenderLeft,  kRenderTop},
      { 0.0f,  1.2f, kRenderRight, kRenderTop},
      {-1.2f,  0.0f, kRenderRight, kRenderBottom},
      { 0.0f, -1.2f, kRenderLeft,  kRenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,                0,                 kRenderHalfWidth, kRenderHalfHeight},
      {kRenderHalfWidth, 0,                 kRenderWidth,     kRenderHalfHeight},
      {kRenderHalfWidth, kRenderHalfHeight, kRenderWidth,     kRenderHeight},
      {0,                kRenderHalfHeight, kRenderHalfWidth, kRenderHeight},
      // clang-format on
  };
  const SkColor sk_colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const DlColor dl_colors[] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::kYellow(),
      DlColor::kMagenta(),
  };
  const sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  const DlImageSampling sampling = DlImageSampling::kNearestNeighbor;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawAtlas(image.get(), xform, tex, sk_colors, 4,
                              SkBlendMode::kSrcOver, ToSk(sampling), nullptr,
                              &paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawAtlas(DlImage::Make(image), xform, tex, dl_colors, 4,
                              DlBlendMode::kSrcOver, sampling, nullptr, &paint);
          },
          kDrawAtlasWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawAtlasNearestNoPaint) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, kRenderLeft,  kRenderTop},
      { 0.0f,  1.2f, kRenderRight, kRenderTop},
      {-1.2f,  0.0f, kRenderRight, kRenderBottom},
      { 0.0f, -1.2f, kRenderLeft,  kRenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,                0,                 kRenderHalfWidth, kRenderHalfHeight},
      {kRenderHalfWidth, 0,                 kRenderWidth,     kRenderHalfHeight},
      {kRenderHalfWidth, kRenderHalfHeight, kRenderWidth,     kRenderHeight},
      {0,                kRenderHalfHeight, kRenderHalfWidth, kRenderHeight},
      // clang-format on
  };
  const SkColor sk_colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const DlColor dl_colors[] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::kYellow(),
      DlColor::kMagenta(),
  };
  const sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  const DlImageSampling sampling = DlImageSampling::kNearestNeighbor;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawAtlas(image.get(), xform, tex, sk_colors, 4,
                              SkBlendMode::kSrcOver, ToSk(sampling),  //
                              nullptr, nullptr);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawAtlas(DlImage::Make(image), xform, tex, dl_colors, 4,
                              DlBlendMode::kSrcOver, sampling, nullptr,
                              nullptr);
          },
          kDrawAtlasFlags));
}

TEST_F(DisplayListCanvas, DrawAtlasLinear) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, kRenderLeft,  kRenderTop},
      { 0.0f,  1.2f, kRenderRight, kRenderTop},
      {-1.2f,  0.0f, kRenderRight, kRenderBottom},
      { 0.0f, -1.2f, kRenderLeft,  kRenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,                0,                 kRenderHalfWidth, kRenderHalfHeight},
      {kRenderHalfWidth, 0,                 kRenderWidth,     kRenderHalfHeight},
      {kRenderHalfWidth, kRenderHalfHeight, kRenderWidth,     kRenderHeight},
      {0,                kRenderHalfHeight, kRenderHalfWidth, kRenderHeight},
      // clang-format on
  };
  const SkColor sk_colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const DlColor dl_colors[] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::kYellow(),
      DlColor::kMagenta(),
  };
  const sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  const DlImageSampling sampling = DlImageSampling::kLinear;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawAtlas(image.get(), xform, tex, sk_colors, 2,  //
                              SkBlendMode::kSrcOver, ToSk(sampling), nullptr,
                              &paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {
            canvas->DrawAtlas(DlImage::Make(image), xform, tex, dl_colors, 2,
                              DlBlendMode::kSrcOver, sampling, nullptr, &paint);
          },
          kDrawAtlasWithPaintFlags));
}

sk_sp<DisplayList> makeTestDisplayList() {
  DisplayListBuilder builder;
  builder.setStyle(DlDrawStyle::kFill);
  builder.setColor(SK_ColorRED);
  builder.drawRect({kRenderLeft, kRenderTop, kRenderCenterX, kRenderCenterY});
  builder.setColor(SK_ColorBLUE);
  builder.drawRect({kRenderCenterX, kRenderTop, kRenderRight, kRenderCenterY});
  builder.setColor(SK_ColorGREEN);
  builder.drawRect(
      {kRenderLeft, kRenderCenterY, kRenderCenterX, kRenderBottom});
  builder.setColor(SK_ColorYELLOW);
  builder.drawRect(
      {kRenderCenterX, kRenderCenterY, kRenderRight, kRenderBottom});
  return builder.Build();
}

TEST_F(DisplayListCanvas, DrawDisplayList) {
  sk_sp<DisplayList> display_list = makeTestDisplayList();
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            display_list->RenderTo(canvas);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawDisplayList(display_list);
          },
          kDrawDisplayListFlags)
          .set_draw_display_list());
}

TEST_F(DisplayListCanvas, DrawTextBlob) {
  // TODO(https://github.com/flutter/flutter/issues/82202): Remove once the
  // performance overlay can use Fuchsia's font manager instead of the empty
  // default.
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Rendering comparisons require a valid default font manager";
#endif  // OS_FUCHSIA
  sk_sp<SkTextBlob> blob =
      CanvasCompareTester::MakeTextBlob("Testing", kRenderHeight * 0.33f);
  SkScalar render_y_1_3 = kRenderTop + kRenderHeight * 0.3;
  SkScalar render_y_2_3 = kRenderTop + kRenderHeight * 0.6;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawTextBlob(blob, kRenderLeft, render_y_1_3, paint);
            canvas->drawTextBlob(blob, kRenderLeft, render_y_2_3, paint);
            canvas->drawTextBlob(blob, kRenderLeft, kRenderBottom, paint);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawTextBlob(blob, kRenderLeft, render_y_1_3, paint);
            canvas->DrawTextBlob(blob, kRenderLeft, render_y_2_3, paint);
            canvas->DrawTextBlob(blob, kRenderLeft, kRenderBottom, paint);
          },
          kDrawTextBlobFlags)
          .set_draw_text_blob(),
      // From examining the bounds differential for the "Default" case, the
      // SkTextBlob adds a padding of ~32 on the left, ~30 on the right,
      // ~12 on top and ~8 on the bottom, so we add 33h & 13v allowed
      // padding to the tolerance
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(33, 13));
  EXPECT_TRUE(blob->unique());
}

TEST_F(DisplayListCanvas, DrawShadow) {
  SkPath path;
  path.addRoundRect(
      {
          kRenderLeft + 10,
          kRenderTop,
          kRenderRight - 10,
          kRenderBottom - 20,
      },
      kRenderCornerRadius, kRenderCornerRadius);
  const DlColor color = DlColor::kDarkGrey();
  const SkScalar elevation = 5;

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            DisplayListCanvasDispatcher::DrawShadow(canvas, path, color,
                                                    elevation, false, 1.0);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawShadow(path, color, elevation, false, 1.0);
          },
          kDrawShadowFlags),
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

TEST_F(DisplayListCanvas, DrawShadowTransparentOccluder) {
  SkPath path;
  path.addRoundRect(
      {
          kRenderLeft + 10,
          kRenderTop,
          kRenderRight - 10,
          kRenderBottom - 20,
      },
      kRenderCornerRadius, kRenderCornerRadius);
  const DlColor color = DlColor::kDarkGrey();
  const SkScalar elevation = 5;

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            DisplayListCanvasDispatcher::DrawShadow(canvas, path, color,
                                                    elevation, true, 1.0);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawShadow(path, color, elevation, true, 1.0);
          },
          kDrawShadowFlags),
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

TEST_F(DisplayListCanvas, DrawShadowDpr) {
  SkPath path;
  path.addRoundRect(
      {
          kRenderLeft + 10,
          kRenderTop,
          kRenderRight - 10,
          kRenderBottom - 20,
      },
      kRenderCornerRadius, kRenderCornerRadius);
  const DlColor color = DlColor::kDarkGrey();
  const SkScalar elevation = 5;

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            DisplayListCanvasDispatcher::DrawShadow(canvas, path, color,
                                                    elevation, false, 1.5);
          },
          [=](DlCanvas* canvas, const DlPaint& paint) {  //
            canvas->DrawShadow(path, color, elevation, false, 1.5);
          },
          kDrawShadowFlags),
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

TEST_F(DisplayListCanvas, SaveLayerConsolidation) {
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
  SkMatrix contract_matrix;
  contract_matrix.setScale(0.9f, 0.9f, kRenderCenterX, kRenderCenterY);

  std::vector<SkScalar> opacities = {
      0,
      0.5f,
      SK_Scalar1,
  };
  std::vector<std::shared_ptr<DlColorFilter>> color_filters = {
      std::make_shared<DlBlendColorFilter>(DlColor::kCyan(),
                                           DlBlendMode::kSrcATop),
      std::make_shared<DlMatrixColorFilter>(commutable_color_matrix),
      std::make_shared<DlMatrixColorFilter>(non_commutable_color_matrix),
      DlSrgbToLinearGammaColorFilter::instance,
      DlLinearToSrgbGammaColorFilter::instance,
  };
  std::vector<std::shared_ptr<DlImageFilter>> image_filters = {
      std::make_shared<DlBlurImageFilter>(5.0f, 5.0f, DlTileMode::kDecal),
      std::make_shared<DlDilateImageFilter>(5.0f, 5.0f),
      std::make_shared<DlErodeImageFilter>(5.0f, 5.0f),
      std::make_shared<DlMatrixImageFilter>(contract_matrix,
                                            DlImageSampling::kLinear),
  };
  std::vector<std::unique_ptr<RenderEnvironment>> environments;
  for (auto& provider : CanvasCompareTester::kTestProviders) {
    auto env = std::make_unique<RenderEnvironment>(
        provider.get(), PixelFormat::kN32Premul_PixelFormat);
    environments.push_back(std::move(env));
  }

  auto render_content = [](DisplayListBuilder& builder) {
    builder.DrawRect(
        SkRect{kRenderLeft, kRenderTop, kRenderCenterX, kRenderCenterY},
        DlPaint(DlColor::kYellow()));
    builder.DrawRect(
        SkRect{kRenderCenterX, kRenderTop, kRenderRight, kRenderCenterY},
        DlPaint(DlColor::kRed()));
    builder.DrawRect(
        SkRect{kRenderLeft, kRenderCenterY, kRenderCenterX, kRenderBottom},
        DlPaint(DlColor::kBlue()));
    builder.DrawRect(
        SkRect{kRenderCenterX, kRenderCenterY, kRenderRight, kRenderBottom},
        DlPaint(DlColor::kRed().modulateOpacity(0.5f)));
  };

  auto test_attributes_env =
      [render_content](DlPaint& paint1, DlPaint& paint2,
                       const DlPaint& paint_both, bool same, bool rev_same,
                       const std::string& desc1, const std::string& desc2,
                       const RenderEnvironment* env) {
        DisplayListBuilder nested_builder;
        nested_builder.SaveLayer(&kTestBounds, &paint1);
        nested_builder.SaveLayer(&kTestBounds, &paint2);
        render_content(nested_builder);
        auto nested_results = env->getResult(nested_builder.Build());

        DisplayListBuilder reverse_builder;
        reverse_builder.SaveLayer(&kTestBounds, &paint2);
        reverse_builder.SaveLayer(&kTestBounds, &paint1);
        render_content(reverse_builder);
        auto reverse_results = env->getResult(reverse_builder.Build());

        DisplayListBuilder combined_builder;
        combined_builder.SaveLayer(&kTestBounds, &paint_both);
        render_content(combined_builder);
        auto combined_results = env->getResult(combined_builder.Build());

        // Set this boolean to true to test if combinations that are marked
        // as incompatible actually are compatible despite our predictions.
        // Some of the combinations that we treat as incompatible actually
        // are compatible with swapping the order of the operations, but
        // it would take a bit of new infrastructure to really identify
        // those combinations. The only hard constraint to test here is
        // when we claim that they are compatible and they aren't.
        const bool always = false;

        if (always || same) {
          CanvasCompareTester::quickCompareToReference(
              nested_results.get(), combined_results.get(), same,
              "nested " + desc1 + " then " + desc2);
        }
        if (always || rev_same) {
          CanvasCompareTester::quickCompareToReference(
              reverse_results.get(), combined_results.get(), rev_same,
              "nested " + desc2 + " then " + desc1);
        }
      };

  auto test_attributes = [test_attributes_env, &environments](
                             DlPaint& paint1, DlPaint& paint2,
                             const DlPaint& paint_both, bool same,
                             bool rev_same, const std::string& desc1,
                             const std::string& desc2) {
    for (auto& env : environments) {
      test_attributes_env(paint1, paint2, paint_both,  //
                          same, rev_same, desc1, desc2, env.get());
    }
  };

  // CF then Opacity should always work.
  // The reverse sometimes works.
  for (size_t cfi = 0; cfi < color_filters.size(); cfi++) {
    auto color_filter = color_filters[cfi];
    std::string cf_desc = "color filter #" + std::to_string(cfi + 1);
    DlPaint nested_paint1 = DlPaint().setColorFilter(color_filter);

    for (size_t oi = 0; oi < opacities.size(); oi++) {
      SkScalar opacity = opacities[oi];
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
    SkScalar opacity = opacities[oi];
    std::string op_desc = "opacity " + std::to_string(opacity);
    DlPaint nested_paint1 = DlPaint().setOpacity(opacity);

    for (size_t ifi = 0; ifi < image_filters.size(); ifi++) {
      auto image_filter = image_filters[ifi];
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
    auto color_filter = color_filters[cfi];
    std::string cf_desc = "color filter #" + std::to_string(cfi + 1);
    DlPaint nested_paint1 = DlPaint().setColorFilter(color_filter);

    for (size_t ifi = 0; ifi < image_filters.size(); ifi++) {
      auto image_filter = image_filters[ifi];
      std::string if_desc = "image filter #" + std::to_string(ifi + 1);
      DlPaint nested_paint2 = DlPaint().setImageFilter(image_filter);

      DlPaint combined_paint = nested_paint1;
      combined_paint.setImageFilter(image_filter);

      test_attributes(nested_paint1, nested_paint2, combined_paint, true, false,
                      cf_desc, if_desc);
    }
  }
}

}  // namespace testing
}  // namespace flutter

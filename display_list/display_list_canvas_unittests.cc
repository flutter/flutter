// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/display_list/display_list_canvas_recorder.h"
#include "flutter/display_list/display_list_comparable.h"
#include "flutter/display_list/display_list_flags.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/fml/math.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/effects/SkBlenders.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkDiscretePathEffect.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

namespace flutter {
namespace testing {

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
    SkIRect rounded = allowed.roundOut();
    int padLeft = std::max(0, pix_bounds.fLeft - rounded.fLeft);
    int padTop = std::max(0, pix_bounds.fTop - rounded.fTop);
    int padRight = std::max(0, pix_bounds.fRight - rounded.fRight);
    int padBottom = std::max(0, pix_bounds.fBottom - rounded.fBottom);
    int allowed_pad_x = std::max(padLeft, padRight);
    int allowed_pad_y = std::max(padTop, padBottom);
    if (worst_bounds_pad_x > allowed_pad_x ||
        worst_bounds_pad_y > allowed_pad_y) {
      FML_LOG(ERROR) << "allowed pad: "  //
                     << allowed_pad_x << ", " << allowed_pad_y;
    }
    return (worst_bounds_pad_x > allowed_pad_x ||
            worst_bounds_pad_y > allowed_pad_y);
  }

  SkScalar discrete_offset() const { return discrete_offset_; }

 private:
  SkPoint bounds_pad_ = {0, 0};
  SkPoint scale_ = {1, 1};
  SkPoint absolute_pad_ = {0, 0};
  SkRect clip_ = {-1E9, -1E9, 1E9, 1E9};

  SkScalar discrete_offset_ = 0;
};

typedef const std::function<void(SkCanvas*, SkPaint&)> CvSetup;
typedef const std::function<void(SkCanvas*, const SkPaint&)> CvRenderer;
typedef const std::function<void(DisplayListBuilder&)> DlRenderer;
static void EmptyCvRenderer(SkCanvas*, const SkPaint&) {}
static void EmptyDlRenderer(DisplayListBuilder&) {}

class RenderSurface {
 public:
  explicit RenderSurface(sk_sp<SkSurface> surface) : surface_(surface) {
    EXPECT_EQ(canvas()->save(), 1);
  }
  ~RenderSurface() { sk_free(addr_); }

  SkCanvas* canvas() { return surface_->getCanvas(); }

  const SkPixmap* pixmap() {
    if (!pixmap_.addr()) {
      canvas()->restoreToCount(1);
      SkImageInfo info = surface_->imageInfo();
      if (info.colorType() != kN32_SkColorType ||
          !surface_->peekPixels(&pixmap_)) {
        info = SkImageInfo::MakeN32Premul(info.dimensions());
        addr_ = malloc(info.computeMinByteSize() * info.height());
        pixmap_.reset(info, addr_, info.minRowBytes());
        EXPECT_TRUE(surface_->readPixels(pixmap_, 0, 0));
      }
    }
    return &pixmap_;
  }

 private:
  sk_sp<SkSurface> surface_;
  SkPixmap pixmap_;
  void* addr_ = nullptr;
};

class RenderEnvironment {
 public:
  static RenderEnvironment Make565() {
    return RenderEnvironment(
        SkImageInfo::Make({1, 1}, kRGB_565_SkColorType, kOpaque_SkAlphaType));
  }

  static RenderEnvironment MakeN32() {
    return RenderEnvironment(SkImageInfo::MakeN32Premul(1, 1));
  }

  std::unique_ptr<RenderSurface> MakeSurface(
      const DlColor bg = DlColor::kTransparent(),
      int width = kTestWidth,
      int height = kTestHeight) const {
    sk_sp<SkSurface> surface =
        SkSurface::MakeRaster(info_.makeWH(width, height));
    surface->getCanvas()->clear(bg);
    return std::make_unique<RenderSurface>(surface);
  }

  void init_ref(CvRenderer& cv_renderer, DlColor bg = DlColor::kTransparent()) {
    init_ref([=](SkCanvas*, SkPaint&) {}, cv_renderer,
             [=](DisplayListBuilder&) {}, bg);
  }

  void init_ref(CvSetup& cv_setup,
                CvRenderer& cv_renderer,
                DlRenderer& dl_setup,
                DlColor bg = DlColor::kTransparent()) {
    ref_canvas()->clear(bg);
    dl_setup(ref_attr_);
    SkPaint paint;
    cv_setup(ref_canvas(), paint);
    ref_matrix_ = ref_canvas()->getTotalMatrix();
    ref_clip_ = ref_canvas()->getDeviceClipBounds();
    cv_renderer(ref_canvas(), paint);
    ref_pixmap_ = ref_surface_->pixmap();
  }

  const SkImageInfo& info() const { return info_; }
  SkCanvas* ref_canvas() { return ref_surface_->canvas(); }
  const DisplayListBuilder& ref_attr() const { return ref_attr_; }
  const SkMatrix& ref_matrix() const { return ref_matrix_; }
  const SkIRect& ref_clip_bounds() const { return ref_clip_; }
  const SkPixmap* ref_pixmap() const { return ref_pixmap_; }

 private:
  explicit RenderEnvironment(const SkImageInfo& info) : info_(info) {
    ref_surface_ = MakeSurface();
  }

  const SkImageInfo info_;

  DisplayListBuilder ref_attr_;
  SkMatrix ref_matrix_;
  SkIRect ref_clip_;
  std::unique_ptr<RenderSurface> ref_surface_;
  const SkPixmap* ref_pixmap_ = nullptr;
};

class TestParameters {
 public:
  TestParameters(const CvRenderer& cv_renderer,
                 const DlRenderer& dl_renderer,
                 const DisplayListAttributeFlags& flags)
      : cv_renderer_(cv_renderer), dl_renderer_(dl_renderer), flags_(flags) {}

  bool uses_paint() const { return !flags_.ignores_paint(); }

  bool should_match(const RenderEnvironment& env,
                    const DisplayListBuilder& attr,
                    const SkMatrix& matrix,
                    const SkIRect& device_clip,
                    bool has_diff_clip,
                    bool has_mutating_save_layer) const {
    if (has_mutating_save_layer) {
      return false;
    }
    if (env.ref_clip_bounds() != device_clip || has_diff_clip) {
      return false;
    }
    if (env.ref_matrix() != matrix && !flags_.is_flood()) {
      return false;
    }
    if (flags_.ignores_paint()) {
      return true;
    }
    const DisplayListBuilder& ref_attr = env.ref_attr();
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
        ref_attr.getBlender() != attr.getBlender()) {
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
    bool is_stroked = flags_.is_stroked(ref_attr.getStyle());
    if (flags_.is_stroked(attr.getStyle()) != is_stroked) {
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

  DlStrokeCap getCap(const DisplayListBuilder& attr,
                     DisplayListSpecialGeometryFlags geo_flags) const {
    DlStrokeCap cap = attr.getStrokeCap();
    if (geo_flags.butt_cap_becomes_square() && cap == DlStrokeCap::kButt) {
      return DlStrokeCap::kSquare;
    }
    return cap;
  }

  const BoundsTolerance adjust(const BoundsTolerance& tolerance,
                               const SkPaint& paint,
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
      if (paint.getStyle() != SkPaint::kFill_Style &&
          paint.getStrokeJoin() == SkPaint::kMiter_Join) {
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
                                   const SkPaint& paint,
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
    auto paint_effect = paint.refPathEffect();

    DisplayListSpecialGeometryFlags geo_flags =
        flags_.WithPathEffect(DlPathEffect::From(paint.refPathEffect()).get());
    if (paint.getStrokeCap() == SkPaint::kButt_Cap &&
        !geo_flags.butt_cap_becomes_square()) {
      adjust = std::max(adjust, half_width);
    }
    if (adjust == 0) {
      return tolerance;
    }
    SkScalar hTolerance;
    SkScalar vTolerance;
    if (is_horizontal_line()) {
      FML_DCHECK(!is_vertical_line());
      hTolerance = adjust;
      vTolerance = 0;
    } else if (is_vertical_line()) {
      hTolerance = 0;
      vTolerance = adjust;
    } else {
      // The perpendicular miters just do not impact the bounds of
      // diagonal lines at all as they are aimed in the wrong direction
      // to matter. So allow tolerance in both axes.
      hTolerance = vTolerance = adjust;
    }
    BoundsTolerance new_tolerance =
        tolerance.addBoundsPadding(hTolerance, vTolerance);
    return new_tolerance;
  }

  const CvRenderer& cv_renderer() const { return cv_renderer_; }
  void render_to(SkCanvas* canvas, SkPaint& paint) const {
    cv_renderer_(canvas, paint);
  }

  const DlRenderer& dl_renderer() const { return dl_renderer_; }
  void render_to(DisplayListBuilder& builder) const {  //
    dl_renderer_(builder);
  }

  // If a test is using any shadow operations then we cannot currently
  // record those in an SkCanvas and play it back into a DisplayList
  // because internally the operation gets encapsulated in a Skia
  // ShadowRec which is not exposed by their headers. For operations
  // that use shadows, we can perform a lot of tests, but not the tests
  // that require SkCanvas->DisplayList transfers.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
  bool is_draw_shadows() const { return is_draw_shadows_; }
  // The CPU renders nothing for drawVertices with a Blender.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12200
  bool is_draw_vertices() const { return is_draw_vertices_; }
  // The CPU renders nothing for drawAtlas with a Blender.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12199
  bool is_draw_atlas() const { return is_draw_atlas_; }
  // Tests that call drawTextBlob with an sk_ref paint attribute will cause
  // those attributes to be stored in an internal Skia cache so we need
  // to expect that the |sk_ref.unique()| call will fail in those cases.
  // See: (TBD(flar) - file Skia bug)
  bool is_draw_text_blob() const { return is_draw_text_blob_; }
  bool is_draw_display_list() const { return is_draw_display_list_; }
  bool is_draw_line() const { return is_draw_line_; }
  bool is_draw_arc_center() const { return is_draw_arc_center_; }
  bool is_horizontal_line() const { return is_horizontal_line_; }
  bool is_vertical_line() const { return is_vertical_line_; }
  bool ignores_dashes() const { return ignores_dashes_; }

  TestParameters& set_draw_shadows() {
    is_draw_shadows_ = true;
    return *this;
  }
  TestParameters& set_draw_vertices() {
    is_draw_vertices_ = true;
    return *this;
  }
  TestParameters& set_draw_text_blob() {
    is_draw_text_blob_ = true;
    return *this;
  }
  TestParameters& set_draw_atlas() {
    is_draw_atlas_ = true;
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
  const CvRenderer& cv_renderer_;
  const DlRenderer& dl_renderer_;
  const DisplayListAttributeFlags& flags_;

  bool is_draw_shadows_ = false;
  bool is_draw_vertices_ = false;
  bool is_draw_text_blob_ = false;
  bool is_draw_atlas_ = false;
  bool is_draw_display_list_ = false;
  bool is_draw_line_ = false;
  bool is_draw_arc_center_ = false;
  bool ignores_dashes_ = false;
  bool is_horizontal_line_ = false;
  bool is_vertical_line_ = false;
};

class CaseParameters {
 public:
  explicit CaseParameters(std::string info)
      : CaseParameters(info, EmptyCvRenderer, EmptyDlRenderer) {}

  CaseParameters(std::string info, CvSetup cv_setup, DlRenderer dl_setup)
      : CaseParameters(info,
                       cv_setup,
                       dl_setup,
                       EmptyCvRenderer,
                       EmptyDlRenderer,
                       SK_ColorTRANSPARENT,
                       false,
                       false,
                       false) {}

  CaseParameters(std::string info,
                 CvSetup cv_setup,
                 DlRenderer dl_setup,
                 CvRenderer cv_restore,
                 DlRenderer dl_restore,
                 DlColor bg,
                 bool has_diff_clip,
                 bool has_mutating_save_layer,
                 bool fuzzy_compare_components)
      : info_(info),
        bg_(bg),
        cv_setup_(cv_setup),
        dl_setup_(dl_setup),
        cv_restore_(cv_restore),
        dl_restore_(dl_restore),
        has_diff_clip_(has_diff_clip),
        has_mutating_save_layer_(has_mutating_save_layer),
        fuzzy_compare_components_(fuzzy_compare_components) {}

  CaseParameters with_restore(CvRenderer cv_restore,
                              DlRenderer dl_restore,
                              bool mutating_layer,
                              bool fuzzy_compare_components = false) {
    return CaseParameters(info_, cv_setup_, dl_setup_, cv_restore, dl_restore,
                          bg_, has_diff_clip_, mutating_layer,
                          fuzzy_compare_components);
  }

  CaseParameters with_bg(DlColor bg) {
    return CaseParameters(info_, cv_setup_, dl_setup_, cv_restore_, dl_restore_,
                          bg, has_diff_clip_, has_mutating_save_layer_,
                          fuzzy_compare_components_);
  }

  CaseParameters with_diff_clip() {
    return CaseParameters(info_, cv_setup_, dl_setup_, cv_restore_, dl_restore_,
                          bg_, true, has_mutating_save_layer_,
                          fuzzy_compare_components_);
  }

  std::string info() const { return info_; }
  DlColor bg() const { return bg_; }
  bool has_diff_clip() const { return has_diff_clip_; }
  bool has_mutating_save_layer() const { return has_mutating_save_layer_; }
  bool fuzzy_compare_components() const { return fuzzy_compare_components_; }

  CvSetup cv_setup() const { return cv_setup_; }
  DlRenderer dl_setup() const { return dl_setup_; }
  CvRenderer cv_restore() const { return cv_restore_; }
  DlRenderer dl_restore() const { return dl_restore_; }

  const SkPaint render_to(SkCanvas* canvas,  //
                          const TestParameters& testP) const {
    SkPaint paint;
    cv_setup_(canvas, paint);
    testP.render_to(canvas, paint);
    cv_restore_(canvas, paint);
    return paint;
  }

  void render_to(DisplayListBuilder& builder,
                 const TestParameters& testP) const {
    dl_setup_(builder);
    testP.render_to(builder);
    dl_restore_(builder);
  }

 private:
  const std::string info_;
  const DlColor bg_;
  const CvSetup cv_setup_;
  const DlRenderer dl_setup_;
  const CvRenderer cv_restore_;
  const DlRenderer dl_restore_;
  const bool has_diff_clip_;
  const bool has_mutating_save_layer_;
  const bool fuzzy_compare_components_;
};

class CanvasCompareTester {
 public:
  static BoundsTolerance DefaultTolerance;

  static void RenderAll(const TestParameters& params,
                        const BoundsTolerance& tolerance = DefaultTolerance) {
    RenderEnvironment env = RenderEnvironment::MakeN32();
    env.init_ref(params.cv_renderer());
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
    SkRect clip =
        SkRect::MakeXYWH(kRenderCenterX - 1, kRenderCenterY - 1, 2, 2);
    SkRect rect = SkRect::MakeXYWH(kRenderCenterX, kRenderCenterY, 10, 10);
    DlColor alpha_layer_color = DlColor::kCyan().withAlpha(0x7f);
    DlColor default_color = DlPaint::kDefaultColor;
    CvRenderer cv_safe_restore = [=](SkCanvas* cv, const SkPaint& p) {
      // Draw another primitive to disable peephole optimizations
      cv->drawRect(kRenderBounds.makeOffset(500, 500), p);
      cv->restore();
    };
    DlRenderer dl_safe_restore = [=](DisplayListBuilder& b) {
      // Draw another primitive to disable peephole optimizations
      b.drawRect(kRenderBounds.makeOffset(500, 500));
      b.restore();
    };
    CvRenderer cv_opt_restore = [=](SkCanvas* cv, const SkPaint& p) {
      // Just a simple restore to allow peephole optimizations to occur
      cv->restore();
    };
    DlRenderer dl_opt_restore = [=](DisplayListBuilder& b) {
      // Just a simple restore to allow peephole optimizations to occur
      b.restore();
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
                   [=](DisplayListBuilder& b) {
                     b.save();
                     b.clipRect(clip, SkClipOp::kIntersect, false);
                     b.drawRect(rect);
                     b.setBlendMode(DlBlendMode::kClear);
                     b.drawRect(rect);
                     b.setBlendMode(DlBlendMode::kSrcOver);
                     b.restore();
                   }));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer no paint, no bounds",
                   [=](SkCanvas* cv, SkPaint& p) {  //
                     cv->saveLayer(nullptr, nullptr);
                   },
                   [=](DisplayListBuilder& b) {  //
                     b.saveLayer(nullptr, false);
                   })
                   .with_restore(cv_safe_restore, dl_safe_restore, false));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer no paint, with bounds",
                   [=](SkCanvas* cv, SkPaint& p) {  //
                     cv->saveLayer(layer_bounds, nullptr);
                   },
                   [=](DisplayListBuilder& b) {  //
                     b.saveLayer(&layer_bounds, false);
                   })
                   .with_restore(cv_safe_restore, dl_safe_restore, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with alpha, no bounds",
                   [=](SkCanvas* cv, SkPaint& p) {
                     SkPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->saveLayer(nullptr, &save_p);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setColor(alpha_layer_color);
                     b.saveLayer(nullptr, true);
                     b.setColor(default_color);
                   })
                   .with_restore(cv_safe_restore, dl_safe_restore, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with peephole alpha, no bounds",
                   [=](SkCanvas* cv, SkPaint& p) {
                     SkPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->saveLayer(nullptr, &save_p);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setColor(alpha_layer_color);
                     b.saveLayer(nullptr, true);
                     b.setColor(default_color);
                   })
                   .with_restore(cv_opt_restore, dl_opt_restore, true, true));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer with alpha and bounds",
                   [=](SkCanvas* cv, SkPaint& p) {
                     SkPaint save_p;
                     save_p.setColor(alpha_layer_color);
                     cv->saveLayer(layer_bounds, &save_p);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setColor(alpha_layer_color);
                     b.saveLayer(&layer_bounds, true);
                     b.setColor(default_color);
                   })
                   .with_restore(cv_safe_restore, dl_safe_restore, true));
    {
      // Being able to see a backdrop blur requires a non-default background
      // so we create a new environment for these tests that has a checkerboard
      // background that can be blurred by the backdrop filter. We also want
      // to avoid the rendered primitive from obscuring the blurred background
      // so we set an alpha value which works for all primitives except for
      // drawColor which can override the alpha with its color, but it now uses
      // a non-opaque color to avoid that problem.
      RenderEnvironment backdrop_env = RenderEnvironment::MakeN32();
      CvSetup cv_backdrop_setup = [=](SkCanvas* cv, SkPaint& p) {
        SkPaint setup_p;
        setup_p.setShader(kTestImageColorSource.skia_object());
        cv->drawPaint(setup_p);
        p.setAlpha(p.getAlpha() / 2);
      };
      DlRenderer dl_backdrop_setup = [=](DisplayListBuilder& b) {
        b.setColorSource(&kTestImageColorSource);
        b.drawPaint();
        b.setColorSource(nullptr);
        DlColor current_color = b.getColor();
        b.setColor(current_color.withAlpha(current_color.getAlpha() / 2));
      };
      backdrop_env.init_ref(cv_backdrop_setup, testP.cv_renderer(),
                            dl_backdrop_setup);

      DlBlurImageFilter backdrop(5, 5, DlTileMode::kDecal);
      RenderWith(testP, backdrop_env, tolerance,
                 CaseParameters(
                     "saveLayer with backdrop",
                     [=](SkCanvas* cv, SkPaint& p) {
                       cv_backdrop_setup(cv, p);
                       cv->saveLayer(SkCanvas::SaveLayerRec(
                           nullptr, nullptr, backdrop.skia_object().get(), 0));
                     },
                     [=](DisplayListBuilder& b) {
                       dl_backdrop_setup(b);
                       b.saveLayer(nullptr, SaveLayerOptions::kNoAttributes,
                                   &backdrop);
                     })
                     .with_restore(cv_safe_restore, dl_safe_restore, true));
      RenderWith(
          testP, backdrop_env, tolerance,
          CaseParameters(
              "saveLayer with bounds and backdrop",
              [=](SkCanvas* cv, SkPaint& p) {
                cv_backdrop_setup(cv, p);
                cv->saveLayer(SkCanvas::SaveLayerRec(
                    &layer_bounds, nullptr, backdrop.skia_object().get(), 0));
              },
              [=](DisplayListBuilder& b) {
                dl_backdrop_setup(b);
                b.saveLayer(&layer_bounds, SaveLayerOptions::kNoAttributes,
                            &backdrop);
              })
              .with_restore(cv_safe_restore, dl_safe_restore, true));
      RenderWith(testP, backdrop_env, tolerance,
                 CaseParameters(
                     "clipped saveLayer with backdrop",
                     [=](SkCanvas* cv, SkPaint& p) {
                       cv_backdrop_setup(cv, p);
                       cv->clipRect(layer_bounds);
                       cv->saveLayer(SkCanvas::SaveLayerRec(
                           nullptr, nullptr, backdrop.skia_object().get(), 0));
                     },
                     [=](DisplayListBuilder& b) {
                       dl_backdrop_setup(b);
                       b.clipRect(layer_bounds, SkClipOp::kIntersect, false);
                       b.saveLayer(nullptr, SaveLayerOptions::kNoAttributes,
                                   &backdrop);
                     })
                     .with_restore(cv_safe_restore, dl_safe_restore, true));
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
                       [=](DisplayListBuilder& b) {
                         b.setColorFilter(&filter);
                         b.saveLayer(nullptr, true);
                         b.setColorFilter(nullptr);
                         b.setStrokeWidth(5.0);
                       })
                       .with_restore(cv_safe_restore, dl_safe_restore, true));
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
                       [=](DisplayListBuilder& b) {
                         b.setColorFilter(&filter);
                         b.saveLayer(&kRenderBounds, true);
                         b.setColorFilter(nullptr);
                         b.setStrokeWidth(5.0);
                       })
                       .with_restore(cv_safe_restore, dl_safe_restore, true));
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
                       [=](DisplayListBuilder& b) {
                         b.setImageFilter(&filter);
                         b.saveLayer(nullptr, true);
                         b.setImageFilter(nullptr);
                         b.setStrokeWidth(5.0);
                       })
                       .with_restore(cv_safe_restore, dl_safe_restore, true));
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
                       [=](DisplayListBuilder& b) {
                         b.setImageFilter(&filter);
                         b.saveLayer(&kRenderBounds, true);
                         b.setImageFilter(nullptr);
                         b.setStrokeWidth(5.0);
                       })
                       .with_restore(cv_safe_restore, dl_safe_restore, true));
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
      RenderEnvironment aa_env = RenderEnvironment::MakeN32();
      // Tweak the bounds tolerance for the displacement of 1/10 of a pixel
      const BoundsTolerance aa_tolerance = tolerance.addBoundsPadding(1, 1);
      CvSetup cv_aa_setup = [=](SkCanvas* cv, SkPaint& p) {
        cv->translate(0.1, 0.1);
        p.setStrokeWidth(5.0);
      };
      DlRenderer dl_aa_setup = [=](DisplayListBuilder& b) {
        b.translate(0.1, 0.1);
        b.setStrokeWidth(5.0);
      };
      aa_env.init_ref(cv_aa_setup, testP.cv_renderer(), dl_aa_setup);
      RenderWith(testP, aa_env, aa_tolerance,
                 CaseParameters(
                     "AntiAlias == True",
                     [=](SkCanvas* cv, SkPaint& p) {
                       cv_aa_setup(cv, p);
                       p.setAntiAlias(true);
                     },
                     [=](DisplayListBuilder& b) {
                       dl_aa_setup(b);
                       b.setAntiAlias(true);
                     }));
      RenderWith(testP, aa_env, aa_tolerance,
                 CaseParameters(
                     "AntiAlias == False",
                     [=](SkCanvas* cv, SkPaint& p) {
                       cv_aa_setup(cv, p);
                       p.setAntiAlias(false);
                     },
                     [=](DisplayListBuilder& b) {
                       dl_aa_setup(b);
                       b.setAntiAlias(false);
                     }));
    }

    {
      // The CPU renderer does not always dither for solid colors and we
      // need to use a non-default color (default is black) on an opaque
      // surface, so we use a shader instead of a color. Also, thin stroked
      // primitives (mainly drawLine and drawPoints) do not show much
      // dithering so we use a non-trivial stroke width as well.
      RenderEnvironment dither_env = RenderEnvironment::Make565();
      DlColor dither_bg = DlColor::kBlack();
      CvSetup cv_dither_setup = [=](SkCanvas*, SkPaint& p) {
        p.setShader(kTestImageColorSource.skia_object());
        p.setAlpha(0xf0);
        p.setStrokeWidth(5.0);
      };
      DlRenderer dl_dither_setup = [=](DisplayListBuilder& b) {
        b.setColorSource(&kTestImageColorSource);
        b.setColor(DlColor(0xf0000000));
        b.setStrokeWidth(5.0);
      };
      dither_env.init_ref(cv_dither_setup, testP.cv_renderer(),  //
                          dl_dither_setup, dither_bg);
      RenderWith(testP, dither_env, tolerance,
                 CaseParameters(
                     "Dither == True",
                     [=](SkCanvas* cv, SkPaint& p) {
                       cv_dither_setup(cv, p);
                       p.setDither(true);
                     },
                     [=](DisplayListBuilder& b) {
                       dl_dither_setup(b);
                       b.setDither(true);
                     })
                     .with_bg(dither_bg));
      RenderWith(testP, dither_env, tolerance,
                 CaseParameters(
                     "Dither = False",
                     [=](SkCanvas* cv, SkPaint& p) {
                       cv_dither_setup(cv, p);
                       p.setDither(false);
                     },
                     [=](DisplayListBuilder& b) {
                       dl_dither_setup(b);
                       b.setDither(false);
                     })
                     .with_bg(dither_bg));
    }

    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Color == Blue",
                   [=](SkCanvas*, SkPaint& p) { p.setColor(SK_ColorBLUE); },
                   [=](DisplayListBuilder& b) { b.setColor(SK_ColorBLUE); }));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Color == Green",
                   [=](SkCanvas*, SkPaint& p) { p.setColor(SK_ColorGREEN); },
                   [=](DisplayListBuilder& b) { b.setColor(SK_ColorGREEN); }));

    RenderWithStrokes(testP, env, tolerance);

    {
      // half opaque cyan
      DlColor blendableColor = DlColor::kCyan().withAlpha(0x7f);
      DlColor bg = DlColor::kWhite();

      RenderWith(testP, env, tolerance,
                 CaseParameters(
                     "Blend == SrcIn",
                     [=](SkCanvas*, SkPaint& p) {
                       p.setBlendMode(SkBlendMode::kSrcIn);
                       p.setColor(blendableColor);
                     },
                     [=](DisplayListBuilder& b) {
                       b.setBlendMode(DlBlendMode::kSrcIn);
                       b.setColor(blendableColor);
                     })
                     .with_bg(bg));
      RenderWith(testP, env, tolerance,
                 CaseParameters(
                     "Blend == DstIn",
                     [=](SkCanvas*, SkPaint& p) {
                       p.setBlendMode(SkBlendMode::kDstIn);
                       p.setColor(blendableColor);
                     },
                     [=](DisplayListBuilder& b) {
                       b.setBlendMode(DlBlendMode::kDstIn);
                       b.setColor(blendableColor);
                     })
                     .with_bg(bg));
    }

    if (!(testP.is_draw_atlas() || testP.is_draw_vertices())) {
      sk_sp<SkBlender> blender =
          SkBlenders::Arithmetic(0.25, 0.25, 0.25, 0.25, false);
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "Blender == Arithmetic 0.25-false",
                       [=](SkCanvas*, SkPaint& p) { p.setBlender(blender); },
                       [=](DisplayListBuilder& b) { b.setBlender(blender); }));
      }
      EXPECT_TRUE(blender->unique()) << "Blender Cleanup";
      blender = SkBlenders::Arithmetic(0.25, 0.25, 0.25, 0.25, true);
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "Blender == Arithmetic 0.25-true",
                       [=](SkCanvas*, SkPaint& p) { p.setBlender(blender); },
                       [=](DisplayListBuilder& b) { b.setBlender(blender); }));
      }
      EXPECT_TRUE(blender->unique()) << "Blender Cleanup";
    }

    {
      // Being able to see a blur requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment blur_env = RenderEnvironment::MakeN32();
      CvSetup cv_blur_setup = [=](SkCanvas*, SkPaint& p) {
        p.setShader(kTestImageColorSource.skia_object());
        p.setStrokeWidth(5.0);
      };
      DlRenderer dl_blur_setup = [=](DisplayListBuilder& b) {
        b.setColorSource(&kTestImageColorSource);
        b.setStrokeWidth(5.0);
      };
      blur_env.init_ref(cv_blur_setup, testP.cv_renderer(), dl_blur_setup);
      DlBlurImageFilter filter_decal_5(5.0, 5.0, DlTileMode::kDecal);
      BoundsTolerance blur5Tolerance = tolerance.addBoundsPadding(4, 4);
      {
        RenderWith(testP, blur_env, blur5Tolerance,
                   CaseParameters(
                       "ImageFilter == Decal Blur 5",
                       [=](SkCanvas* cv, SkPaint& p) {
                         cv_blur_setup(cv, p);
                         p.setImageFilter(filter_decal_5.skia_object());
                       },
                       [=](DisplayListBuilder& b) {
                         dl_blur_setup(b);
                         b.setImageFilter(&filter_decal_5);
                       }));
      }
      DlBlurImageFilter filter_clamp_5(5.0, 5.0, DlTileMode::kClamp);
      {
        RenderWith(testP, blur_env, blur5Tolerance,
                   CaseParameters(
                       "ImageFilter == Clamp Blur 5",
                       [=](SkCanvas* cv, SkPaint& p) {
                         cv_blur_setup(cv, p);
                         p.setImageFilter(filter_clamp_5.skia_object());
                       },
                       [=](DisplayListBuilder& b) {
                         dl_blur_setup(b);
                         b.setImageFilter(&filter_clamp_5);
                       }));
      }
    }

    {
      // Being able to see a dilate requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment dilate_env = RenderEnvironment::MakeN32();
      CvSetup cv_dilate_setup = [=](SkCanvas*, SkPaint& p) {
        p.setShader(kTestImageColorSource.skia_object());
        p.setStrokeWidth(5.0);
      };
      DlRenderer dl_dilate_setup = [=](DisplayListBuilder& b) {
        b.setColorSource(&kTestImageColorSource);
        b.setStrokeWidth(5.0);
      };
      dilate_env.init_ref(cv_dilate_setup, testP.cv_renderer(),
                          dl_dilate_setup);
      DlDilateImageFilter filter_5(5.0, 5.0);
      RenderWith(testP, dilate_env, tolerance,
                 CaseParameters(
                     "ImageFilter == Dilate 5",
                     [=](SkCanvas* cv, SkPaint& p) {
                       cv_dilate_setup(cv, p);
                       p.setImageFilter(filter_5.skia_object());
                     },
                     [=](DisplayListBuilder& b) {
                       dl_dilate_setup(b);
                       b.setImageFilter(&filter_5);
                     }));
    }

    {
      // Being able to see an erode requires some non-default attributes,
      // like a non-trivial stroke width and a shader rather than a color
      // (for drawPaint) so we create a new environment for these tests.
      RenderEnvironment erode_env = RenderEnvironment::MakeN32();
      CvSetup cv_erode_setup = [=](SkCanvas*, SkPaint& p) {
        p.setShader(kTestImageColorSource.skia_object());
        p.setStrokeWidth(6.0);
      };
      DlRenderer dl_erode_setup = [=](DisplayListBuilder& b) {
        b.setColorSource(&kTestImageColorSource);
        b.setStrokeWidth(6.0);
      };
      erode_env.init_ref(cv_erode_setup, testP.cv_renderer(), dl_erode_setup);
      // do not erode too much, because some tests assert there are enough
      // pixels that are changed.
      DlErodeImageFilter filter_1(1.0, 1.0);
      RenderWith(testP, erode_env, tolerance,
                 CaseParameters(
                     "ImageFilter == Erode 1",
                     [=](SkCanvas* cv, SkPaint& p) {
                       cv_erode_setup(cv, p);
                       p.setImageFilter(filter_1.skia_object());
                     },
                     [=](DisplayListBuilder& b) {
                       dl_erode_setup(b);
                       b.setImageFilter(&filter_1);
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
                       [=](DisplayListBuilder& b) {
                         b.setColor(DlColor::kYellow());
                         b.setColorFilter(&filter);
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
                       [=](DisplayListBuilder& b) {
                         b.setColor(DlColor::kYellow());
                         b.setInvertColors(true);
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
                       [=](DisplayListBuilder& b) {
                         b.setStrokeWidth(5.0);
                         b.setStrokeMiter(3.0);
                         b.setPathEffect(DlPathEffect::From(effect).get());
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
                       [=](DisplayListBuilder& b) {
                         b.setStrokeWidth(5.0);
                         b.setStrokeMiter(2.5);
                         b.setPathEffect(DlPathEffect::From(effect).get());
                       }));
      }
      EXPECT_TRUE(testP.is_draw_text_blob() || effect->unique())
          << "PathEffect == Discrete-2-3 Cleanup";
    }

    {
      const DlBlurMaskFilter filter(kNormal_SkBlurStyle, 5.0);
      BoundsTolerance blur5Tolerance = tolerance.addBoundsPadding(4, 4);
      {
        // Stroked primitives need some non-trivial stroke size to be blurred
        RenderWith(testP, env, blur5Tolerance,
                   CaseParameters(
                       "MaskFilter == Blur 5",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setMaskFilter(filter.skia_object());
                       },
                       [=](DisplayListBuilder& b) {
                         b.setStrokeWidth(5.0);
                         b.setMaskFilter(&filter);
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
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "LinearGradient GYB",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setShader(source->skia_object());
                       },
                       [=](DisplayListBuilder& b) {
                         b.setColorSource(source.get());
                       }));
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
                   [=](DisplayListBuilder& b) {  //
                     b.setStyle(DlDrawStyle::kFill);
                   }));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Stroke + defaults",
                   [=](SkCanvas*, SkPaint& p) {  //
                     p.setStyle(SkPaint::kStroke_Style);
                   },
                   [=](DisplayListBuilder& b) {  //
                     b.setStyle(DlDrawStyle::kStroke);
                   }));

    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Fill + unnecessary StrokeWidth 10",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kFill_Style);
                     p.setStrokeWidth(10.0);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kFill);
                     b.setStrokeWidth(10.0);
                   }));

    RenderEnvironment stroke_base_env = RenderEnvironment::MakeN32();
    CvSetup cv_stroke_setup = [=](SkCanvas*, SkPaint& p) {
      p.setStyle(SkPaint::kStroke_Style);
      p.setStrokeWidth(5.0);
    };
    DlRenderer dl_stroke_setup = [=](DisplayListBuilder& b) {
      b.setStyle(DlDrawStyle::kStroke);
      b.setStrokeWidth(5.0);
    };
    stroke_base_env.init_ref(cv_stroke_setup, testP.cv_renderer(),
                             dl_stroke_setup);

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 10",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(10.0);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kStroke);
                     b.setStrokeWidth(10.0);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kStroke);
                     b.setStrokeWidth(5.0);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Square Cap",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeCap(SkPaint::kSquare_Cap);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kStroke);
                     b.setStrokeWidth(5.0);
                     b.setStrokeCap(DlStrokeCap::kSquare);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Round Cap",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeCap(SkPaint::kRound_Cap);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kStroke);
                     b.setStrokeWidth(5.0);
                     b.setStrokeCap(DlStrokeCap::kRound);
                   }));

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Bevel Join",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeJoin(SkPaint::kBevel_Join);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kStroke);
                     b.setStrokeWidth(5.0);
                     b.setStrokeJoin(DlStrokeJoin::kBevel);
                   }));
    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 5, Round Join",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(5.0);
                     p.setStrokeJoin(SkPaint::kRound_Join);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kStroke);
                     b.setStrokeWidth(5.0);
                     b.setStrokeJoin(DlStrokeJoin::kRound);
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
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kStroke);
                     b.setStrokeWidth(5.0);
                     b.setStrokeMiter(10.0);
                     b.setStrokeJoin(DlStrokeJoin::kMiter);
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
                   [=](DisplayListBuilder& b) {
                     b.setStyle(DlDrawStyle::kStroke);
                     b.setStrokeWidth(5.0);
                     b.setStrokeMiter(0.0);
                     b.setStrokeJoin(DlStrokeJoin::kMiter);
                   }));

    {
      const SkScalar TestDashes1[] = {29.0, 2.0};
      const SkScalar TestDashes2[] = {17.0, 1.5};
      auto effect = DlDashPathEffect::Make(TestDashes1, 2, 0.0f);
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
                       [=](DisplayListBuilder& b) {
                         // Need stroke style to see dashing properly
                         b.setStyle(DlDrawStyle::kStroke);
                         // Provide some non-trivial stroke size to get dashed
                         b.setStrokeWidth(5.0);
                         b.setPathEffect(effect.get());
                       }));
      }
      effect = DlDashPathEffect::Make(TestDashes2, 2, 0.0f);
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
                       [=](DisplayListBuilder& b) {
                         // Need stroke style to see dashing properly
                         b.setStyle(DlDrawStyle::kStroke);
                         // Provide some non-trivial stroke size to get dashed
                         b.setStrokeWidth(5.0);
                         b.setPathEffect(effect.get());
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
                   [=](DisplayListBuilder& b) { b.translate(5, 10); }));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Scale +5%",  //
                   [=](SkCanvas* c, SkPaint&) { c->scale(1.05, 1.05); },
                   [=](DisplayListBuilder& b) { b.scale(1.05, 1.05); }));
    RenderWith(testP, env, skewed_tolerance,
               CaseParameters(
                   "Rotate 5 degrees",  //
                   [=](SkCanvas* c, SkPaint&) { c->rotate(5); },
                   [=](DisplayListBuilder& b) { b.rotate(5); }));
    RenderWith(testP, env, skewed_tolerance,
               CaseParameters(
                   "Skew 5%",  //
                   [=](SkCanvas* c, SkPaint&) { c->skew(0.05, 0.05); },
                   [=](DisplayListBuilder& b) { b.skew(0.05, 0.05); }));
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
                     [=](DisplayListBuilder& b) {
                       b.transform2DAffine(tx[0], tx[1], tx[2],  //
                                           tx[3], tx[4], tx[5]);
                     }));
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
      RenderWith(
          testP, env, skewed_tolerance,
          CaseParameters(
              "Transform Full Perspective",
              [=](SkCanvas* c, SkPaint&) { c->concat(m44); },  //
              [=](DisplayListBuilder& b) {
                b.transformFullPerspective(
                    m44.rc(0, 0), m44.rc(0, 1), m44.rc(0, 2), m44.rc(0, 3),
                    m44.rc(1, 0), m44.rc(1, 1), m44.rc(1, 2), m44.rc(1, 3),
                    m44.rc(2, 0), m44.rc(2, 1), m44.rc(2, 2), m44.rc(2, 3),
                    m44.rc(3, 0), m44.rc(3, 1), m44.rc(3, 2), m44.rc(3, 3));
              }));
    }
  }

  static void RenderWithClips(const TestParameters& testP,
                              const RenderEnvironment& env,
                              const BoundsTolerance& diff_tolerance) {
    SkRect r_clip = kRenderBounds.makeInset(15.5, 15.5);
    BoundsTolerance intersect_tolerance = diff_tolerance.clip(r_clip);
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipRect inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRect(r_clip, SkClipOp::kIntersect, false);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipRect(r_clip, SkClipOp::kIntersect, false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipRect inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRect(r_clip, SkClipOp::kIntersect, true);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipRect(r_clip, SkClipOp::kIntersect, true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipRect Diff, inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRect(r_clip, SkClipOp::kDifference, false);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipRect(r_clip, SkClipOp::kDifference, false);
                   })
                   .with_diff_clip());
    SkRRect rr_clip = SkRRect::MakeRectXY(r_clip, 1.8, 2.7);
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipRRect inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRRect(rr_clip, SkClipOp::kIntersect, false);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipRRect(rr_clip, SkClipOp::kIntersect, false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipRRect inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRRect(rr_clip, SkClipOp::kIntersect, true);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipRRect(rr_clip, SkClipOp::kIntersect, true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipRRect Diff, inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipRRect(rr_clip, SkClipOp::kDifference, false);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipRRect(rr_clip, SkClipOp::kDifference, false);
                   })
                   .with_diff_clip());
    SkPath path_clip = SkPath();
    path_clip.setFillType(SkPathFillType::kEvenOdd);
    path_clip.addRect(r_clip);
    path_clip.addCircle(kRenderCenterX, kRenderCenterY, 1.0);
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "Hard ClipPath inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipPath(path_clip, SkClipOp::kIntersect, false);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipPath(path_clip, SkClipOp::kIntersect, false);
                   }));
    RenderWith(testP, env, intersect_tolerance,
               CaseParameters(
                   "AntiAlias ClipPath inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipPath(path_clip, SkClipOp::kIntersect, true);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipPath(path_clip, SkClipOp::kIntersect, true);
                   }));
    RenderWith(testP, env, diff_tolerance,
               CaseParameters(
                   "Hard ClipPath Diff, inset by 15.5",
                   [=](SkCanvas* c, SkPaint&) {
                     c->clipPath(path_clip, SkClipOp::kDifference, false);
                   },
                   [=](DisplayListBuilder& b) {
                     b.clipPath(path_clip, SkClipOp::kDifference, false);
                   })
                   .with_diff_clip());
  }

  static sk_sp<SkPicture> getSkPicture(const TestParameters& testP,
                                       const CaseParameters& caseP) {
    SkPictureRecorder recorder;
    SkRTreeFactory rtree_factory;
    SkCanvas* cv = recorder.beginRecording(kTestBounds, &rtree_factory);
    caseP.render_to(cv, testP);
    return recorder.finishRecordingAsPicture();
  }

  static void RenderWith(const TestParameters& testP,
                         const RenderEnvironment& env,
                         const BoundsTolerance& tolerance_in,
                         const CaseParameters& caseP) {
    // sk_surface is a direct rendering via SkCanvas to SkSurface
    // DisplayList mechanisms are not involved in this operation
    const std::string info = caseP.info();
    const DlColor bg = caseP.bg();
    std::unique_ptr<RenderSurface> sk_surface = env.MakeSurface(bg);
    SkCanvas* sk_canvas = sk_surface->canvas();
    SkPaint sk_paint;
    caseP.cv_setup()(sk_canvas, sk_paint);
    SkMatrix sk_matrix = sk_canvas->getTotalMatrix();
    SkIRect sk_clip = sk_canvas->getDeviceClipBounds();
    const BoundsTolerance tolerance =
        testP.adjust(tolerance_in, sk_paint, sk_canvas->getTotalMatrix());
    testP.render_to(sk_canvas, sk_paint);
    caseP.cv_restore()(sk_canvas, sk_paint);
    const sk_sp<SkPicture> sk_picture = getSkPicture(testP, caseP);
    SkRect sk_bounds = sk_picture->cullRect();
    const SkPixmap* sk_pixels = sk_surface->pixmap();
    ASSERT_EQ(sk_pixels->width(), kTestWidth) << info;
    ASSERT_EQ(sk_pixels->height(), kTestHeight) << info;
    ASSERT_EQ(sk_pixels->info().bytesPerPixel(), 4) << info;
    checkPixels(sk_pixels, sk_bounds, info + " (Skia reference)", bg);

    DisplayListBuilder dl_attr;
    caseP.dl_setup()(dl_attr);
    if (testP.should_match(env, dl_attr, sk_matrix, sk_clip,
                           caseP.has_diff_clip(),
                           caseP.has_mutating_save_layer())) {
      quickCompareToReference(env.ref_pixmap(), sk_pixels, true,
                              info + " (attribute has no effect)");
    } else {
      quickCompareToReference(env.ref_pixmap(), sk_pixels, false,
                              info + " (attribute affects rendering)");
    }

    {
      // This sequence plays the provided equivalently constructed
      // DisplayList onto the SkCanvas of the surface
      // DisplayList => direct rendering
      DisplayListBuilder builder(kTestBounds);
      caseP.render_to(builder, testP);
      sk_sp<DisplayList> display_list = builder.Build();
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
      }

      std::unique_ptr<RenderSurface> dl_surface = env.MakeSurface(bg);
      display_list->RenderTo(dl_surface->canvas());
      compareToReference(dl_surface->pixmap(), sk_pixels,
                         info + " (DisplayList built directly -> surface)",
                         &dl_bounds, &tolerance, bg,
                         caseP.fuzzy_compare_components());

      if (display_list->can_apply_group_opacity()) {
        checkGroupOpacity(env, display_list, dl_surface->pixmap(),
                          info + " with Group Opacity", bg);
      }
    }

    // This test cannot work if the rendering is using shadows until
    // we can access the Skia ShadowRec via public headers.
    if (!testP.is_draw_shadows()) {
      // This sequence renders SkCanvas calls to a DisplayList and then
      // plays them back on SkCanvas to SkSurface
      // SkCanvas calls => DisplayList => rendering
      std::unique_ptr<RenderSurface> cv_dl_surface = env.MakeSurface(bg);
      DisplayListCanvasRecorder dl_recorder(kTestBounds);
      caseP.render_to(&dl_recorder, testP);
      dl_recorder.builder()->Build()->RenderTo(cv_dl_surface->canvas());
      compareToReference(cv_dl_surface->pixmap(), sk_pixels,
                         info + " (Skia calls -> DisplayList -> surface)",
                         nullptr, nullptr, bg,
                         caseP.fuzzy_compare_components());
    }

    {
      // This sequence renders the SkCanvas calls to an SkPictureRecorder and
      // renders the DisplayList calls to a DisplayListBuilder and then
      // renders both back under a transform (scale(2x)) to see if their
      // rendering is affected differently by a change of matrix between
      // recording time and rendering time.
      const int TestWidth2 = kTestWidth * 2;
      const int TestHeight2 = kTestHeight * 2;
      const SkScalar TestScale = 2.0;

      SkPictureRecorder sk_x2_recorder;
      SkCanvas* ref_canvas = sk_x2_recorder.beginRecording(kTestBounds);
      SkPaint ref_paint;
      caseP.render_to(ref_canvas, testP);
      sk_sp<SkPicture> ref_x2_picture =
          sk_x2_recorder.finishRecordingAsPicture();
      std::unique_ptr<RenderSurface> ref_x2_surface =
          env.MakeSurface(bg, TestWidth2, TestHeight2);
      SkCanvas* ref_x2_canvas = ref_x2_surface->canvas();
      ref_x2_canvas->scale(TestScale, TestScale);
      ref_x2_picture->playback(ref_x2_canvas);
      const SkPixmap* ref_x2_pixels = ref_x2_surface->pixmap();
      ASSERT_EQ(ref_x2_pixels->width(), TestWidth2) << info;
      ASSERT_EQ(ref_x2_pixels->height(), TestHeight2) << info;
      ASSERT_EQ(ref_x2_pixels->info().bytesPerPixel(), 4) << info;

      DisplayListBuilder builder_x2(kTestBounds);
      caseP.render_to(builder_x2, testP);
      sk_sp<DisplayList> display_list_x2 = builder_x2.Build();
      std::unique_ptr<RenderSurface> test_x2_surface =
          env.MakeSurface(bg, TestWidth2, TestHeight2);
      SkCanvas* test_x2_canvas = test_x2_surface->canvas();
      test_x2_canvas->scale(TestScale, TestScale);
      display_list_x2->RenderTo(test_x2_canvas);
      compareToReference(test_x2_surface->pixmap(), ref_x2_pixels,
                         info + " (Both rendered scaled 2x)", nullptr, nullptr,
                         bg, caseP.fuzzy_compare_components(),  //
                         TestWidth2, TestHeight2, false);
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

  static void checkGroupOpacity(const RenderEnvironment& env,
                                sk_sp<DisplayList> display_list,
                                const SkPixmap* ref_pixmap,
                                const std::string info,
                                DlColor bg) {
    SkScalar opacity = 128.0 / 255.0;

    std::unique_ptr<RenderSurface> group_opacity_surface = env.MakeSurface(bg);
    SkCanvas* group_opacity_canvas = group_opacity_surface->canvas();
    display_list->RenderTo(group_opacity_canvas, opacity);
    const SkPixmap* group_opacity_pixmap = group_opacity_surface->pixmap();

    ASSERT_EQ(group_opacity_pixmap->width(), kTestWidth) << info;
    ASSERT_EQ(group_opacity_pixmap->height(), kTestHeight) << info;
    ASSERT_EQ(group_opacity_pixmap->info().bytesPerPixel(), 4) << info;

    ASSERT_EQ(ref_pixmap->width(), kTestWidth) << info;
    ASSERT_EQ(ref_pixmap->height(), kTestHeight) << info;
    ASSERT_EQ(ref_pixmap->info().bytesPerPixel(), 4) << info;

    int pixels_touched = 0;
    int pixels_different = 0;
    // We need to allow some slight differences per component due to the
    // fact that rearranging discrete calculations can compound round off
    // errors. Off-by-2 is enough for 8 bit components, but for the 565
    // tests we allow at least 9 which is the maximum distance between
    // samples when converted to 8 bits. (You might think it would be a
    // max step of 8 converting 5 bits to 8 bits, but it is really
    // converting 31 steps to 255 steps with an average step size of
    // 8.23 - 24 of the steps are by 8, but 7 of them are by 9.)
    int fudge = env.info().bytesPerPixel() < 4 ? 9 : 2;
    for (int y = 0; y < kTestHeight; y++) {
      const uint32_t* ref_row = ref_pixmap->addr32(0, y);
      const uint32_t* test_row = group_opacity_pixmap->addr32(0, y);
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
              pixels_different++;
              break;
            }
          }
        }
      }
    }
    ASSERT_GT(pixels_touched, 20) << info;
    ASSERT_LE(pixels_different, 1) << info;
  }

  static void checkPixels(const SkPixmap* ref_pixels,
                          const SkRect ref_bounds,
                          const std::string info,
                          const DlColor bg) {
    uint32_t untouched = bg.premultipliedArgb();
    int pixels_touched = 0;
    int pixels_oob = 0;
    SkIRect i_bounds = ref_bounds.roundOut();
    for (int y = 0; y < kTestHeight; y++) {
      const uint32_t* ref_row = ref_pixels->addr32(0, y);
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

  static void quickCompareToReference(const SkPixmap* ref_pixels,
                                      const SkPixmap* test_pixels,
                                      bool should_match,
                                      const std::string info) {
    ASSERT_EQ(test_pixels->width(), ref_pixels->width()) << info;
    ASSERT_EQ(test_pixels->height(), ref_pixels->height()) << info;
    ASSERT_EQ(test_pixels->info().bytesPerPixel(), 4) << info;
    ASSERT_EQ(ref_pixels->info().bytesPerPixel(), 4) << info;
    int pixels_different = 0;
    for (int y = 0; y < test_pixels->height(); y++) {
      const uint32_t* ref_row = ref_pixels->addr32(0, y);
      const uint32_t* test_row = test_pixels->addr32(0, y);
      for (int x = 0; x < test_pixels->width(); x++) {
        if (ref_row[x] != test_row[x]) {
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

  static void compareToReference(const SkPixmap* test_pixels,
                                 const SkPixmap* ref_pixels,
                                 const std::string info,
                                 SkRect* bounds,
                                 const BoundsTolerance* tolerance,
                                 const DlColor bg,
                                 bool fuzzyCompares = false,
                                 int width = kTestWidth,
                                 int height = kTestHeight,
                                 bool printMismatches = false) {
    uint32_t untouched = bg.premultipliedArgb();
    ASSERT_EQ(test_pixels->width(), width) << info;
    ASSERT_EQ(test_pixels->height(), height) << info;
    ASSERT_EQ(test_pixels->info().bytesPerPixel(), 4) << info;
    ASSERT_EQ(ref_pixels->info().bytesPerPixel(), 4) << info;
    SkIRect i_bounds =
        bounds ? bounds->roundOut() : SkIRect::MakeWH(width, height);

    int pixels_different = 0;
    int pixels_oob = 0;
    int minX = width;
    int minY = height;
    int maxX = 0;
    int maxY = 0;
    for (int y = 0; y < height; y++) {
      const uint32_t* ref_row = ref_pixels->addr32(0, y);
      const uint32_t* test_row = test_pixels->addr32(0, y);
      for (int x = 0; x < width; x++) {
        if (bounds && test_row[x] != untouched) {
          if (minX > x) {
            minX = x;
          }
          if (minY > y) {
            minY = y;
          }
          if (maxX <= x) {
            maxX = x + 1;
          }
          if (maxY <= y) {
            maxY = y + 1;
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
                     << minX << ", " << minY << " => " << maxX << ", " << maxY
                     << "]";
      FML_LOG(ERROR) << "dl_bounds["                               //
                     << bounds->fLeft << ", " << bounds->fTop      //
                     << " => "                                     //
                     << bounds->fRight << ", " << bounds->fBottom  //
                     << "]";
    } else if (bounds) {
      showBoundsOverflow(info, i_bounds, tolerance, minX, minY, maxX, maxY);
    }
    ASSERT_EQ(pixels_oob, 0) << info;
    ASSERT_EQ(pixels_different, 0) << info;
  }

  static void showBoundsOverflow(std::string info,
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
    int pixWidth = pix_size.width();
    int pixHeight = pix_size.height();
    int worst_pad_x = std::max(pad_left, pad_right);
    int worst_pad_y = std::max(pad_top, pad_bottom);
    if (tolerance->overflows(pix_bounds, worst_pad_x, worst_pad_y)) {
      FML_LOG(ERROR) << "Overflow for " << info;
      FML_LOG(ERROR) << "pix bounds["                        //
                     << pixLeft << ", " << pixTop << " => "  //
                     << pixRight << ", " << pixBottom        //
                     << "]";
      FML_LOG(ERROR) << "dl_bounds["                             //
                     << bounds.fLeft << ", " << bounds.fTop      //
                     << " => "                                   //
                     << bounds.fRight << ", " << bounds.fBottom  //
                     << "]";
      FML_LOG(ERROR) << "Bounds overflowed by up to "             //
                     << worst_pad_x << ", " << worst_pad_y        //
                     << " (" << (worst_pad_x * 100.0 / pixWidth)  //
                     << "%, " << (worst_pad_y * 100.0 / pixHeight) << "%)";
      int pix_area = pix_size.area();
      int dl_area = bounds.width() * bounds.height();
      FML_LOG(ERROR) << "Total overflow area: " << (dl_area - pix_area)  //
                     << " (+" << (dl_area * 100.0 / pix_area - 100.0) << "%)";
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

  static sk_sp<SkTextBlob> MakeTextBlob(std::string string,
                                        SkScalar font_height) {
    SkFont font(SkTypeface::MakeFromName("ahem", SkFontStyle::Normal()),
                font_height);
    return SkTextBlob::MakeFromText(string.c_str(), string.size(), font,
                                    SkTextEncoding::kUTF8);
  }
};

BoundsTolerance CanvasCompareTester::DefaultTolerance =
    BoundsTolerance().addAbsolutePadding(1, 1);

const sk_sp<SkImage> CanvasCompareTester::kTestImage = makeTestImage();
const DlImageColorSource CanvasCompareTester::kTestImageColorSource(
    kTestImage,
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawPaint();
          },
          kDrawPaintFlags));
}

TEST_F(DisplayListCanvas, DrawColor) {
  // We use a non-opaque color to avoid obliterating any backdrop filter output
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawColor(0x7FFF00FF);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawColor(0x7FFF00FF, DlBlendMode::kSrcOver);
          },
          kDrawColorFlags));
}

TEST_F(DisplayListCanvas, DrawDiagonalLines) {
  SkPoint p1 = SkPoint::Make(kRenderLeft, kRenderTop);
  SkPoint p2 = SkPoint::Make(kRenderRight, kRenderBottom);
  SkPoint p3 = SkPoint::Make(kRenderLeft, kRenderBottom);
  SkPoint p4 = SkPoint::Make(kRenderRight, kRenderTop);

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
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawLine(p1, p2);
            builder.drawLine(p3, p4);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawLine(p1, p2);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawLine(p1, p2);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawRect(kRenderBounds.makeOffset(0.5, 0.5));
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawOval(rect);
          },
          kDrawOvalFlags));
}

TEST_F(DisplayListCanvas, DrawCircle) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawCircle(kTestCenter, kRenderRadius, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawCircle(kTestCenter, kRenderRadius);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawRRect(rrect);
          },
          kDrawRRectFlags));
}

TEST_F(DisplayListCanvas, DrawDRRect) {
  SkRRect outer = SkRRect::MakeRectXY(kRenderBounds, kRenderCornerRadius,
                                      kRenderCornerRadius);
  SkRect innerBounds = kRenderBounds.makeInset(30.0, 30.0);
  SkRRect inner = SkRRect::MakeRectXY(innerBounds, kRenderCornerRadius,
                                      kRenderCornerRadius);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawDRRect(outer, inner, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawDRRect(outer, inner);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawPath(path);
          },
          kDrawPathFlags));
}

TEST_F(DisplayListCanvas, DrawArc) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawArc(kRenderBounds, 60, 330, false, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawArc(kRenderBounds, 60, 330, false);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawArc(kRenderBounds, 60, 360 - 12, true);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawPoints(SkCanvas::kPoints_PointMode, count, points);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawPoints(SkCanvas::kLines_PointMode, count, points);
          },
          kDrawPointsAsLinesFlags));
}

TEST_F(DisplayListCanvas, DrawPointsAsPolygon) {
  const SkPoint points1[] = {
      // RenderBounds box with a diagonal
      SkPoint::Make(kRenderLeft, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderBottom),
      SkPoint::Make(kRenderLeft, kRenderBottom),
      SkPoint::Make(kRenderLeft, kRenderTop),
      SkPoint::Make(kRenderRight, kRenderBottom),
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawPoints(SkCanvas::kPolygon_PointMode, count1, points1);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawVertices(vertices, DlBlendMode::kSrcOver);
          },
          kDrawVerticesFlags)
          .set_draw_vertices());
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
          [=](DisplayListBuilder& builder) {  //
            if (builder.getColorSource() == nullptr) {
              builder.setColorSource(
                  &CanvasCompareTester::kTestImageColorSource);
            }
            builder.drawVertices(vertices, DlBlendMode::kSrcOver);
          },
          kDrawVerticesFlags)
          .set_draw_vertices());
}

TEST_F(DisplayListCanvas, DrawImageNearest) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {         //
            canvas->drawImage(CanvasCompareTester::kTestImage,  //
                              kRenderLeft, kRenderTop,
                              ToSk(DlImageSampling::kNearestNeighbor), &paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawImage(DlImage::Make(CanvasCompareTester::kTestImage),
                              SkPoint::Make(kRenderLeft, kRenderTop),
                              DlImageSampling::kNearestNeighbor, true);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawImage(DlImage::Make(CanvasCompareTester::kTestImage),
                              SkPoint::Make(kRenderLeft, kRenderTop),
                              DlImageSampling::kNearestNeighbor, false);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawImage(DlImage::Make(CanvasCompareTester::kTestImage),
                              SkPoint::Make(kRenderLeft, kRenderTop),
                              DlImageSampling::kLinear, true);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawImageRect(
                DlImage::Make(CanvasCompareTester::kTestImage), src, dst,
                DlImageSampling::kNearestNeighbor, true);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawImageRect(
                DlImage::Make(CanvasCompareTester::kTestImage), src, dst,
                DlImageSampling::kNearestNeighbor, false);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawImageRect(
                DlImage::Make(CanvasCompareTester::kTestImage), src, dst,
                DlImageSampling::kLinear, true);
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
          [=](DisplayListBuilder& builder) {
            builder.drawImageNine(DlImage::Make(image), src, dst,
                                  DlFilterMode::kNearest, true);
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
          [=](DisplayListBuilder& builder) {
            builder.drawImageNine(DlImage::Make(image), src, dst,
                                  DlFilterMode::kNearest, false);
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
          [=](DisplayListBuilder& builder) {
            builder.drawImageNine(DlImage::Make(image), src, dst,
                                  DlFilterMode::kLinear, true);
          },
          kDrawImageNineWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageLatticeNearest) {
  const SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  const int divX[] = {
      kRenderWidth * 1 / 4,
      kRenderWidth * 2 / 4,
      kRenderWidth * 3 / 4,
  };
  const int divY[] = {
      kRenderHeight * 1 / 4,
      kRenderHeight * 2 / 4,
      kRenderHeight * 3 / 4,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageLattice(image.get(), lattice, dst,
                                     SkFilterMode::kNearest, &paint);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageLattice(DlImage::Make(image), lattice, dst,
                                     DlFilterMode::kNearest, true);
          },
          kDrawImageLatticeWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageLatticeNearestNoPaint) {
  const SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  const int divX[] = {
      kRenderWidth * 1 / 4,
      kRenderWidth * 2 / 4,
      kRenderWidth * 3 / 4,
  };
  const int divY[] = {
      kRenderHeight * 1 / 4,
      kRenderHeight * 2 / 4,
      kRenderHeight * 3 / 4,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageLattice(image.get(), lattice, dst,
                                     SkFilterMode::kNearest, nullptr);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageLattice(DlImage::Make(image), lattice, dst,
                                     DlFilterMode::kNearest, false);
          },
          kDrawImageLatticeFlags));
}

TEST_F(DisplayListCanvas, DrawImageLatticeLinear) {
  const SkRect dst = kRenderBounds.makeInset(10.5, 10.5);
  const int divX[] = {
      kRenderWidth / 4,
      kRenderWidth / 2,
      kRenderWidth * 3 / 4,
  };
  const int divY[] = {
      kRenderHeight / 4,
      kRenderHeight / 2,
      kRenderHeight * 3 / 4,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageLattice(image.get(), lattice, dst,
                                     SkFilterMode::kLinear, &paint);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageLattice(DlImage::Make(image), lattice, dst,
                                     DlFilterMode::kLinear, true);
          },
          kDrawImageLatticeWithPaintFlags));
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
  const DlColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  const DlImageSampling sampling = DlImageSampling::kNearestNeighbor;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors);
            canvas->drawAtlas(image.get(), xform, tex, sk_colors, 4,
                              SkBlendMode::kSrcOver, ToSk(sampling), nullptr,
                              &paint);
          },
          [=](DisplayListBuilder& builder) {
            const DlColor* dl_colors = reinterpret_cast<const DlColor*>(colors);
            builder.drawAtlas(DlImage::Make(image), xform, tex, dl_colors, 4,
                              DlBlendMode::kSrcOver, sampling, nullptr, true);
          },
          kDrawAtlasWithPaintFlags)
          .set_draw_atlas());
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
  const DlColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  const DlImageSampling sampling = DlImageSampling::kNearestNeighbor;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors);
            canvas->drawAtlas(image.get(), xform, tex, sk_colors, 4,
                              SkBlendMode::kSrcOver, ToSk(sampling),  //
                              nullptr, nullptr);
          },
          [=](DisplayListBuilder& builder) {
            const DlColor* dl_colors = reinterpret_cast<const DlColor*>(colors);
            builder.drawAtlas(DlImage::Make(image), xform, tex, dl_colors, 4,
                              DlBlendMode::kSrcOver, sampling,  //
                              nullptr, false);
          },
          kDrawAtlasFlags)
          .set_draw_atlas());
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
  const DlColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::kTestImage;
  const DlImageSampling sampling = DlImageSampling::kLinear;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors);
            canvas->drawAtlas(image.get(), xform, tex, sk_colors, 2,  //
                              SkBlendMode::kSrcOver, ToSk(sampling), nullptr,
                              &paint);
          },
          [=](DisplayListBuilder& builder) {
            const DlColor* dl_colors = reinterpret_cast<const DlColor*>(colors);
            builder.drawAtlas(DlImage::Make(image), xform, tex, dl_colors, 2,
                              DlBlendMode::kSrcOver, sampling, nullptr, true);
          },
          kDrawAtlasWithPaintFlags)
          .set_draw_atlas());
}

sk_sp<SkPicture> makeTestPicture() {
  SkPictureRecorder recorder;
  SkCanvas* cv = recorder.beginRecording(kRenderBounds);
  SkPaint p;
  p.setStyle(SkPaint::kFill_Style);
  p.setColor(SK_ColorRED);
  cv->drawRect({kRenderLeft, kRenderTop, kRenderCenterX, kRenderCenterY}, p);
  p.setColor(SK_ColorBLUE);
  cv->drawRect({kRenderCenterX, kRenderTop, kRenderRight, kRenderCenterY}, p);
  p.setColor(SK_ColorGREEN);
  cv->drawRect({kRenderLeft, kRenderCenterY, kRenderCenterX, kRenderBottom}, p);
  p.setColor(SK_ColorYELLOW);
  cv->drawRect({kRenderCenterX, kRenderCenterY, kRenderRight, kRenderBottom},
               p);
  return recorder.finishRecordingAsPicture();
}

TEST_F(DisplayListCanvas, DrawPicture) {
  sk_sp<SkPicture> picture = makeTestPicture();
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawPicture(picture, nullptr, nullptr);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawPicture(picture, nullptr, false);
          },
          kDrawPictureFlags));
}

TEST_F(DisplayListCanvas, DrawPictureWithMatrix) {
  sk_sp<SkPicture> picture = makeTestPicture();
  SkMatrix matrix = SkMatrix::Scale(0.9, 0.9);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawPicture(picture, &matrix, nullptr);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawPicture(picture, &matrix, false);
          },
          kDrawPictureFlags));
}

TEST_F(DisplayListCanvas, DrawPictureWithPaint) {
  sk_sp<SkPicture> picture = makeTestPicture();
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawPicture(picture, nullptr, &paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawPicture(picture, nullptr, true);
          },
          kDrawPictureWithPaintFlags));
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawDisplayList(display_list);
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
  SkScalar RenderY1_3 = kRenderTop + kRenderHeight * 0.3;
  SkScalar RenderY2_3 = kRenderTop + kRenderHeight * 0.6;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawTextBlob(blob, kRenderLeft, RenderY1_3, paint);
            canvas->drawTextBlob(blob, kRenderLeft, RenderY2_3, paint);
            canvas->drawTextBlob(blob, kRenderLeft, kRenderBottom, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawTextBlob(blob, kRenderLeft, RenderY1_3);
            builder.drawTextBlob(blob, kRenderLeft, RenderY2_3);
            builder.drawTextBlob(blob, kRenderLeft, kRenderBottom);
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawShadow(path, color, elevation, false, 1.0);
          },
          kDrawShadowFlags)
          .set_draw_shadows(),
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawShadow(path, color, elevation, true, 1.0);
          },
          kDrawShadowFlags)
          .set_draw_shadows(),
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
          [=](DisplayListBuilder& builder) {  //
            builder.drawShadow(path, color, elevation, false, 1.5);
          },
          kDrawShadowFlags)
          .set_draw_shadows(),
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

}  // namespace testing
}  // namespace flutter

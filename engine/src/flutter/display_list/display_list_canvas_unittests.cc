// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/display_list/display_list_canvas_recorder.h"
#include "flutter/display_list/display_list_flags.h"
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

constexpr int TestWidth = 200;
constexpr int TestHeight = 200;
constexpr int RenderWidth = 100;
constexpr int RenderHeight = 100;
constexpr int RenderHalfWidth = 50;
constexpr int RenderHalfHeight = 50;
constexpr int RenderLeft = (TestWidth - RenderWidth) / 2;
constexpr int RenderTop = (TestHeight - RenderHeight) / 2;
constexpr int RenderRight = RenderLeft + RenderWidth;
constexpr int RenderBottom = RenderTop + RenderHeight;
constexpr int RenderCenterX = (RenderLeft + RenderRight) / 2;
constexpr int RenderCenterY = (RenderTop + RenderBottom) / 2;
constexpr SkScalar RenderRadius = std::min(RenderWidth, RenderHeight) / 2.0;
constexpr SkScalar RenderCornerRadius = RenderRadius / 5.0;

constexpr SkPoint TestCenter = SkPoint::Make(TestWidth / 2, TestHeight / 2);
constexpr SkRect TestBounds = SkRect::MakeWH(TestWidth, TestHeight);
constexpr SkRect RenderBounds =
    SkRect::MakeLTRB(RenderLeft, RenderTop, RenderRight, RenderBottom);

// The tests try 3 miter limit values, 0.0, 4.0 (the default), and 10.0
// These values will allow us to construct a diamond that spans the
// width or height of the render box and still show the miter for 4.0
// and 10.0.
// These values were discovered by drawing a diamond path in Skia fiddle
// and then playing with the cross-axis size until the miter was about
// as large as it could get before it got cut off.

// The X offsets which will be used for tall vertical diamonds are
// expressed in terms of the rendering height to obtain the proper angle
constexpr SkScalar MiterExtremeDiamondOffsetX = RenderHeight * 0.04;
constexpr SkScalar Miter10DiamondOffsetX = RenderHeight * 0.051;
constexpr SkScalar Miter4DiamondOffsetX = RenderHeight * 0.14;

// The Y offsets which will be used for long horizontal diamonds are
// expressed in terms of the rendering width to obtain the proper angle
constexpr SkScalar MiterExtremeDiamondOffsetY = RenderWidth * 0.04;
constexpr SkScalar Miter10DiamondOffsetY = RenderWidth * 0.051;
constexpr SkScalar Miter4DiamondOffsetY = RenderWidth * 0.14;

// Render 3 vertical and horizontal diamonds each
// designed to break at the tested miter limits
// 0.0, 4.0 and 10.0
// Center is biased by 0.5 to include more pixel centers in the
// thin miters
constexpr SkScalar x_off_0 = RenderCenterX + 0.5;
constexpr SkScalar x_off_l1 = x_off_0 - Miter4DiamondOffsetX;
constexpr SkScalar x_off_l2 = x_off_l1 - Miter10DiamondOffsetX;
constexpr SkScalar x_off_l3 = x_off_l2 - Miter10DiamondOffsetX;
constexpr SkScalar x_off_r1 = x_off_0 + Miter4DiamondOffsetX;
constexpr SkScalar x_off_r2 = x_off_r1 + MiterExtremeDiamondOffsetX;
constexpr SkScalar x_off_r3 = x_off_r2 + MiterExtremeDiamondOffsetX;
constexpr SkPoint VerticalMiterDiamondPoints[] = {
    // Vertical diamonds:
    //  M10   M4  Mextreme
    //   /\   /|\   /\       top of RenderBounds
    //  /  \ / | \ /  \              to
    // <----X--+--X---->         RenderCenter
    //  \  / \ | / \  /              to
    //   \/   \|/   \/      bottom of RenderBounds
    // clang-format off
    SkPoint::Make(x_off_l3, RenderCenterY),
    SkPoint::Make(x_off_l2, RenderTop),
    SkPoint::Make(x_off_l1, RenderCenterY),
    SkPoint::Make(x_off_0,  RenderTop),
    SkPoint::Make(x_off_r1, RenderCenterY),
    SkPoint::Make(x_off_r2, RenderTop),
    SkPoint::Make(x_off_r3, RenderCenterY),
    SkPoint::Make(x_off_r2, RenderBottom),
    SkPoint::Make(x_off_r1, RenderCenterY),
    SkPoint::Make(x_off_0,  RenderBottom),
    SkPoint::Make(x_off_l1, RenderCenterY),
    SkPoint::Make(x_off_l2, RenderBottom),
    SkPoint::Make(x_off_l3, RenderCenterY),
    // clang-format on
};
const int VerticalMiterDiamondPointCount =
    sizeof(VerticalMiterDiamondPoints) / sizeof(VerticalMiterDiamondPoints[0]);

constexpr SkScalar y_off_0 = RenderCenterY + 0.5;
constexpr SkScalar y_off_u1 = x_off_0 - Miter4DiamondOffsetY;
constexpr SkScalar y_off_u2 = y_off_u1 - Miter10DiamondOffsetY;
constexpr SkScalar y_off_u3 = y_off_u2 - Miter10DiamondOffsetY;
constexpr SkScalar y_off_d1 = x_off_0 + Miter4DiamondOffsetY;
constexpr SkScalar y_off_d2 = y_off_d1 + MiterExtremeDiamondOffsetY;
constexpr SkScalar y_off_d3 = y_off_d2 + MiterExtremeDiamondOffsetY;
const SkPoint HorizontalMiterDiamondPoints[] = {
    // Horizontal diamonds
    // Same configuration as Vertical diamonds above but
    // rotated 90 degrees
    // clang-format off
    SkPoint::Make(RenderCenterX, y_off_u3),
    SkPoint::Make(RenderLeft,    y_off_u2),
    SkPoint::Make(RenderCenterX, y_off_u1),
    SkPoint::Make(RenderLeft,    y_off_0),
    SkPoint::Make(RenderCenterX, y_off_d1),
    SkPoint::Make(RenderLeft,    y_off_d2),
    SkPoint::Make(RenderCenterX, y_off_d3),
    SkPoint::Make(RenderRight,   y_off_d2),
    SkPoint::Make(RenderCenterX, y_off_d1),
    SkPoint::Make(RenderRight,   y_off_0),
    SkPoint::Make(RenderCenterX, y_off_u1),
    SkPoint::Make(RenderRight,   y_off_u2),
    SkPoint::Make(RenderCenterX, y_off_u3),
    // clang-format on
};
const int HorizontalMiterDiamondPointCount =
    (sizeof(HorizontalMiterDiamondPoints) /
     sizeof(HorizontalMiterDiamondPoints[0]));

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
    return RenderEnvironment(SkImageInfo::Make({1, 1}, kRGB_565_SkColorType,
                                               kOpaque_SkAlphaType, nullptr));
  }

  static RenderEnvironment MakeN32() {
    return RenderEnvironment(SkImageInfo::MakeN32Premul(1, 1));
  }

  std::unique_ptr<RenderSurface> MakeSurface(
      const SkColor bg = SK_ColorTRANSPARENT,
      int width = TestWidth,
      int height = TestHeight) const {
    sk_sp<SkSurface> surface =
        SkSurface::MakeRaster(info_.makeWH(width, height));
    surface->getCanvas()->clear(bg);
    return std::make_unique<RenderSurface>(surface);
  }

  void init_ref(CvRenderer& cv_renderer, SkColor bg = SK_ColorTRANSPARENT) {
    init_ref([=](SkCanvas*, SkPaint&) {}, cv_renderer, bg);
  }

  void init_ref(CvSetup& cv_setup,
                CvRenderer& cv_renderer,
                SkColor bg = SK_ColorTRANSPARENT) {
    ref_canvas()->clear(bg);
    cv_setup(ref_canvas(), ref_paint_);
    ref_matrix_ = ref_canvas()->getTotalMatrix();
    ref_clip_ = ref_canvas()->getDeviceClipBounds();
    cv_renderer(ref_canvas(), ref_paint_);
    ref_pixmap_ = ref_surface_->pixmap();
  }

  const SkImageInfo& info() const { return info_; }
  SkCanvas* ref_canvas() { return ref_surface_->canvas(); }
  const SkPaint& ref_paint() const { return ref_paint_; }
  const SkMatrix& ref_matrix() const { return ref_matrix_; }
  const SkIRect& ref_clip_bounds() const { return ref_clip_; }
  const SkPixmap* ref_pixmap() const { return ref_pixmap_; }

 private:
  explicit RenderEnvironment(const SkImageInfo& info) : info_(info) {
    ref_surface_ = MakeSurface();
  }

  const SkImageInfo info_;

  SkPaint ref_paint_;
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
                    const SkPaint& paint,
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
    const SkPaint& ref_paint = env.ref_paint();
    if (flags_.applies_anti_alias() &&  //
        ref_paint.isAntiAlias() != paint.isAntiAlias()) {
      return false;
    }
    if (flags_.applies_dither() &&  //
        ref_paint.isDither() != paint.isDither()) {
      return false;
    }
    if (flags_.applies_color() &&  //
        ref_paint.getColor() != paint.getColor()) {
      return false;
    }
    if (flags_.applies_alpha() &&  //
        ref_paint.getAlpha() != paint.getAlpha()) {
      return false;
    }
    if (flags_.applies_blend() &&  //
        ref_paint.getBlender() != paint.getBlender()) {
      return false;
    }
    if (flags_.applies_color_filter() &&  //
        ref_paint.getColorFilter() != paint.getColorFilter()) {
      return false;
    }
    if (flags_.applies_mask_filter() &&  //
        ref_paint.getMaskFilter() != paint.getMaskFilter()) {
      return false;
    }
    if (flags_.applies_image_filter() &&  //
        ref_paint.getImageFilter() != paint.getImageFilter()) {
      return false;
    }
    if (flags_.applies_shader() &&  //
        ref_paint.getShader() != paint.getShader()) {
      return false;
    }
    DisplayListSpecialGeometryFlags geo_flags =
        flags_.WithPathEffect(paint.refPathEffect());
    if (flags_.applies_path_effect() &&  //
        ref_paint.getPathEffect() != paint.getPathEffect()) {
      SkPathEffect::DashInfo info;
      if (paint.getPathEffect()->asADash(&info) !=
          SkPathEffect::kDash_DashType) {
        return false;
      }
      if (!ignores_dashes()) {
        return false;
      }
    }
    bool is_stroked = flags_.is_stroked(ref_paint.getStyle());
    if (flags_.is_stroked(paint.getStyle()) != is_stroked) {
      return false;
    }
    if (!is_stroked) {
      return true;
    }
    if (ref_paint.getStrokeWidth() != paint.getStrokeWidth()) {
      return false;
    }
    if (geo_flags.may_have_end_caps() &&  //
        getCap(ref_paint, geo_flags) != getCap(paint, geo_flags)) {
      return false;
    }
    if (geo_flags.may_have_joins()) {
      if (ref_paint.getStrokeJoin() != paint.getStrokeJoin()) {
        return false;
      }
      if (ref_paint.getStrokeJoin() == SkPaint::kMiter_Join) {
        SkScalar ref_miter = ref_paint.getStrokeMiter();
        SkScalar test_miter = paint.getStrokeMiter();
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

  SkPaint::Cap getCap(const SkPaint& paint,
                      DisplayListSpecialGeometryFlags geo_flags) const {
    SkPaint::Cap cap = paint.getStrokeCap();
    if (geo_flags.butt_cap_becomes_square() && cap == SkPaint::kButt_Cap) {
      return SkPaint::kSquare_Cap;
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
    DisplayListSpecialGeometryFlags geo_flags =
        flags_.WithPathEffect(paint.refPathEffect());
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
                       false) {}

  CaseParameters(std::string info,
                 CvSetup cv_setup,
                 DlRenderer dl_setup,
                 CvRenderer cv_restore,
                 DlRenderer dl_restore,
                 SkColor bg,
                 bool has_diff_clip,
                 bool has_mutating_save_layer)
      : info_(info),
        bg_(bg),
        cv_setup_(cv_setup),
        dl_setup_(dl_setup),
        cv_restore_(cv_restore),
        dl_restore_(dl_restore),
        has_diff_clip_(has_diff_clip),
        has_mutating_save_layer_(has_mutating_save_layer) {}

  CaseParameters with_restore(CvRenderer cv_restore,
                              DlRenderer dl_restore,
                              bool mutating_layer) {
    return CaseParameters(info_, cv_setup_, dl_setup_, cv_restore, dl_restore,
                          bg_, has_diff_clip_, mutating_layer);
  }

  CaseParameters with_bg(SkColor bg) {
    return CaseParameters(info_, cv_setup_, dl_setup_, cv_restore_, dl_restore_,
                          bg, has_diff_clip_, has_mutating_save_layer_);
  }

  CaseParameters with_diff_clip() {
    return CaseParameters(info_, cv_setup_, dl_setup_, cv_restore_, dl_restore_,
                          bg_, true, has_mutating_save_layer_);
  }

  std::string info() const { return info_; }
  SkColor bg() const { return bg_; }
  bool has_diff_clip() const { return has_diff_clip_; }
  bool has_mutating_save_layer() const { return has_mutating_save_layer_; }

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
  const SkColor bg_;
  const CvSetup cv_setup_;
  const DlRenderer dl_setup_;
  const CvRenderer cv_restore_;
  const DlRenderer dl_restore_;
  const bool has_diff_clip_;
  const bool has_mutating_save_layer_;
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
    SkRect clip = SkRect::MakeXYWH(RenderCenterX - 1, RenderCenterY - 1, 2, 2);
    SkRect rect = SkRect::MakeXYWH(RenderCenterX, RenderCenterY, 10, 10);
    SkColor alpha_layer_color = SkColorSetARGB(0x7f, 0x00, 0xff, 0xff);
    SkColor default_color = SkPaint().getColor();
    CvRenderer cv_restore = [=](SkCanvas* cv, const SkPaint& p) {
      // Draw another primitive to disable peephole optimizations
      cv->drawRect(RenderBounds.makeOffset(500, 500), p);
      cv->restore();
    };
    DlRenderer dl_restore = [=](DisplayListBuilder& b) {
      // Draw another primitive to disable peephole optimizations
      b.drawRect(RenderBounds.makeOffset(500, 500));
      b.restore();
    };
    SkRect layer_bounds = RenderBounds.makeInset(15, 15);
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
                     b.setBlendMode(SkBlendMode::kClear);
                     b.drawRect(rect);
                     b.setBlendMode(SkBlendMode::kSrcOver);
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
                   .with_restore(cv_restore, dl_restore, false));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "saveLayer no paint, with bounds",
                   [=](SkCanvas* cv, SkPaint& p) {  //
                     cv->saveLayer(layer_bounds, nullptr);
                   },
                   [=](DisplayListBuilder& b) {  //
                     b.saveLayer(&layer_bounds, false);
                   })
                   .with_restore(cv_restore, dl_restore, true));
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
                   .with_restore(cv_restore, dl_restore, true));
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
                   .with_restore(cv_restore, dl_restore, true));

    {
      // clang-format off
      constexpr float rotate_alpha_color_matrix[20] = {
          0, 1, 0,  0 , 0,
          0, 0, 1,  0 , 0,
          1, 0, 0,  0 , 0,
          0, 0, 0, 0.5, 0,
      };
      // clang-format on
      sk_sp<SkColorFilter> filter =
          SkColorFilters::Matrix(rotate_alpha_color_matrix);
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ColorFilter, no bounds",
                       [=](SkCanvas* cv, SkPaint& p) {
                         SkPaint save_p;
                         save_p.setColorFilter(filter);
                         cv->saveLayer(nullptr, &save_p);
                         p.setStrokeWidth(5.0);
                       },
                       [=](DisplayListBuilder& b) {
                         b.setColorFilter(filter);
                         b.saveLayer(nullptr, true);
                         b.setColorFilter(nullptr);
                         b.setStrokeWidth(5.0);
                       })
                       .with_restore(cv_restore, dl_restore, true));
      }
      EXPECT_TRUE(filter->unique())
          << "saveLayer ColorFilter, no bounds Cleanup";
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ColorFilter and bounds",
                       [=](SkCanvas* cv, SkPaint& p) {
                         SkPaint save_p;
                         save_p.setColorFilter(filter);
                         cv->saveLayer(RenderBounds, &save_p);
                         p.setStrokeWidth(5.0);
                       },
                       [=](DisplayListBuilder& b) {
                         b.setColorFilter(filter);
                         b.saveLayer(&RenderBounds, true);
                         b.setColorFilter(nullptr);
                         b.setStrokeWidth(5.0);
                       })
                       .with_restore(cv_restore, dl_restore, true));
      }
      EXPECT_TRUE(filter->unique())
          << "saveLayer ColorFilter and bounds Cleanup";
    }
    {
      sk_sp<SkImageFilter> filter = SkImageFilters::Arithmetic(
          0.1, 0.1, 0.1, 0.25, true, nullptr, nullptr);
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ImageFilter, no bounds",
                       [=](SkCanvas* cv, SkPaint& p) {
                         SkPaint save_p;
                         save_p.setImageFilter(filter);
                         cv->saveLayer(nullptr, &save_p);
                         p.setStrokeWidth(5.0);
                       },
                       [=](DisplayListBuilder& b) {
                         b.setImageFilter(filter);
                         b.saveLayer(nullptr, true);
                         b.setImageFilter(nullptr);
                         b.setStrokeWidth(5.0);
                       })
                       .with_restore(cv_restore, dl_restore, true));
      }
      EXPECT_TRUE(filter->unique())
          << "saveLayer ImageFilter, no bounds Cleanup";
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "saveLayer ImageFilter and bounds",
                       [=](SkCanvas* cv, SkPaint& p) {
                         SkPaint save_p;
                         save_p.setImageFilter(filter);
                         cv->saveLayer(RenderBounds, &save_p);
                         p.setStrokeWidth(5.0);
                       },
                       [=](DisplayListBuilder& b) {
                         b.setImageFilter(filter);
                         b.saveLayer(&RenderBounds, true);
                         b.setImageFilter(nullptr);
                         b.setStrokeWidth(5.0);
                       })
                       .with_restore(cv_restore, dl_restore, true));
      }
      EXPECT_TRUE(filter->unique())
          << "saveLayer ImageFilter and bounds Cleanup";
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
      aa_env.init_ref(cv_aa_setup, testP.cv_renderer());
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
      SkColor dither_bg = SK_ColorBLACK;
      CvSetup cv_dither_setup = [=](SkCanvas*, SkPaint& p) {
        p.setShader(testImageShader);
        p.setAlpha(0xf0);
        p.setStrokeWidth(5.0);
      };
      DlRenderer dl_dither_setup = [=](DisplayListBuilder& b) {
        b.setShader(testImageShader);
        b.setColor(SkColor(0xf0000000));
        b.setStrokeWidth(5.0);
      };
      dither_env.init_ref(cv_dither_setup, testP.cv_renderer(), dither_bg);
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
    EXPECT_TRUE(testImageShader->unique()) << "Dither Cleanup";

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
      SkColor blendableColor = SkColorSetARGB(0x7f, 0x00, 0xff, 0xff);
      SkColor bg = SK_ColorWHITE;

      RenderWith(testP, env, tolerance,
                 CaseParameters(
                     "Blend == SrcIn",
                     [=](SkCanvas*, SkPaint& p) {
                       p.setBlendMode(SkBlendMode::kSrcIn);
                       p.setColor(blendableColor);
                     },
                     [=](DisplayListBuilder& b) {
                       b.setBlendMode(SkBlendMode::kSrcIn);
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
                       b.setBlendMode(SkBlendMode::kDstIn);
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
        p.setShader(testImageShader);
        p.setStrokeWidth(5.0);
      };
      DlRenderer dl_blur_setup = [=](DisplayListBuilder& b) {
        b.setShader(testImageShader);
        b.setStrokeWidth(5.0);
      };
      blur_env.init_ref(cv_blur_setup, testP.cv_renderer());
      sk_sp<SkImageFilter> filter =
          SkImageFilters::Blur(5.0, 5.0, SkTileMode::kDecal, nullptr, nullptr);
      BoundsTolerance blur5Tolerance = tolerance.addBoundsPadding(4, 4);
      {
        RenderWith(testP, blur_env, blur5Tolerance,
                   CaseParameters(
                       "ImageFilter == Decal Blur 5",
                       [=](SkCanvas* cv, SkPaint& p) {
                         cv_blur_setup(cv, p);
                         p.setImageFilter(filter);
                       },
                       [=](DisplayListBuilder& b) {
                         dl_blur_setup(b);
                         b.setImageFilter(filter);
                       }));
      }
      EXPECT_TRUE(filter->unique()) << "ImageFilter Cleanup";
      filter =
          SkImageFilters::Blur(5.0, 5.0, SkTileMode::kClamp, nullptr, nullptr);
      {
        RenderWith(testP, blur_env, blur5Tolerance,
                   CaseParameters(
                       "ImageFilter == Clamp Blur 5",
                       [=](SkCanvas* cv, SkPaint& p) {
                         cv_blur_setup(cv, p);
                         p.setImageFilter(filter);
                       },
                       [=](DisplayListBuilder& b) {
                         dl_blur_setup(b);
                         b.setImageFilter(filter);
                       }));
      }
      EXPECT_TRUE(filter->unique()) << "ImageFilter Cleanup";
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
      sk_sp<SkColorFilter> filter = SkColorFilters::Matrix(rotate_color_matrix);
      {
        SkColor bg = SK_ColorWHITE;
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "ColorFilter == RotateRGB",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setColor(SK_ColorYELLOW);
                         p.setColorFilter(filter);
                       },
                       [=](DisplayListBuilder& b) {
                         b.setColor(SK_ColorYELLOW);
                         b.setColorFilter(filter);
                       })
                       .with_bg(bg));
      }
      EXPECT_TRUE(filter->unique()) << "ColorFilter == RotateRGB Cleanup";
      filter = SkColorFilters::Matrix(invert_color_matrix);
      {
        SkColor bg = SK_ColorWHITE;
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "ColorFilter == Invert",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setColor(SK_ColorYELLOW);
                         p.setColorFilter(filter);
                       },
                       [=](DisplayListBuilder& b) {
                         b.setColor(SK_ColorYELLOW);
                         b.setInvertColors(true);
                       })
                       .with_bg(bg));
      }
      EXPECT_TRUE(filter->unique()) << "ColorFilter == Invert Cleanup";
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
                         b.setPathEffect(effect);
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
                         b.setPathEffect(effect);
                       }));
      }
      EXPECT_TRUE(testP.is_draw_text_blob() || effect->unique())
          << "PathEffect == Discrete-2-3 Cleanup";
    }

    {
      sk_sp<SkMaskFilter> filter =
          SkMaskFilter::MakeBlur(kNormal_SkBlurStyle, 5.0);
      BoundsTolerance blur5Tolerance = tolerance.addBoundsPadding(4, 4);
      {
        // Stroked primitives need some non-trivial stroke size to be blurred
        RenderWith(testP, env, blur5Tolerance,
                   CaseParameters(
                       "MaskFilter == Blur 5",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setMaskFilter(filter);
                       },
                       [=](DisplayListBuilder& b) {
                         b.setStrokeWidth(5.0);
                         b.setMaskFilter(filter);
                       }));
      }
      EXPECT_TRUE(testP.is_draw_text_blob() || filter->unique())
          << "MaskFilter == Blur 5 Cleanup";
      {
        RenderWith(testP, env, blur5Tolerance,
                   CaseParameters(
                       "MaskFilter == Blur(Normal, 5.0)",
                       [=](SkCanvas*, SkPaint& p) {
                         p.setStrokeWidth(5.0);
                         p.setMaskFilter(filter);
                       },
                       [=](DisplayListBuilder& b) {
                         b.setStrokeWidth(5.0);
                         b.setMaskBlurFilter(kNormal_SkBlurStyle, 5.0);
                       }));
      }
      EXPECT_TRUE(testP.is_draw_text_blob() || filter->unique())
          << "MaskFilter == Blur(Normal, 5.0) Cleanup";
    }

    {
      SkPoint end_points[] = {
          SkPoint::Make(RenderBounds.fLeft, RenderBounds.fTop),
          SkPoint::Make(RenderBounds.fRight, RenderBounds.fBottom),
      };
      SkColor colors[] = {
          SK_ColorGREEN,
          SkColorSetA(SK_ColorYELLOW, 0x7f),
          SK_ColorBLUE,
      };
      float stops[] = {
          0.0,
          0.5,
          1.0,
      };
      sk_sp<SkShader> shader = SkGradientShader::MakeLinear(
          end_points, colors, stops, 3, SkTileMode::kMirror, 0, nullptr);
      {
        RenderWith(testP, env, tolerance,
                   CaseParameters(
                       "LinearGradient GYB",
                       [=](SkCanvas*, SkPaint& p) { p.setShader(shader); },
                       [=](DisplayListBuilder& b) { b.setShader(shader); }));
      }
      EXPECT_TRUE(shader->unique()) << "LinearGradient GYB Cleanup";
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
                     b.setStyle(SkPaint::kFill_Style);
                   }));
    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Stroke + defaults",
                   [=](SkCanvas*, SkPaint& p) {  //
                     p.setStyle(SkPaint::kStroke_Style);
                   },
                   [=](DisplayListBuilder& b) {  //
                     b.setStyle(SkPaint::kStroke_Style);
                   }));

    RenderWith(testP, env, tolerance,
               CaseParameters(
                   "Fill + unnecessary StrokeWidth 10",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kFill_Style);
                     p.setStrokeWidth(10.0);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(SkPaint::kFill_Style);
                     b.setStrokeWidth(10.0);
                   }));

    RenderEnvironment stroke_base_env = RenderEnvironment::MakeN32();
    CvSetup cv_stroke_setup = [=](SkCanvas*, SkPaint& p) {
      p.setStyle(SkPaint::kStroke_Style);
      p.setStrokeWidth(5.0);
    };
    stroke_base_env.init_ref(cv_stroke_setup, testP.cv_renderer());

    RenderWith(testP, stroke_base_env, tolerance,
               CaseParameters(
                   "Stroke Width 10",
                   [=](SkCanvas*, SkPaint& p) {
                     p.setStyle(SkPaint::kStroke_Style);
                     p.setStrokeWidth(10.0);
                   },
                   [=](DisplayListBuilder& b) {
                     b.setStyle(SkPaint::kStroke_Style);
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
                     b.setStyle(SkPaint::kStroke_Style);
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
                     b.setStyle(SkPaint::kStroke_Style);
                     b.setStrokeWidth(5.0);
                     b.setStrokeCap(SkPaint::kSquare_Cap);
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
                     b.setStyle(SkPaint::kStroke_Style);
                     b.setStrokeWidth(5.0);
                     b.setStrokeCap(SkPaint::kRound_Cap);
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
                     b.setStyle(SkPaint::kStroke_Style);
                     b.setStrokeWidth(5.0);
                     b.setStrokeJoin(SkPaint::kBevel_Join);
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
                     b.setStyle(SkPaint::kStroke_Style);
                     b.setStrokeWidth(5.0);
                     b.setStrokeJoin(SkPaint::kRound_Join);
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
                     b.setStyle(SkPaint::kStroke_Style);
                     b.setStrokeWidth(5.0);
                     b.setStrokeMiter(10.0);
                     b.setStrokeJoin(SkPaint::kMiter_Join);
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
                     b.setStyle(SkPaint::kStroke_Style);
                     b.setStrokeWidth(5.0);
                     b.setStrokeMiter(0.0);
                     b.setStrokeJoin(SkPaint::kMiter_Join);
                   }));

    {
      const SkScalar TestDashes1[] = {29.0, 2.0};
      const SkScalar TestDashes2[] = {17.0, 1.5};
      sk_sp<SkPathEffect> effect = SkDashPathEffect::Make(TestDashes1, 2, 0.0f);
      {
        RenderWith(testP, stroke_base_env, tolerance,
                   CaseParameters(
                       "PathEffect == Dash-29-2",
                       [=](SkCanvas*, SkPaint& p) {
                         // Need stroke style to see dashing properly
                         p.setStyle(SkPaint::kStroke_Style);
                         // Provide some non-trivial stroke size to get dashed
                         p.setStrokeWidth(5.0);
                         p.setPathEffect(effect);
                       },
                       [=](DisplayListBuilder& b) {
                         // Need stroke style to see dashing properly
                         b.setStyle(SkPaint::kStroke_Style);
                         // Provide some non-trivial stroke size to get dashed
                         b.setStrokeWidth(5.0);
                         b.setPathEffect(effect);
                       }));
      }
      EXPECT_TRUE(testP.is_draw_text_blob() || effect->unique())
          << "PathEffect == Dash-29-2 Cleanup";
      effect = SkDashPathEffect::Make(TestDashes2, 2, 0.0f);
      {
        RenderWith(testP, stroke_base_env, tolerance,
                   CaseParameters(
                       "PathEffect == Dash-17-1.5",
                       [=](SkCanvas*, SkPaint& p) {
                         // Need stroke style to see dashing properly
                         p.setStyle(SkPaint::kStroke_Style);
                         // Provide some non-trivial stroke size to get dashed
                         p.setStrokeWidth(5.0);
                         p.setPathEffect(effect);
                       },
                       [=](DisplayListBuilder& b) {
                         // Need stroke style to see dashing properly
                         b.setStyle(SkPaint::kStroke_Style);
                         // Provide some non-trivial stroke size to get dashed
                         b.setStrokeWidth(5.0);
                         b.setPathEffect(effect);
                       }));
      }
      EXPECT_TRUE(testP.is_draw_text_blob() || effect->unique())
          << "PathEffect == Dash-17-1.5 Cleanup";
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
      SkM44 m44 = SkM44(1, 0, 0, RenderCenterX,  //
                        0, 1, 0, RenderCenterY,  //
                        0, 0, 1, 0,              //
                        0, 0, .001, 1);
      m44.preConcat(
          SkM44::Rotate({1, 0, 0}, math::kPi / 60));  // 3 degrees around X
      m44.preConcat(
          SkM44::Rotate({0, 1, 0}, math::kPi / 45));  // 4 degrees around Y
      m44.preTranslate(-RenderCenterX, -RenderCenterY);
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
    SkRect r_clip = RenderBounds.makeInset(15.5, 15.5);
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
    path_clip.addCircle(RenderCenterX, RenderCenterY, 1.0);
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
    SkCanvas* cv = recorder.beginRecording(TestBounds, &rtree_factory);
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
    const SkColor bg = caseP.bg();
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
    ASSERT_EQ(sk_pixels->width(), TestWidth) << info;
    ASSERT_EQ(sk_pixels->height(), TestHeight) << info;
    ASSERT_EQ(sk_pixels->info().bytesPerPixel(), 4) << info;
    checkPixels(sk_pixels, sk_bounds, info + " (Skia reference)", bg);

    if (testP.should_match(env, sk_paint, sk_matrix, sk_clip,
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
      DisplayListBuilder builder(TestBounds);
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
        EXPECT_EQ(display_list->op_count(), sk_picture->approximateOpCount())
            << info;
      }

      std::unique_ptr<RenderSurface> dl_surface = env.MakeSurface(bg);
      display_list->RenderTo(dl_surface->canvas());
      compareToReference(dl_surface->pixmap(), sk_pixels,
                         info + " (DisplayList built directly -> surface)",
                         &dl_bounds, &tolerance, bg);

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
      DisplayListCanvasRecorder dl_recorder(TestBounds);
      caseP.render_to(&dl_recorder, testP);
      dl_recorder.builder()->Build()->RenderTo(cv_dl_surface->canvas());
      compareToReference(cv_dl_surface->pixmap(), sk_pixels,
                         info + " (Skia calls -> DisplayList -> surface)",
                         nullptr, nullptr, bg);
    }

    {
      // This sequence renders the SkCanvas calls to an SkPictureRecorder and
      // renders the DisplayList calls to a DisplayListBuilder and then
      // renders both back under a transform (scale(2x)) to see if their
      // rendering is affected differently by a change of matrix between
      // recording time and rendering time.
      const int TestWidth2 = TestWidth * 2;
      const int TestHeight2 = TestHeight * 2;
      const SkScalar TestScale = 2.0;

      SkPictureRecorder sk_x2_recorder;
      SkCanvas* ref_canvas = sk_x2_recorder.beginRecording(TestBounds);
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

      DisplayListBuilder builder_x2(TestBounds);
      caseP.render_to(builder_x2, testP);
      sk_sp<DisplayList> display_list_x2 = builder_x2.Build();
      std::unique_ptr<RenderSurface> test_x2_surface =
          env.MakeSurface(bg, TestWidth2, TestHeight2);
      SkCanvas* test_x2_canvas = test_x2_surface->canvas();
      test_x2_canvas->scale(TestScale, TestScale);
      display_list_x2->RenderTo(test_x2_canvas);
      compareToReference(test_x2_surface->pixmap(), ref_x2_pixels,
                         info + " (Both rendered scaled 2x)", nullptr, nullptr,
                         bg, TestWidth2, TestHeight2, false);
    }
  }

  static void checkGroupOpacity(const RenderEnvironment& env,
                                sk_sp<DisplayList> display_list,
                                const SkPixmap* ref_pixmap,
                                const std::string info,
                                SkColor bg) {
    SkScalar opacity = 128.0 / 255.0;

    std::unique_ptr<RenderSurface> group_opacity_surface = env.MakeSurface(bg);
    SkCanvas* group_opacity_canvas = group_opacity_surface->canvas();
    display_list->RenderTo(group_opacity_canvas, opacity);
    const SkPixmap* group_opacity_pixmap = group_opacity_surface->pixmap();

    ASSERT_EQ(group_opacity_pixmap->width(), TestWidth) << info;
    ASSERT_EQ(group_opacity_pixmap->height(), TestHeight) << info;
    ASSERT_EQ(group_opacity_pixmap->info().bytesPerPixel(), 4) << info;

    ASSERT_EQ(ref_pixmap->width(), TestWidth) << info;
    ASSERT_EQ(ref_pixmap->height(), TestHeight) << info;
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
    for (int y = 0; y < TestHeight; y++) {
      const uint32_t* ref_row = ref_pixmap->addr32(0, y);
      const uint32_t* test_row = group_opacity_pixmap->addr32(0, y);
      for (int x = 0; x < TestWidth; x++) {
        uint32_t ref_pixel = ref_row[x];
        uint32_t test_pixel = test_row[x];
        if (ref_pixel != bg || test_pixel != bg) {
          pixels_touched++;
          for (int i = 0; i < 32; i += 8) {
            int ref_comp = (ref_pixel >> i) & 0xff;
            int bg_comp = (bg >> i) & 0xff;
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
                          const SkColor bg) {
    SkPMColor untouched = SkPreMultiplyColor(bg);
    int pixels_touched = 0;
    int pixels_oob = 0;
    SkIRect i_bounds = ref_bounds.roundOut();
    for (int y = 0; y < TestHeight; y++) {
      const uint32_t* ref_row = ref_pixels->addr32(0, y);
      for (int x = 0; x < TestWidth; x++) {
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
                                 const SkColor bg,
                                 int width = TestWidth,
                                 int height = TestHeight,
                                 bool printMismatches = false) {
    SkPMColor untouched = SkPreMultiplyColor(bg);
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
        if (test_row[x] != ref_row[x]) {
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

  static const sk_sp<SkImage> testImage;
  static const sk_sp<SkImage> makeTestImage() {
    sk_sp<SkSurface> surface =
        SkSurface::MakeRasterN32Premul(RenderWidth, RenderHeight);
    SkCanvas* canvas = surface->getCanvas();
    SkPaint p0, p1;
    p0.setStyle(SkPaint::kFill_Style);
    p0.setColor(SkColorSetARGB(0xff, 0x00, 0xfe, 0x00));  // off-green
    p1.setStyle(SkPaint::kFill_Style);
    p1.setColor(SK_ColorBLUE);
    // Some pixels need some transparency for DstIn testing
    p1.setAlpha(128);
    int cbdim = 5;
    for (int y = 0; y < RenderHeight; y += cbdim) {
      for (int x = 0; x < RenderWidth; x += cbdim) {
        SkPaint& cellp = ((x + y) & 1) == 0 ? p0 : p1;
        canvas->drawRect(SkRect::MakeXYWH(x, y, cbdim, cbdim), cellp);
      }
    }
    return surface->makeImageSnapshot();
  }

  static const sk_sp<SkShader> testImageShader;

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

const sk_sp<SkImage> CanvasCompareTester::testImage = makeTestImage();
const sk_sp<SkShader> CanvasCompareTester::testImageShader =
    makeTestImage()->makeShader(SkTileMode::kRepeat,
                                SkTileMode::kRepeat,
                                SkSamplingOptions());

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
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawColor(SK_ColorMAGENTA);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawColor(SK_ColorMAGENTA, SkBlendMode::kSrcOver);
          },
          kDrawColorFlags));
}

TEST_F(DisplayListCanvas, DrawDiagonalLines) {
  SkPoint p1 = SkPoint::Make(RenderLeft, RenderTop);
  SkPoint p2 = SkPoint::Make(RenderRight, RenderBottom);
  SkPoint p3 = SkPoint::Make(RenderLeft, RenderBottom);
  SkPoint p4 = SkPoint::Make(RenderRight, RenderTop);

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
  SkPoint p1 = SkPoint::Make(RenderLeft, RenderCenterY);
  SkPoint p2 = SkPoint::Make(RenderRight, RenderCenterY);

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
  SkPoint p1 = SkPoint::Make(RenderCenterX, RenderTop);
  SkPoint p2 = SkPoint::Make(RenderCenterY, RenderBottom);

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
            canvas->drawRect(RenderBounds.makeOffset(0.5, 0.5), paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawRect(RenderBounds.makeOffset(0.5, 0.5));
          },
          kDrawRectFlags));
}

TEST_F(DisplayListCanvas, DrawOval) {
  SkRect rect = RenderBounds.makeInset(0, 10);

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
            canvas->drawCircle(TestCenter, RenderRadius, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawCircle(TestCenter, RenderRadius);
          },
          kDrawCircleFlags));
}

TEST_F(DisplayListCanvas, DrawRRect) {
  SkRRect rrect =
      SkRRect::MakeRectXY(RenderBounds, RenderCornerRadius, RenderCornerRadius);
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
  SkRRect outer =
      SkRRect::MakeRectXY(RenderBounds, RenderCornerRadius, RenderCornerRadius);
  SkRect innerBounds = RenderBounds.makeInset(30.0, 30.0);
  SkRRect inner =
      SkRRect::MakeRectXY(innerBounds, RenderCornerRadius, RenderCornerRadius);
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
  path.moveTo(RenderLeft + 15, RenderTop + 15);
  path.lineTo(RenderRight - 15, RenderBottom - 15);
  path.moveTo(RenderLeft + 15, RenderBottom - 15);
  path.lineTo(RenderRight - 15, RenderTop + 15);

  path.addRect(RenderBounds);

  // miter diamonds horizontally and vertically to show miters
  path.moveTo(VerticalMiterDiamondPoints[0]);
  for (int i = 1; i < VerticalMiterDiamondPointCount; i++) {
    path.lineTo(VerticalMiterDiamondPoints[i]);
  }
  path.close();
  path.moveTo(HorizontalMiterDiamondPoints[0]);
  for (int i = 1; i < HorizontalMiterDiamondPointCount; i++) {
    path.lineTo(HorizontalMiterDiamondPoints[i]);
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
            canvas->drawArc(RenderBounds, 60, 330, false, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawArc(RenderBounds, 60, 330, false);
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
            canvas->drawArc(RenderBounds, 60, 360 - 12, true, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawArc(RenderBounds, 60, 360 - 12, true);
          },
          kDrawArcWithCenterFlags)
          .set_draw_arc_center());
}

TEST_F(DisplayListCanvas, DrawPointsAsPoints) {
  // The +/- 16 points are designed to fall just inside the clips
  // that are tested against so we avoid lots of undrawn pixels
  // in the accumulated bounds.
  const SkScalar x0 = RenderLeft;
  const SkScalar x1 = RenderLeft + 16;
  const SkScalar x2 = (RenderLeft + RenderCenterX) * 0.5;
  const SkScalar x3 = RenderCenterX + 0.1;
  const SkScalar x4 = (RenderRight + RenderCenterX) * 0.5;
  const SkScalar x5 = RenderRight - 16;
  const SkScalar x6 = RenderRight;

  const SkScalar y0 = RenderTop;
  const SkScalar y1 = RenderTop + 16;
  const SkScalar y2 = (RenderTop + RenderCenterY) * 0.5;
  const SkScalar y3 = RenderCenterY + 0.1;
  const SkScalar y4 = (RenderBottom + RenderCenterY) * 0.5;
  const SkScalar y5 = RenderBottom - 16;
  const SkScalar y6 = RenderBottom;

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
  const SkScalar x0 = RenderLeft + 1;
  const SkScalar x1 = RenderLeft + 16;
  const SkScalar x2 = RenderRight - 16;
  const SkScalar x3 = RenderRight - 1;

  const SkScalar y0 = RenderTop;
  const SkScalar y1 = RenderTop + 16;
  const SkScalar y2 = RenderBottom - 16;
  const SkScalar y3 = RenderBottom;

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
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderTop),
      SkPoint::Make(RenderRight, RenderBottom),
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderBottom),
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
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderTop),
      SkPoint::Make(RenderRight, RenderCenterY),
      // Lower-Left corner, full bottom, half left coverage
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderLeft, RenderCenterY),
      SkPoint::Make(RenderRight, RenderBottom),
  };
  const SkColor colors[6] = {
      SK_ColorRED,  SK_ColorBLUE,   SK_ColorGREEN,
      SK_ColorCYAN, SK_ColorYELLOW, SK_ColorMAGENTA,
  };
  const sk_sp<SkVertices> vertices = SkVertices::MakeCopy(
      SkVertices::kTriangles_VertexMode, 6, pts, nullptr, colors);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawVertices(vertices.get(), SkBlendMode::kSrcOver, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawVertices(vertices, SkBlendMode::kSrcOver);
          },
          kDrawVerticesFlags)
          .set_draw_vertices());
  EXPECT_TRUE(vertices->unique());
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
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderTop),
      SkPoint::Make(RenderRight, RenderCenterY),
      // Lower-Left corner, full bottom, half left coverage
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderLeft, RenderCenterY),
      SkPoint::Make(RenderRight, RenderBottom),
  };
  const SkPoint tex[6] = {
      SkPoint::Make(RenderWidth / 2.0, 0),
      SkPoint::Make(0, RenderHeight),
      SkPoint::Make(RenderWidth, RenderHeight),
      SkPoint::Make(RenderWidth / 2, RenderHeight),
      SkPoint::Make(0, 0),
      SkPoint::Make(RenderWidth, 0),
  };
  const sk_sp<SkVertices> vertices = SkVertices::MakeCopy(
      SkVertices::kTriangles_VertexMode, 6, pts, tex, nullptr);

  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            SkPaint v_paint = paint;
            if (v_paint.getShader() == nullptr) {
              v_paint.setShader(CanvasCompareTester::testImageShader);
            }
            canvas->drawVertices(vertices.get(), SkBlendMode::kSrcOver,
                                 v_paint);
          },
          [=](DisplayListBuilder& builder) {  //
            if (builder.getShader() == nullptr) {
              builder.setShader(CanvasCompareTester::testImageShader);
            }
            builder.drawVertices(vertices, SkBlendMode::kSrcOver);
          },
          kDrawVerticesFlags)
          .set_draw_vertices());

  EXPECT_TRUE(vertices->unique());
  EXPECT_TRUE(CanvasCompareTester::testImageShader->unique());
}

TEST_F(DisplayListCanvas, DrawImageNearest) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {        //
            canvas->drawImage(CanvasCompareTester::testImage,  //
                              RenderLeft, RenderTop,
                              DisplayList::NearestSampling, &paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawImage(CanvasCompareTester::testImage,
                              SkPoint::Make(RenderLeft, RenderTop),
                              DisplayList::NearestSampling, true);
          },
          kDrawImageWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageNearestNoPaint) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {        //
            canvas->drawImage(CanvasCompareTester::testImage,  //
                              RenderLeft, RenderTop,
                              DisplayList::NearestSampling, nullptr);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawImage(CanvasCompareTester::testImage,
                              SkPoint::Make(RenderLeft, RenderTop),
                              DisplayList::NearestSampling, false);
          },
          kDrawImageFlags));
}

TEST_F(DisplayListCanvas, DrawImageLinear) {
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {        //
            canvas->drawImage(CanvasCompareTester::testImage,  //
                              RenderLeft, RenderTop,
                              DisplayList::LinearSampling, &paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawImage(CanvasCompareTester::testImage,
                              SkPoint::Make(RenderLeft, RenderTop),
                              DisplayList::LinearSampling, true);
          },
          kDrawImageWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageRectNearest) {
  SkRect src = SkRect::MakeIWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawImageRect(CanvasCompareTester::testImage, src, dst,
                                  DisplayList::NearestSampling, &paint,
                                  SkCanvas::kFast_SrcRectConstraint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawImageRect(CanvasCompareTester::testImage, src, dst,
                                  DisplayList::NearestSampling, true);
          },
          kDrawImageRectWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageRectNearestNoPaint) {
  SkRect src = SkRect::MakeIWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawImageRect(CanvasCompareTester::testImage, src, dst,
                                  DisplayList::NearestSampling, nullptr,
                                  SkCanvas::kFast_SrcRectConstraint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawImageRect(CanvasCompareTester::testImage, src, dst,
                                  DisplayList::NearestSampling, false);
          },
          kDrawImageRectFlags));
}

TEST_F(DisplayListCanvas, DrawImageRectLinear) {
  SkRect src = SkRect::MakeIWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawImageRect(CanvasCompareTester::testImage, src, dst,
                                  DisplayList::LinearSampling, &paint,
                                  SkCanvas::kFast_SrcRectConstraint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawImageRect(CanvasCompareTester::testImage, src, dst,
                                  DisplayList::LinearSampling, true);
          },
          kDrawImageRectWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageNineNearest) {
  SkIRect src = SkIRect::MakeWH(RenderWidth, RenderHeight).makeInset(25, 25);
  SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageNine(image.get(), src, dst, SkFilterMode::kNearest,
                                  &paint);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageNine(image, src, dst, SkFilterMode::kNearest,
                                  true);
          },
          kDrawImageNineWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageNineNearestNoPaint) {
  SkIRect src = SkIRect::MakeWH(RenderWidth, RenderHeight).makeInset(25, 25);
  SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageNine(image.get(), src, dst, SkFilterMode::kNearest,
                                  nullptr);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageNine(image, src, dst, SkFilterMode::kNearest,
                                  false);
          },
          kDrawImageNineFlags));
}

TEST_F(DisplayListCanvas, DrawImageNineLinear) {
  SkIRect src = SkIRect::MakeWH(RenderWidth, RenderHeight).makeInset(25, 25);
  SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageNine(image.get(), src, dst, SkFilterMode::kLinear,
                                  &paint);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageNine(image, src, dst, SkFilterMode::kLinear, true);
          },
          kDrawImageNineWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageLatticeNearest) {
  const SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  const int divX[] = {
      RenderWidth * 1 / 4,
      RenderWidth * 2 / 4,
      RenderWidth * 3 / 4,
  };
  const int divY[] = {
      RenderHeight * 1 / 4,
      RenderHeight * 2 / 4,
      RenderHeight * 3 / 4,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageLattice(image.get(), lattice, dst,
                                     SkFilterMode::kNearest, &paint);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageLattice(image, lattice, dst,
                                     SkFilterMode::kNearest, true);
          },
          kDrawImageLatticeWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawImageLatticeNearestNoPaint) {
  const SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  const int divX[] = {
      RenderWidth * 1 / 4,
      RenderWidth * 2 / 4,
      RenderWidth * 3 / 4,
  };
  const int divY[] = {
      RenderHeight * 1 / 4,
      RenderHeight * 2 / 4,
      RenderHeight * 3 / 4,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageLattice(image.get(), lattice, dst,
                                     SkFilterMode::kNearest, nullptr);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageLattice(image, lattice, dst,
                                     SkFilterMode::kNearest, false);
          },
          kDrawImageLatticeFlags));
}

TEST_F(DisplayListCanvas, DrawImageLatticeLinear) {
  const SkRect dst = RenderBounds.makeInset(10.5, 10.5);
  const int divX[] = {
      RenderWidth / 4,
      RenderWidth / 2,
      RenderWidth * 3 / 4,
  };
  const int divY[] = {
      RenderHeight / 4,
      RenderHeight / 2,
      RenderHeight * 3 / 4,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawImageLattice(image.get(), lattice, dst,
                                     SkFilterMode::kLinear, &paint);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawImageLattice(image, lattice, dst, SkFilterMode::kLinear,
                                     true);
          },
          kDrawImageLatticeWithPaintFlags));
}

TEST_F(DisplayListCanvas, DrawAtlasNearest) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, RenderLeft,  RenderTop},
      { 0.0f,  1.2f, RenderRight, RenderTop},
      {-1.2f,  0.0f, RenderRight, RenderBottom},
      { 0.0f, -1.2f, RenderLeft,  RenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,               0,                RenderHalfWidth, RenderHalfHeight},
      {RenderHalfWidth, 0,                RenderWidth,     RenderHalfHeight},
      {RenderHalfWidth, RenderHalfHeight, RenderWidth,     RenderHeight},
      {0,               RenderHalfHeight, RenderHalfWidth, RenderHeight},
      // clang-format on
  };
  const SkColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::testImage;
  const SkSamplingOptions sampling = DisplayList::NearestSampling;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawAtlas(image.get(), xform, tex, colors, 4,
                              SkBlendMode::kSrcOver, sampling, nullptr, &paint);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawAtlas(image, xform, tex, colors, 4,  //
                              SkBlendMode::kSrcOver, sampling, nullptr, true);
          },
          kDrawAtlasWithPaintFlags)
          .set_draw_atlas());
}

TEST_F(DisplayListCanvas, DrawAtlasNearestNoPaint) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, RenderLeft,  RenderTop},
      { 0.0f,  1.2f, RenderRight, RenderTop},
      {-1.2f,  0.0f, RenderRight, RenderBottom},
      { 0.0f, -1.2f, RenderLeft,  RenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,               0,                RenderHalfWidth, RenderHalfHeight},
      {RenderHalfWidth, 0,                RenderWidth,     RenderHalfHeight},
      {RenderHalfWidth, RenderHalfHeight, RenderWidth,     RenderHeight},
      {0,               RenderHalfHeight, RenderHalfWidth, RenderHeight},
      // clang-format on
  };
  const SkColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::testImage;
  const SkSamplingOptions sampling = DisplayList::NearestSampling;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawAtlas(image.get(), xform, tex, colors, 4,
                              SkBlendMode::kSrcOver, sampling,  //
                              nullptr, nullptr);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawAtlas(image, xform, tex, colors, 4,     //
                              SkBlendMode::kSrcOver, sampling,  //
                              nullptr, false);
          },
          kDrawAtlasFlags)
          .set_draw_atlas());
}

TEST_F(DisplayListCanvas, DrawAtlasLinear) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, RenderLeft,  RenderTop},
      { 0.0f,  1.2f, RenderRight, RenderTop},
      {-1.2f,  0.0f, RenderRight, RenderBottom},
      { 0.0f, -1.2f, RenderLeft,  RenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,               0,                RenderHalfWidth, RenderHalfHeight},
      {RenderHalfWidth, 0,                RenderWidth,     RenderHalfHeight},
      {RenderHalfWidth, RenderHalfHeight, RenderWidth,     RenderHeight},
      {0,               RenderHalfHeight, RenderHalfWidth, RenderHeight},
      // clang-format on
  };
  const SkColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::testImage;
  const SkSamplingOptions sampling = DisplayList::LinearSampling;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {
            canvas->drawAtlas(image.get(), xform, tex, colors, 2,  //
                              SkBlendMode::kSrcOver, sampling, nullptr, &paint);
          },
          [=](DisplayListBuilder& builder) {
            builder.drawAtlas(image, xform, tex, colors, 2,  //
                              SkBlendMode::kSrcOver, sampling, nullptr, true);
          },
          kDrawAtlasWithPaintFlags)
          .set_draw_atlas());
}

sk_sp<SkPicture> makeTestPicture() {
  SkPictureRecorder recorder;
  SkCanvas* cv = recorder.beginRecording(RenderBounds);
  SkPaint p;
  p.setStyle(SkPaint::kFill_Style);
  p.setColor(SK_ColorRED);
  cv->drawRect({RenderLeft, RenderTop, RenderCenterX, RenderCenterY}, p);
  p.setColor(SK_ColorBLUE);
  cv->drawRect({RenderCenterX, RenderTop, RenderRight, RenderCenterY}, p);
  p.setColor(SK_ColorGREEN);
  cv->drawRect({RenderLeft, RenderCenterY, RenderCenterX, RenderBottom}, p);
  p.setColor(SK_ColorYELLOW);
  cv->drawRect({RenderCenterX, RenderCenterY, RenderRight, RenderBottom}, p);
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
  builder.setStyle(SkPaint::kFill_Style);
  builder.setColor(SK_ColorRED);
  builder.drawRect({RenderLeft, RenderTop, RenderCenterX, RenderCenterY});
  builder.setColor(SK_ColorBLUE);
  builder.drawRect({RenderCenterX, RenderTop, RenderRight, RenderCenterY});
  builder.setColor(SK_ColorGREEN);
  builder.drawRect({RenderLeft, RenderCenterY, RenderCenterX, RenderBottom});
  builder.setColor(SK_ColorYELLOW);
  builder.drawRect({RenderCenterX, RenderCenterY, RenderRight, RenderBottom});
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
      CanvasCompareTester::MakeTextBlob("Testing", RenderHeight * 0.33f);
  SkScalar RenderY1_3 = RenderTop + RenderHeight * 0.3;
  SkScalar RenderY2_3 = RenderTop + RenderHeight * 0.6;
  CanvasCompareTester::RenderAll(  //
      TestParameters(
          [=](SkCanvas* canvas, const SkPaint& paint) {  //
            canvas->drawTextBlob(blob, RenderLeft, RenderY1_3, paint);
            canvas->drawTextBlob(blob, RenderLeft, RenderY2_3, paint);
            canvas->drawTextBlob(blob, RenderLeft, RenderBottom, paint);
          },
          [=](DisplayListBuilder& builder) {  //
            builder.drawTextBlob(blob, RenderLeft, RenderY1_3);
            builder.drawTextBlob(blob, RenderLeft, RenderY2_3);
            builder.drawTextBlob(blob, RenderLeft, RenderBottom);
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
          RenderLeft + 10,
          RenderTop,
          RenderRight - 10,
          RenderBottom - 20,
      },
      RenderCornerRadius, RenderCornerRadius);
  const SkColor color = SK_ColorDKGRAY;
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
          RenderLeft + 10,
          RenderTop,
          RenderRight - 10,
          RenderBottom - 20,
      },
      RenderCornerRadius, RenderCornerRadius);
  const SkColor color = SK_ColorDKGRAY;
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
          RenderLeft + 10,
          RenderTop,
          RenderRight - 10,
          RenderBottom - 20,
      },
      RenderCornerRadius, RenderCornerRadius);
  const SkColor color = SK_ColorDKGRAY;
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

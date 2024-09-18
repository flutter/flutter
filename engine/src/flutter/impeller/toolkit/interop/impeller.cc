// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/impeller.h"

#include <sstream>

#include "flutter/fml/mapping.h"
#include "impeller/base/validation.h"
#include "impeller/geometry/scalar.h"
#include "impeller/toolkit/interop/color_filter.h"
#include "impeller/toolkit/interop/color_source.h"
#include "impeller/toolkit/interop/context.h"
#include "impeller/toolkit/interop/dl_builder.h"
#include "impeller/toolkit/interop/formats.h"
#include "impeller/toolkit/interop/image_filter.h"
#include "impeller/toolkit/interop/mask_filter.h"
#include "impeller/toolkit/interop/object.h"
#include "impeller/toolkit/interop/paint.h"
#include "impeller/toolkit/interop/path.h"
#include "impeller/toolkit/interop/path_builder.h"
#include "impeller/toolkit/interop/surface.h"
#include "impeller/toolkit/interop/texture.h"

namespace impeller::interop {

#define DEFINE_PEER_GETTER(cxx_type, c_type)    \
  cxx_type* GetPeer(c_type object) {            \
    return reinterpret_cast<cxx_type*>(object); \
  }

DEFINE_PEER_GETTER(ColorFilter, ImpellerColorFilter);
DEFINE_PEER_GETTER(ColorSource, ImpellerColorSource);
DEFINE_PEER_GETTER(Context, ImpellerContext);
DEFINE_PEER_GETTER(DisplayList, ImpellerDisplayList);
DEFINE_PEER_GETTER(DisplayListBuilder, ImpellerDisplayListBuilder);
DEFINE_PEER_GETTER(ImageFilter, ImpellerImageFilter);
DEFINE_PEER_GETTER(MaskFilter, ImpellerMaskFilter);
DEFINE_PEER_GETTER(Paint, ImpellerPaint);
DEFINE_PEER_GETTER(Path, ImpellerPath);
DEFINE_PEER_GETTER(PathBuilder, ImpellerPathBuilder);
DEFINE_PEER_GETTER(Surface, ImpellerSurface);
DEFINE_PEER_GETTER(Texture, ImpellerTexture);

static std::string GetVersionAsString(uint32_t version) {
  std::stringstream stream;
  stream << IMPELLER_VERSION_GET_VARIANT(version) << "."
         << IMPELLER_VERSION_GET_MAJOR(version) << "."
         << IMPELLER_VERSION_GET_MINOR(version) << "."
         << IMPELLER_VERSION_GET_PATCH(version);
  return stream.str();
}

IMPELLER_EXTERN_C
uint32_t ImpellerGetVersion() {
  return IMPELLER_VERSION;
}

IMPELLER_EXTERN_C
ImpellerContext ImpellerContextCreateOpenGLESNew(
    uint32_t version,
    ImpellerProcAddressCallback gl_proc_address_callback,
    void* gl_proc_address_callback_user_data) {
  if (version != IMPELLER_VERSION) {
    VALIDATION_LOG << "This version of Impeller ("
                   << GetVersionAsString(ImpellerGetVersion()) << ") "
                   << "doesn't match the version the user expects ("
                   << GetVersionAsString(version) << ").";
    return nullptr;
  }
  auto context = Context::CreateOpenGLES(
      [gl_proc_address_callback,
       gl_proc_address_callback_user_data](const char* proc_name) -> void* {
        return gl_proc_address_callback(proc_name,
                                        gl_proc_address_callback_user_data);
      });
  if (!context || !context->IsValid()) {
    VALIDATION_LOG << "Could not create valid context.";
    return nullptr;
  }
  return context.Leak();
}

IMPELLER_EXTERN_C
void ImpellerContextRetain(ImpellerContext context) {
  ObjectBase::SafeRetain(context);
}

IMPELLER_EXTERN_C
void ImpellerContextRelease(ImpellerContext context) {
  ObjectBase::SafeRelease(context);
}

IMPELLER_EXTERN_C
ImpellerDisplayListBuilder ImpellerDisplayListBuilderNew(
    const ImpellerRect* cull_rect) {
  return Create<DisplayListBuilder>(cull_rect).Leak();
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderRetain(ImpellerDisplayListBuilder builder) {
  ObjectBase::SafeRetain(builder);
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderRelease(ImpellerDisplayListBuilder builder) {
  ObjectBase::SafeRelease(builder);
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderSave(ImpellerDisplayListBuilder builder) {
  GetPeer(builder)->Save();
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderSaveLayer(ImpellerDisplayListBuilder builder,
                                         const ImpellerRect* bounds,
                                         ImpellerPaint paint,
                                         ImpellerImageFilter backdrop) {
  GetPeer(builder)->SaveLayer(ToImpellerType(*bounds),  //
                              GetPeer(paint),           //
                              GetPeer(backdrop)         //
  );
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderRestore(ImpellerDisplayListBuilder builder) {
  GetPeer(builder)->Restore();
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderScale(ImpellerDisplayListBuilder builder,
                                     float x_scale,
                                     float y_scale) {
  GetPeer(builder)->Scale(Size{x_scale, y_scale});
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderRotate(ImpellerDisplayListBuilder builder,
                                      float angle_degrees) {
  GetPeer(builder)->Rotate(Degrees{angle_degrees});
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderTranslate(ImpellerDisplayListBuilder builder,
                                         float x_translation,
                                         float y_translation) {
  GetPeer(builder)->Translate(Point{x_translation, y_translation});
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderSetTransform(ImpellerDisplayListBuilder builder,
                                            const ImpellerMatrix* transform) {
  GetPeer(builder)->SetTransform(ToImpellerType(*transform));
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderGetTransform(ImpellerDisplayListBuilder builder,
                                            ImpellerMatrix* out_transform) {
  FromImpellerType(GetPeer(builder)->GetTransform(), *out_transform);
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderResetTransform(
    ImpellerDisplayListBuilder builder) {
  GetPeer(builder)->ResetTransform();
}

IMPELLER_EXTERN_C
uint32_t ImpellerDisplayListBuilderGetSaveCount(
    ImpellerDisplayListBuilder builder) {
  return GetPeer(builder)->GetSaveCount();
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderRestoreToCount(
    ImpellerDisplayListBuilder builder,
    uint32_t count) {
  GetPeer(builder)->RestoreToCount(count);
}

IMPELLER_EXTERN_C
void ImpellerPathRetain(ImpellerPath path) {
  ObjectBase::SafeRetain(path);
}

IMPELLER_EXTERN_C
void ImpellerPathRelease(ImpellerPath path) {
  ObjectBase::SafeRelease(path);
}

IMPELLER_EXTERN_C
ImpellerPathBuilder ImpellerPathBuilderNew() {
  return Create<PathBuilder>().Leak();
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderRetain(ImpellerPathBuilder builder) {
  ObjectBase::SafeRetain(builder);
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderRelease(ImpellerPathBuilder builder) {
  ObjectBase::SafeRelease(builder);
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderMoveTo(ImpellerPathBuilder builder,
                               const ImpellerPoint* location) {
  GetPeer(builder)->MoveTo(ToImpellerType(*location));
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderLineTo(ImpellerPathBuilder builder,
                               const ImpellerPoint* location) {
  GetPeer(builder)->LineTo(ToImpellerType(*location));
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderQuadraticCurveTo(ImpellerPathBuilder builder,
                                         const ImpellerPoint* control_point,
                                         const ImpellerPoint* end_point) {
  GetPeer(builder)->QuadraticCurveTo(ToImpellerType(*control_point),
                                     ToImpellerType(*end_point));
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderCubicCurveTo(ImpellerPathBuilder builder,
                                     const ImpellerPoint* control_point_1,
                                     const ImpellerPoint* control_point_2,
                                     const ImpellerPoint* end_point) {
  GetPeer(builder)->CubicCurveTo(ToImpellerType(*control_point_1),  //
                                 ToImpellerType(*control_point_2),  //
                                 ToImpellerType(*end_point)         //
  );
}

IMPELLER_EXTERN_C void ImpellerPathBuilderAddRect(ImpellerPathBuilder builder,
                                                  const ImpellerRect* rect) {
  GetPeer(builder)->AddRect(ToImpellerType(*rect));
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderAddArc(ImpellerPathBuilder builder,
                               const ImpellerRect* oval_bounds,
                               float start_angle_degrees,
                               float end_angle_degrees) {
  GetPeer(builder)->AddArc(ToImpellerType(*oval_bounds),  //
                           Degrees{start_angle_degrees},  //
                           Degrees{end_angle_degrees}     //
  );
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderAddOval(ImpellerPathBuilder builder,
                                const ImpellerRect* oval_bounds) {
  GetPeer(builder)->AddOval(ToImpellerType(*oval_bounds));
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderAddRoundedRect(
    ImpellerPathBuilder builder,
    const ImpellerRect* rect,
    const ImpellerRoundingRadii* rounding_radii) {
  GetPeer(builder)->AddRoundedRect(ToImpellerType(*rect),
                                   ToImpellerType(*rounding_radii));
}

IMPELLER_EXTERN_C
void ImpellerPathBuilderClose(ImpellerPathBuilder builder) {
  GetPeer(builder)->Close();
}

IMPELLER_EXTERN_C
ImpellerPath ImpellerPathBuilderCopyPathNew(ImpellerPathBuilder builder,
                                            ImpellerFillType fill) {
  return GetPeer(builder)->CopyPath(ToImpellerType(fill)).Leak();
}

IMPELLER_EXTERN_C ImpellerPath ImpellerPathBuilderTakePathNew(
    ImpellerPathBuilder builder,
    ImpellerFillType fill) {
  return GetPeer(builder)->TakePath(ToImpellerType(fill)).Leak();
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderClipRect(ImpellerDisplayListBuilder builder,
                                        const ImpellerRect* rect,
                                        ImpellerClipOperation op) {
  GetPeer(builder)->ClipRect(ToImpellerType(*rect), ToImpellerType(op));
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderClipOval(ImpellerDisplayListBuilder builder,
                                        const ImpellerRect* oval_bounds,
                                        ImpellerClipOperation op) {
  GetPeer(builder)->ClipOval(ToImpellerType(*oval_bounds), ToImpellerType(op));
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderClipRoundedRect(
    ImpellerDisplayListBuilder builder,
    const ImpellerRect* rect,
    const ImpellerRoundingRadii* radii,
    ImpellerClipOperation op) {
  GetPeer(builder)->ClipRoundedRect(ToImpellerType(*rect),   //
                                    ToImpellerType(*radii),  //
                                    ToImpellerType(op)       //
  );
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderClipPath(ImpellerDisplayListBuilder builder,
                                        ImpellerPath path,
                                        ImpellerClipOperation op) {
  GetPeer(builder)->ClipPath(*GetPeer(path), ToImpellerType(op));
}

IMPELLER_EXTERN_C
ImpellerPaint ImpellerPaintNew() {
  return Create<Paint>().Leak();
}

IMPELLER_EXTERN_C
void ImpellerPaintRetain(ImpellerPaint paint) {
  ObjectBase::SafeRetain(paint);
}

IMPELLER_EXTERN_C
void ImpellerPaintRelease(ImpellerPaint paint) {
  ObjectBase::SafeRelease(paint);
}

IMPELLER_EXTERN_C
void ImpellerPaintSetColor(ImpellerPaint paint, const ImpellerColor* color) {
  GetPeer(paint)->SetColor(ToDisplayListType(*color));
}

IMPELLER_EXTERN_C
void ImpellerPaintSetBlendMode(ImpellerPaint paint, ImpellerBlendMode mode) {
  GetPeer(paint)->SetBlendMode(ToImpellerType(mode));
}

IMPELLER_EXTERN_C
void ImpellerPaintSetDrawStyle(ImpellerPaint paint, ImpellerDrawStyle style) {
  GetPeer(paint)->SetDrawStyle(ToDisplayListType(style));
}

IMPELLER_EXTERN_C
void ImpellerPaintSetStrokeCap(ImpellerPaint paint, ImpellerStrokeCap cap) {
  GetPeer(paint)->SetStrokeCap(ToDisplayListType(cap));
}

IMPELLER_EXTERN_C
void ImpellerPaintSetStrokeJoin(ImpellerPaint paint, ImpellerStrokeJoin join) {
  GetPeer(paint)->SetStrokeJoin(ToDisplayListType(join));
}

IMPELLER_EXTERN_C
void ImpellerPaintSetStrokeWidth(ImpellerPaint paint, float width) {
  GetPeer(paint)->SetStrokeWidth(width);
}

IMPELLER_EXTERN_C
void ImpellerPaintSetStrokeMiter(ImpellerPaint paint, float miter) {
  GetPeer(paint)->SetStrokeMiter(miter);
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawPaint(ImpellerDisplayListBuilder builder,
                                         ImpellerPaint paint) {
  GetPeer(builder)->DrawPaint(*GetPeer(paint));
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawLine(ImpellerDisplayListBuilder builder,
                                        const ImpellerPoint* from,
                                        const ImpellerPoint* to,
                                        ImpellerPaint paint) {
  GetPeer(builder)->DrawLine(ToImpellerType(*from),  //
                             ToImpellerType(*to),    //
                             *GetPeer(paint)         //
  );
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawDashedLine(
    ImpellerDisplayListBuilder builder,
    const ImpellerPoint* from,
    const ImpellerPoint* to,
    float on_length,
    float off_length,
    ImpellerPaint paint) {
  GetPeer(builder)->DrawDashedLine(ToImpellerType(*from),  //
                                   ToImpellerType(*to),    //
                                   on_length,              //
                                   off_length,             //
                                   *GetPeer(paint)         //
  );
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawRect(ImpellerDisplayListBuilder builder,
                                        const ImpellerRect* rect,
                                        ImpellerPaint paint) {
  GetPeer(builder)->DrawRect(ToImpellerType(*rect), *GetPeer(paint));
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawOval(ImpellerDisplayListBuilder builder,
                                        const ImpellerRect* oval_bounds,
                                        ImpellerPaint paint) {
  GetPeer(builder)->DrawOval(ToImpellerType(*oval_bounds), *GetPeer(paint));
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawRoundedRect(
    ImpellerDisplayListBuilder builder,
    const ImpellerRect* rect,
    const ImpellerRoundingRadii* radii,
    ImpellerPaint paint) {
  GetPeer(builder)->DrawRoundedRect(ToImpellerType(*rect),   //
                                    ToImpellerType(*radii),  //
                                    *GetPeer(paint)          //
  );
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawRoundedRectDifference(
    ImpellerDisplayListBuilder builder,
    const ImpellerRect* outer_rect,
    const ImpellerRoundingRadii* outer_radii,
    const ImpellerRect* inner_rect,
    const ImpellerRoundingRadii* inner_radii,
    ImpellerPaint paint) {
  GetPeer(builder)->DrawRoundedRectDifference(ToImpellerType(*outer_rect),   //
                                              ToImpellerType(*outer_radii),  //
                                              ToImpellerType(*inner_rect),   //
                                              ToImpellerType(*inner_radii),  //
                                              *GetPeer(paint)                //
  );
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawPath(ImpellerDisplayListBuilder builder,
                                        ImpellerPath path,
                                        ImpellerPaint paint) {
  GetPeer(builder)->DrawPath(*GetPeer(path), *GetPeer(paint));
}

IMPELLER_EXTERN_C
ImpellerTexture ImpellerTextureCreateWithContentsNew(
    ImpellerContext context,
    const ImpellerTextureDescriptor* descriptor,
    const ImpellerMapping* IMPELLER_NONNULL contents,
    void* IMPELLER_NULLABLE contents_on_release_user_data) {
  TextureDescriptor desc;
  desc.storage_mode = StorageMode::kDevicePrivate;
  desc.type = TextureType::kTexture2D;
  desc.format = ToImpellerType(descriptor->pixel_format);
  desc.size = ToImpellerType(descriptor->size);
  desc.mip_count = std::min(descriptor->mip_count, 1u);
  desc.usage = TextureUsage::kShaderRead;
  desc.compression_type = CompressionType::kLossless;
  auto texture = Create<Texture>(*GetPeer(context), desc);
  if (!texture->IsValid()) {
    VALIDATION_LOG << "Could not create texture.";
    return nullptr;
  }
  // Depending on whether the de-allocation can be delayed, it may be possible
  // to avoid a data copy.
  if (contents->on_release) {
    // Avoids data copy.
    auto wrapped_contents = std::make_shared<fml::NonOwnedMapping>(
        contents->data,    // data ptr
        contents->length,  // data length
        [contents, contents_on_release_user_data](auto, auto) {
          contents->on_release(contents_on_release_user_data);
        }  // release callback
    );
    if (!texture->SetContents(std::move(wrapped_contents))) {
      VALIDATION_LOG << "Could not set texture contents.";
      return nullptr;
    }
  } else {
    // May copy.
    if (!texture->SetContents(contents->data, contents->length)) {
      VALIDATION_LOG << "Could not set texture contents.";
      return nullptr;
    }
  }
  return texture.Leak();
}

IMPELLER_EXTERN_C
void ImpellerTextureRetain(ImpellerTexture texture) {
  ObjectBase::SafeRetain(texture);
}

IMPELLER_EXTERN_C
void ImpellerTextureRelease(ImpellerTexture texture) {
  ObjectBase::SafeRelease(texture);
}

IMPELLER_EXTERN_C
void ImpellerDisplayListRetain(ImpellerDisplayList display_list) {
  ObjectBase::SafeRetain(display_list);
}

IMPELLER_EXTERN_C
void ImpellerDisplayListRelease(ImpellerDisplayList display_list) {
  ObjectBase::SafeRelease(display_list);
}

IMPELLER_EXTERN_C
ImpellerDisplayList ImpellerDisplayListBuilderCreateDisplayListNew(
    ImpellerDisplayListBuilder builder) {
  auto dl = GetPeer(builder)->Build();
  if (!dl->IsValid()) {
    return nullptr;
  }
  return dl.Leak();
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawDisplayList(
    ImpellerDisplayListBuilder builder,
    ImpellerDisplayList display_list,
    float opacity) {
  GetPeer(builder)->DrawDisplayList(*GetPeer(display_list), opacity);
}

IMPELLER_EXTERN_C
ImpellerSurface ImpellerSurfaceCreateWrappedFBONew(ImpellerContext context,
                                                   uint64_t fbo,
                                                   ImpellerPixelFormat format,
                                                   const ImpellerISize* size) {
  return Surface::WrapFBO(*GetPeer(context),       //
                          fbo,                     //
                          ToImpellerType(format),  //
                          ToImpellerType(*size))   //
      .Leak();
}

IMPELLER_EXTERN_C
void ImpellerSurfaceRetain(ImpellerSurface surface) {
  ObjectBase::SafeRetain(surface);
}

IMPELLER_EXTERN_C
void ImpellerSurfaceRelease(ImpellerSurface surface) {
  ObjectBase::SafeRelease(surface);
}

IMPELLER_EXTERN_C
bool ImpellerSurfaceDrawDisplayList(ImpellerSurface surface,
                                    ImpellerDisplayList display_list) {
  return GetPeer(surface)->DrawDisplayList(*GetPeer(display_list));
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawTexture(ImpellerDisplayListBuilder builder,
                                           ImpellerTexture texture,
                                           const ImpellerPoint* point,
                                           ImpellerTextureSampling sampling,
                                           ImpellerPaint paint) {
  GetPeer(builder)->DrawTexture(*GetPeer(texture),            //
                                ToImpellerType(*point),       //
                                ToDisplayListType(sampling),  //
                                GetPeer(paint)                //
  );
}

IMPELLER_EXTERN_C
void ImpellerDisplayListBuilderDrawTextureRect(
    ImpellerDisplayListBuilder builder,
    ImpellerTexture texture,
    const ImpellerRect* src_rect,
    const ImpellerRect* dst_rect,
    ImpellerTextureSampling sampling,
    ImpellerPaint paint) {
  GetPeer(builder)->DrawTextureRect(*GetPeer(texture),            //
                                    ToImpellerType(*src_rect),    //
                                    ToImpellerType(*dst_rect),    //
                                    ToDisplayListType(sampling),  //
                                    GetPeer(paint)                //
  );
}

IMPELLER_EXTERN_C
void ImpellerColorSourceRetain(ImpellerColorSource color_source) {
  ObjectBase::SafeRetain(color_source);
}

IMPELLER_EXTERN_C
void ImpellerColorSourceRelease(ImpellerColorSource color_source) {
  ObjectBase::SafeRelease(color_source);
}

static std::pair<std::vector<flutter::DlColor>, std::vector<Scalar>>
ParseColorsAndStops(uint32_t stop_count,
                    const ImpellerColor* colors,
                    const float* stops) {
  if (stop_count == 0) {
    return {};
  }
  std::pair<std::vector<flutter::DlColor>, std::vector<Scalar>> result;
  result.first.reserve(stop_count);
  result.second.reserve(stop_count);
  for (size_t i = 0; i < stop_count; i++) {
    result.first.emplace_back(ToDisplayListType(colors[i]));
    result.second.emplace_back(stops[i]);
  }
  return result;
}

IMPELLER_EXTERN_C
ImpellerColorSource ImpellerColorSourceCreateLinearGradientNew(
    const ImpellerPoint* start_point,
    const ImpellerPoint* end_point,
    uint32_t stop_count,
    const ImpellerColor* colors,
    const float* stops,
    ImpellerTileMode tile_mode,
    const ImpellerMatrix* transformation) {
  const auto colors_and_stops = ParseColorsAndStops(stop_count, colors, stops);
  return ColorSource::MakeLinearGradient(
             ToImpellerType(*start_point),  //
             ToImpellerType(*end_point),    //
             colors_and_stops.first,        //
             colors_and_stops.second,       //
             ToDisplayListType(tile_mode),  //
             transformation == nullptr ? Matrix{}
                                       : ToImpellerType(*transformation)  //
             )
      .Leak();
}

IMPELLER_EXTERN_C
ImpellerColorSource ImpellerColorSourceCreateRadialGradientNew(
    const ImpellerPoint* center,
    float radius,
    uint32_t stop_count,
    const ImpellerColor* colors,
    const float* stops,
    ImpellerTileMode tile_mode,
    const ImpellerMatrix* transformation) {
  const auto colors_and_stops = ParseColorsAndStops(stop_count, colors, stops);
  return ColorSource::MakeRadialGradient(
             ToImpellerType(*center),       //
             radius,                        //
             colors_and_stops.first,        //
             colors_and_stops.second,       //
             ToDisplayListType(tile_mode),  //
             transformation == nullptr ? Matrix{}
                                       : ToImpellerType(*transformation)  //
             )
      .Leak();
}

IMPELLER_EXTERN_C
ImpellerColorSource ImpellerColorSourceCreateConicalGradientNew(
    const ImpellerPoint* start_center,
    float start_radius,
    const ImpellerPoint* end_center,
    float end_radius,
    uint32_t stop_count,
    const ImpellerColor* colors,
    const float* stops,
    ImpellerTileMode tile_mode,
    const ImpellerMatrix* transformation) {
  const auto colors_and_stops = ParseColorsAndStops(stop_count, colors, stops);
  return ColorSource::MakeConicalGradient(
             ToImpellerType(*start_center),  //
             start_radius,                   //
             ToImpellerType(*end_center),    //
             end_radius,                     //
             colors_and_stops.first,         //
             colors_and_stops.second,        //
             ToDisplayListType(tile_mode),   //
             transformation == nullptr ? Matrix{}
                                       : ToImpellerType(*transformation)  //
             )
      .Leak();
}

IMPELLER_EXTERN_C
ImpellerColorSource ImpellerColorSourceCreateSweepGradientNew(
    const ImpellerPoint* center,
    float start,
    float end,
    uint32_t stop_count,
    const ImpellerColor* colors,
    const float* stops,
    ImpellerTileMode tile_mode,
    const ImpellerMatrix* transformation) {
  const auto colors_and_stops = ParseColorsAndStops(stop_count, colors, stops);
  return ColorSource::MakeSweepGradient(
             ToImpellerType(*center),       //
             start,                         //
             end,                           //
             colors_and_stops.first,        //
             colors_and_stops.second,       //
             ToDisplayListType(tile_mode),  //
             transformation == nullptr ? Matrix{}
                                       : ToImpellerType(*transformation)  //
             )
      .Leak();
}

IMPELLER_EXTERN_C
void ImpellerColorFilterRetain(ImpellerColorFilter color_filter) {
  ObjectBase::SafeRetain(color_filter);
}

IMPELLER_EXTERN_C
void ImpellerColorFilterRelease(ImpellerColorFilter color_filter) {
  ObjectBase::SafeRelease(color_filter);
}

IMPELLER_EXTERN_C
ImpellerColorFilter ImpellerColorFilterCreateBlendNew(
    const ImpellerColor* color,
    ImpellerBlendMode blend_mode) {
  return ColorFilter::MakeBlend(ToImpellerType(*color),
                                ToImpellerType(blend_mode))
      .Leak();
}

IMPELLER_EXTERN_C
ImpellerColorFilter ImpellerColorFilterCreateColorMatrixNew(
    const ImpellerColorMatrix* color_matrix) {
  return ColorFilter::MakeMatrix(color_matrix->m).Leak();
}

IMPELLER_EXTERN_C
void ImpellerMaskFilterRetain(ImpellerMaskFilter mask_filter) {
  ObjectBase::SafeRetain(mask_filter);
}

IMPELLER_EXTERN_C
void ImpellerMaskFilterRelease(ImpellerMaskFilter mask_filter) {
  ObjectBase::SafeRelease(mask_filter);
}

IMPELLER_EXTERN_C
ImpellerMaskFilter ImpellerMaskFilterCreateBlurNew(ImpellerBlurStyle style,
                                                   float sigma) {
  return MaskFilter::MakeBlur(ToDisplayListType(style), sigma).Leak();
}

IMPELLER_EXTERN_C
void ImpellerImageFilterRetain(ImpellerImageFilter image_filter) {
  ObjectBase::SafeRetain(image_filter);
}

IMPELLER_EXTERN_C
void ImpellerImageFilterRelease(ImpellerImageFilter image_filter) {
  ObjectBase::SafeRelease(image_filter);
}

IMPELLER_EXTERN_C
ImpellerImageFilter ImpellerImageFilterCreateBlurNew(
    float x_sigma,
    float y_sigma,
    ImpellerTileMode tile_mode) {
  return ImageFilter::MakeBlur(x_sigma, y_sigma, ToDisplayListType(tile_mode))
      .Leak();
}

IMPELLER_EXTERN_C
ImpellerImageFilter ImpellerImageFilterCreateDilateNew(float x_radius,
                                                       float y_radius) {
  return ImageFilter::MakeDilate(x_radius, y_radius).Leak();
}

IMPELLER_EXTERN_C
ImpellerImageFilter ImpellerImageFilterCreateErodeNew(float x_radius,
                                                      float y_radius) {
  return ImageFilter::MakeErode(x_radius, y_radius).Leak();
}

IMPELLER_EXTERN_C
ImpellerImageFilter ImpellerImageFilterCreateMatrixNew(
    const ImpellerMatrix* matrix,
    ImpellerTextureSampling sampling) {
  return ImageFilter::MakeMatrix(ToImpellerType(*matrix),
                                 ToDisplayListType(sampling))
      .Leak();
}

IMPELLER_EXTERN_C
ImpellerImageFilter ImpellerImageFilterCreateComposeNew(
    ImpellerImageFilter outer,
    ImpellerImageFilter inner) {
  return ImageFilter::MakeCompose(*GetPeer(outer), *GetPeer(inner)).Leak();
}

void ImpellerPaintSetColorFilter(ImpellerPaint paint,
                                 ImpellerColorFilter color_filter) {
  GetPeer(paint)->SetColorFilter(*GetPeer(color_filter));
}

void ImpellerPaintSetColorSource(ImpellerPaint paint,
                                 ImpellerColorSource color_source) {
  GetPeer(paint)->SetColorSource(*GetPeer(color_source));
}

void ImpellerPaintSetImageFilter(ImpellerPaint paint,
                                 ImpellerImageFilter image_filter) {
  GetPeer(paint)->SetImageFilter(*GetPeer(image_filter));
}

void ImpellerPaintSetMaskFilter(ImpellerPaint paint,
                                ImpellerMaskFilter mask_filter) {
  GetPeer(paint)->SetMaskFilter(*GetPeer(mask_filter));
}

}  // namespace impeller::interop

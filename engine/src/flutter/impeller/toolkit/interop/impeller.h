// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TOOLKIT_INTEROP_IMPELLER_H_
#define FLUTTER_IMPELLER_TOOLKIT_INTEROP_IMPELLER_H_

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#if defined(__cplusplus)
#define IMPELLER_EXTERN_C extern "C"
#define IMPELLER_EXTERN_C_BEGIN IMPELLER_EXTERN_C {
#define IMPELLER_EXTERN_C_END }
#else  // defined(__cplusplus)
#define IMPELLER_EXTERN_C
#define IMPELLER_EXTERN_C_BEGIN
#define IMPELLER_EXTERN_C_END
#endif  // defined(__cplusplus)

#ifdef _WIN32
#define IMPELLER_EXPORT_DECORATION __declspec(dllexport)
#else
#define IMPELLER_EXPORT_DECORATION __attribute__((visibility("default")))
#endif

#ifndef IMPELLER_NO_EXPORT
#define IMPELLER_EXPORT IMPELLER_EXPORT_DECORATION
#else  // IMPELLER_NO_EXPORT
#define IMPELLER_EXPORT
#endif  // IMPELLER_NO_EXPORT

#ifdef __clang__
#define IMPELLER_NULLABLE _Nullable
#define IMPELLER_NONNULL _Nonnull
#else  // __clang__
#define IMPELLER_NULLABLE
#define IMPELLER_NONNULL
#endif  // __clang__

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 202000L)
#define IMPELLER_NODISCARD [[nodiscard]]
#else  // defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 202000L)
#define IMPELLER_NODISCARD
#endif  // defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 202000L)

IMPELLER_EXTERN_C_BEGIN

//------------------------------------------------------------------------------
// Versioning
//------------------------------------------------------------------------------

#define IMPELLER_MAKE_VERSION(variant, major, minor, patch)        \
  ((((uint32_t)(variant)) << 29U) | (((uint32_t)(major)) << 22U) | \
   (((uint32_t)(minor)) << 12U) | ((uint32_t)(patch)))

#define IMPELLER_VERSION_VARIANT 1
#define IMPELLER_VERSION_MAJOR 1
#define IMPELLER_VERSION_MINOR 2
#define IMPELLER_VERSION_PATCH 0

#define IMPELLER_VERSION                                                  \
  IMPELLER_MAKE_VERSION(IMPELLER_VERSION_VARIANT, IMPELLER_VERSION_MAJOR, \
                        IMPELLER_VERSION_MINOR, IMPELLER_VERSION_PATCH)

#define IMPELLER_VERSION_GET_VARIANT(version) ((uint32_t)(version) >> 29U)
#define IMPELLER_VERSION_GET_MAJOR(version) \
  (((uint32_t)(version) >> 22U) & 0x7FU)
#define IMPELLER_VERSION_GET_MINOR(version) \
  (((uint32_t)(version) >> 12U) & 0x3FFU)
#define IMPELLER_VERSION_GET_PATCH(version) ((uint32_t)(version) & 0xFFFU)

//------------------------------------------------------------------------------
// Handles
//------------------------------------------------------------------------------

#define IMPELLER_INTERNAL_HANDLE_NAME(handle) handle##_
#define IMPELLER_DEFINE_HANDLE(handle) \
  typedef struct IMPELLER_INTERNAL_HANDLE_NAME(handle) * handle;

IMPELLER_DEFINE_HANDLE(ImpellerColorFilter);
IMPELLER_DEFINE_HANDLE(ImpellerColorSource);
IMPELLER_DEFINE_HANDLE(ImpellerContext);
IMPELLER_DEFINE_HANDLE(ImpellerDisplayList);
IMPELLER_DEFINE_HANDLE(ImpellerDisplayListBuilder);
IMPELLER_DEFINE_HANDLE(ImpellerImageFilter);
IMPELLER_DEFINE_HANDLE(ImpellerMaskFilter);
IMPELLER_DEFINE_HANDLE(ImpellerPaint);
IMPELLER_DEFINE_HANDLE(ImpellerParagraph);
IMPELLER_DEFINE_HANDLE(ImpellerParagraphBuilder);
IMPELLER_DEFINE_HANDLE(ImpellerParagraphStyle);
IMPELLER_DEFINE_HANDLE(ImpellerPath);
IMPELLER_DEFINE_HANDLE(ImpellerPathBuilder);
IMPELLER_DEFINE_HANDLE(ImpellerSurface);
IMPELLER_DEFINE_HANDLE(ImpellerTexture);
IMPELLER_DEFINE_HANDLE(ImpellerTypographyContext);

//------------------------------------------------------------------------------
// Signatures
//------------------------------------------------------------------------------

typedef void (*ImpellerCallback)(void* IMPELLER_NULLABLE user_data);
typedef void* IMPELLER_NULLABLE (*ImpellerProcAddressCallback)(
    const char* IMPELLER_NONNULL proc_name,
    void* IMPELLER_NULLABLE user_data);

//------------------------------------------------------------------------------
// Enumerations
//------------------------------------------------------------------------------
typedef enum ImpellerFillType {
  kImpellerFillTypeNonZero,
  kImpellerFillTypeOdd,
} ImpellerFillType;

typedef enum ImpellerClipOperation {
  kImpellerClipOperationDifference,
  kImpellerClipOperationIntersect,
} ImpellerClipOperation;

typedef enum ImpellerBlendMode {
  kImpellerBlendModeClear,
  kImpellerBlendModeSource,
  kImpellerBlendModeDestination,
  kImpellerBlendModeSourceOver,
  kImpellerBlendModeDestinationOver,
  kImpellerBlendModeSourceIn,
  kImpellerBlendModeDestinationIn,
  kImpellerBlendModeSourceOut,
  kImpellerBlendModeDestinationOut,
  kImpellerBlendModeSourceATop,
  kImpellerBlendModeDestinationATop,
  kImpellerBlendModeXor,
  kImpellerBlendModePlus,
  kImpellerBlendModeModulate,
  kImpellerBlendModeScreen,
  kImpellerBlendModeOverlay,
  kImpellerBlendModeDarken,
  kImpellerBlendModeLighten,
  kImpellerBlendModeColorDodge,
  kImpellerBlendModeColorBurn,
  kImpellerBlendModeHardLight,
  kImpellerBlendModeSoftLight,
  kImpellerBlendModeDifference,
  kImpellerBlendModeExclusion,
  kImpellerBlendModeMultiply,
  kImpellerBlendModeHue,
  kImpellerBlendModeSaturation,
  kImpellerBlendModeColor,
  kImpellerBlendModeLuminosity,
} ImpellerBlendMode;

typedef enum ImpellerDrawStyle {
  kImpellerDrawStyleFill,
  kImpellerDrawStyleStroke,
  kImpellerDrawStyleStrokeAndFill,
} ImpellerDrawStyle;

typedef enum ImpellerStrokeCap {
  kImpellerStrokeCapButt,
  kImpellerStrokeCapRound,
  kImpellerStrokeCapSquare,
} ImpellerStrokeCap;

typedef enum ImpellerStrokeJoin {
  kImpellerStrokeJoinMiter,
  kImpellerStrokeJoinRound,
  kImpellerStrokeJoinBevel,
} ImpellerStrokeJoin;

typedef enum ImpellerPixelFormat {
  kImpellerPixelFormatRGBA8888,
} ImpellerPixelFormat;

typedef enum ImpellerTextureSampling {
  kImpellerTextureSamplingNearestNeighbor,
  kImpellerTextureSamplingLinear,
} ImpellerTextureSampling;

typedef enum ImpellerTileMode {
  kImpellerTileModeClamp,
  kImpellerTileModeRepeat,
  kImpellerTileModeMirror,
  kImpellerTileModeDecal,
} ImpellerTileMode;

typedef enum ImpellerBlurStyle {
  kImpellerBlurStyleNormal,
  kImpellerBlurStyleSolid,
  kImpellerBlurStyleOuter,
  kImpellerBlurStyleInner,
} ImpellerBlurStyle;

typedef enum ImpellerColorSpace {
  kImpellerColorSpaceSRGB,
  kImpellerColorSpaceExtendedSRGB,
  kImpellerColorSpaceDisplayP3,
} ImpellerColorSpace;

typedef enum ImpellerFontWeight {
  kImpellerFontWeight100,  // Thin
  kImpellerFontWeight200,  // Extra-Light
  kImpellerFontWeight300,  // Light
  kImpellerFontWeight400,  // Normal/Regular
  kImpellerFontWeight500,  // Medium
  kImpellerFontWeight600,  // Semi-bold
  kImpellerFontWeight700,  // Bold
  kImpellerFontWeight800,  // Extra-Bold
  kImpellerFontWeight900,  // Black
} ImpellerFontWeight;

typedef enum ImpellerFontStyle {
  kImpellerFontStyleNormal,
  kImpellerFontStyleItalic,
} ImpellerFontStyle;

typedef enum ImpellerTextAlignment {
  kImpellerTextAlignmentLeft,
  kImpellerTextAlignmentRight,
  kImpellerTextAlignmentCenter,
  kImpellerTextAlignmentJustify,
  kImpellerTextAlignmentStart,
  kImpellerTextAlignmentEnd,
} ImpellerTextAlignment;

typedef enum ImpellerTextDirection {
  kImpellerTextDirectionRTL,
  kImpellerTextDirectionLTR,
} ImpellerTextDirection;

//------------------------------------------------------------------------------
// Non-opaque structs
//------------------------------------------------------------------------------
typedef struct ImpellerRect {
  float x;
  float y;
  float width;
  float height;
} ImpellerRect;

typedef struct ImpellerPoint {
  float x;
  float y;
} ImpellerPoint;

typedef struct ImpellerSize {
  float width;
  float height;
} ImpellerSize;

typedef struct ImpellerISize {
  int64_t width;
  int64_t height;
} ImpellerISize;

typedef struct ImpellerMatrix {
  float m[16];
} ImpellerMatrix;

typedef struct ImpellerColorMatrix {
  float m[20];
} ImpellerColorMatrix;

typedef struct ImpellerRoundingRadii {
  ImpellerPoint top_left;
  ImpellerPoint bottom_left;
  ImpellerPoint top_right;
  ImpellerPoint bottom_right;
} ImpellerRoundingRadii;

typedef struct ImpellerColor {
  float red;
  float green;
  float blue;
  float alpha;
  ImpellerColorSpace color_space;
} ImpellerColor;

typedef struct ImpellerTextureDescriptor {
  ImpellerPixelFormat pixel_format;
  ImpellerISize size;
  uint32_t mip_count;
} ImpellerTextureDescriptor;

typedef struct ImpellerMapping {
  const uint8_t* IMPELLER_NONNULL data;
  uint64_t length;
  ImpellerCallback IMPELLER_NULLABLE on_release;
} ImpellerMapping;

//------------------------------------------------------------------------------
// Version
//------------------------------------------------------------------------------

IMPELLER_EXPORT
uint32_t ImpellerGetVersion();

//------------------------------------------------------------------------------
// Context
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerContext IMPELLER_NULLABLE
ImpellerContextCreateOpenGLESNew(
    uint32_t version,
    ImpellerProcAddressCallback IMPELLER_NONNULL gl_proc_address_callback,
    void* IMPELLER_NULLABLE gl_proc_address_callback_user_data);

IMPELLER_EXPORT
void ImpellerContextRetain(ImpellerContext IMPELLER_NULLABLE context);

IMPELLER_EXPORT
void ImpellerContextRelease(ImpellerContext IMPELLER_NULLABLE context);

//------------------------------------------------------------------------------
// Surface
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerSurface IMPELLER_NULLABLE
ImpellerSurfaceCreateWrappedFBONew(ImpellerContext IMPELLER_NULLABLE context,
                                   uint64_t fbo,
                                   ImpellerPixelFormat format,
                                   const ImpellerISize* IMPELLER_NULLABLE size);

IMPELLER_EXPORT
void ImpellerSurfaceRetain(ImpellerSurface IMPELLER_NULLABLE surface);

IMPELLER_EXPORT
void ImpellerSurfaceRelease(ImpellerSurface IMPELLER_NULLABLE surface);

IMPELLER_EXPORT
bool ImpellerSurfaceDrawDisplayList(
    ImpellerSurface IMPELLER_NULLABLE surface,
    ImpellerDisplayList IMPELLER_NONNULL display_list);

//------------------------------------------------------------------------------
// Path
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerPathRetain(ImpellerPath IMPELLER_NULLABLE path);

IMPELLER_EXPORT
void ImpellerPathRelease(ImpellerPath IMPELLER_NULLABLE path);

//------------------------------------------------------------------------------
// Path Builder
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerPathBuilder IMPELLER_NULLABLE
ImpellerPathBuilderNew();

IMPELLER_EXPORT
void ImpellerPathBuilderRetain(ImpellerPathBuilder IMPELLER_NULLABLE builder);

IMPELLER_EXPORT
void ImpellerPathBuilderRelease(ImpellerPathBuilder IMPELLER_NULLABLE builder);

IMPELLER_EXPORT
void ImpellerPathBuilderMoveTo(ImpellerPathBuilder IMPELLER_NONNULL builder,
                               const ImpellerPoint* IMPELLER_NONNULL location);

IMPELLER_EXPORT
void ImpellerPathBuilderLineTo(ImpellerPathBuilder IMPELLER_NONNULL builder,
                               const ImpellerPoint* IMPELLER_NONNULL location);

IMPELLER_EXPORT
void ImpellerPathBuilderQuadraticCurveTo(
    ImpellerPathBuilder IMPELLER_NONNULL builder,
    const ImpellerPoint* IMPELLER_NONNULL control_point,
    const ImpellerPoint* IMPELLER_NONNULL end_point);

IMPELLER_EXPORT
void ImpellerPathBuilderCubicCurveTo(
    ImpellerPathBuilder IMPELLER_NONNULL builder,
    const ImpellerPoint* IMPELLER_NONNULL control_point_1,
    const ImpellerPoint* IMPELLER_NONNULL control_point_2,
    const ImpellerPoint* IMPELLER_NONNULL end_point);

IMPELLER_EXPORT
void ImpellerPathBuilderAddRect(ImpellerPathBuilder IMPELLER_NONNULL builder,
                                const ImpellerRect* IMPELLER_NONNULL rect);

IMPELLER_EXPORT
void ImpellerPathBuilderAddArc(ImpellerPathBuilder IMPELLER_NONNULL builder,
                               const ImpellerRect* IMPELLER_NONNULL oval_bounds,
                               float start_angle_degrees,
                               float end_angle_degrees);

IMPELLER_EXPORT
void ImpellerPathBuilderAddOval(
    ImpellerPathBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL oval_bounds);

IMPELLER_EXPORT
void ImpellerPathBuilderAddRoundedRect(
    ImpellerPathBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL rect,
    const ImpellerRoundingRadii* IMPELLER_NONNULL rounding_radii);

IMPELLER_EXPORT
void ImpellerPathBuilderClose(ImpellerPathBuilder IMPELLER_NONNULL builder);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerPath IMPELLER_NULLABLE
ImpellerPathBuilderCopyPathNew(ImpellerPathBuilder IMPELLER_NONNULL builder,
                               ImpellerFillType fill);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerPath IMPELLER_NULLABLE
ImpellerPathBuilderTakePathNew(ImpellerPathBuilder IMPELLER_NONNULL builder,
                               ImpellerFillType fill);

//------------------------------------------------------------------------------
// Paint
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerPaint IMPELLER_NULLABLE
ImpellerPaintNew();

IMPELLER_EXPORT
void ImpellerPaintRetain(ImpellerPaint IMPELLER_NULLABLE paint);

IMPELLER_EXPORT
void ImpellerPaintRelease(ImpellerPaint IMPELLER_NULLABLE paint);

IMPELLER_EXPORT
void ImpellerPaintSetColor(ImpellerPaint IMPELLER_NONNULL paint,
                           const ImpellerColor* IMPELLER_NONNULL color);

IMPELLER_EXPORT
void ImpellerPaintSetBlendMode(ImpellerPaint IMPELLER_NONNULL paint,
                               ImpellerBlendMode mode);

IMPELLER_EXPORT
void ImpellerPaintSetDrawStyle(ImpellerPaint IMPELLER_NONNULL paint,
                               ImpellerDrawStyle style);

IMPELLER_EXPORT
void ImpellerPaintSetStrokeCap(ImpellerPaint IMPELLER_NONNULL paint,
                               ImpellerStrokeCap cap);

IMPELLER_EXPORT
void ImpellerPaintSetStrokeJoin(ImpellerPaint IMPELLER_NONNULL paint,
                                ImpellerStrokeJoin join);

IMPELLER_EXPORT
void ImpellerPaintSetStrokeWidth(ImpellerPaint IMPELLER_NONNULL paint,
                                 float width);

IMPELLER_EXPORT
void ImpellerPaintSetStrokeMiter(ImpellerPaint IMPELLER_NONNULL paint,
                                 float miter);

IMPELLER_EXPORT
void ImpellerPaintSetColorFilter(
    ImpellerPaint IMPELLER_NONNULL paint,
    ImpellerColorFilter IMPELLER_NONNULL color_filter);

IMPELLER_EXPORT
void ImpellerPaintSetColorSource(
    ImpellerPaint IMPELLER_NONNULL paint,
    ImpellerColorSource IMPELLER_NONNULL color_source);

IMPELLER_EXPORT
void ImpellerPaintSetImageFilter(
    ImpellerPaint IMPELLER_NONNULL paint,
    ImpellerImageFilter IMPELLER_NONNULL image_filter);

IMPELLER_EXPORT
void ImpellerPaintSetMaskFilter(
    ImpellerPaint IMPELLER_NONNULL paint,
    ImpellerMaskFilter IMPELLER_NONNULL mask_filter);

//------------------------------------------------------------------------------
// Texture
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerTexture IMPELLER_NULLABLE
ImpellerTextureCreateWithContentsNew(
    ImpellerContext IMPELLER_NONNULL context,
    const ImpellerTextureDescriptor* IMPELLER_NONNULL descriptor,
    const ImpellerMapping* IMPELLER_NONNULL contents,
    void* IMPELLER_NULLABLE contents_on_release_user_data);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerTexture IMPELLER_NULLABLE
ImpellerTextureCreateWithOpenGLTextureHandleNew(
    ImpellerContext IMPELLER_NONNULL context,
    const ImpellerTextureDescriptor* IMPELLER_NONNULL descriptor,
    uint64_t handle  // transfer-in ownership
);

IMPELLER_EXPORT
void ImpellerTextureRetain(ImpellerTexture IMPELLER_NULLABLE texture);

IMPELLER_EXPORT
void ImpellerTextureRelease(ImpellerTexture IMPELLER_NULLABLE texture);

IMPELLER_EXPORT
uint64_t ImpellerTextureGetOpenGLHandle(
    ImpellerTexture IMPELLER_NONNULL texture);

//------------------------------------------------------------------------------
// Color Sources
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerColorSourceRetain(
    ImpellerColorSource IMPELLER_NULLABLE color_source);

IMPELLER_EXPORT
void ImpellerColorSourceRelease(
    ImpellerColorSource IMPELLER_NULLABLE color_source);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerColorSource IMPELLER_NULLABLE
ImpellerColorSourceCreateLinearGradientNew(
    const ImpellerPoint* IMPELLER_NONNULL start_point,
    const ImpellerPoint* IMPELLER_NONNULL end_point,
    uint32_t stop_count,
    const ImpellerColor* IMPELLER_NONNULL colors,
    const float* IMPELLER_NONNULL stops,
    ImpellerTileMode tile_mode,
    const ImpellerMatrix* IMPELLER_NULLABLE transformation);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerColorSource IMPELLER_NULLABLE
ImpellerColorSourceCreateRadialGradientNew(
    const ImpellerPoint* IMPELLER_NONNULL center,
    float radius,
    uint32_t stop_count,
    const ImpellerColor* IMPELLER_NONNULL colors,
    const float* IMPELLER_NONNULL stops,
    ImpellerTileMode tile_mode,
    const ImpellerMatrix* IMPELLER_NULLABLE transformation);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerColorSource IMPELLER_NULLABLE
ImpellerColorSourceCreateConicalGradientNew(
    const ImpellerPoint* IMPELLER_NONNULL start_center,
    float start_radius,
    const ImpellerPoint* IMPELLER_NONNULL end_center,
    float end_radius,
    uint32_t stop_count,
    const ImpellerColor* IMPELLER_NONNULL colors,
    const float* IMPELLER_NONNULL stops,
    ImpellerTileMode tile_mode,
    const ImpellerMatrix* IMPELLER_NULLABLE transformation);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerColorSource IMPELLER_NULLABLE
ImpellerColorSourceCreateSweepGradientNew(
    const ImpellerPoint* IMPELLER_NONNULL center,
    float start,
    float end,
    uint32_t stop_count,
    const ImpellerColor* IMPELLER_NONNULL colors,
    const float* IMPELLER_NONNULL stops,
    ImpellerTileMode tile_mode,
    const ImpellerMatrix* IMPELLER_NULLABLE transformation);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerColorSource IMPELLER_NULLABLE
ImpellerColorSourceCreateImageNew(
    ImpellerTexture IMPELLER_NONNULL image,
    ImpellerTileMode horizontal_tile_mode,
    ImpellerTileMode vertical_tile_mode,
    ImpellerTextureSampling sampling,
    const ImpellerMatrix* IMPELLER_NULLABLE transformation);

//------------------------------------------------------------------------------
// Color Filters
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerColorFilterRetain(
    ImpellerColorFilter IMPELLER_NULLABLE color_filter);

IMPELLER_EXPORT
void ImpellerColorFilterRelease(
    ImpellerColorFilter IMPELLER_NULLABLE color_filter);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerColorFilter IMPELLER_NULLABLE
ImpellerColorFilterCreateBlendNew(const ImpellerColor* IMPELLER_NONNULL color,
                                  ImpellerBlendMode blend_mode);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerColorFilter IMPELLER_NULLABLE
ImpellerColorFilterCreateColorMatrixNew(
    const ImpellerColorMatrix* IMPELLER_NONNULL color_matrix);

//------------------------------------------------------------------------------
// Mask Filters
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerMaskFilterRetain(ImpellerMaskFilter IMPELLER_NULLABLE mask_filter);

IMPELLER_EXPORT
void ImpellerMaskFilterRelease(
    ImpellerMaskFilter IMPELLER_NULLABLE mask_filter);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerMaskFilter IMPELLER_NULLABLE
ImpellerMaskFilterCreateBlurNew(ImpellerBlurStyle style, float sigma);

//------------------------------------------------------------------------------
// Image Filters
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerImageFilterRetain(
    ImpellerImageFilter IMPELLER_NULLABLE image_filter);

IMPELLER_EXPORT
void ImpellerImageFilterRelease(
    ImpellerImageFilter IMPELLER_NULLABLE image_filter);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerImageFilter IMPELLER_NULLABLE
ImpellerImageFilterCreateBlurNew(float x_sigma,
                                 float y_sigma,
                                 ImpellerTileMode tile_mode);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerImageFilter IMPELLER_NULLABLE
ImpellerImageFilterCreateDilateNew(float x_radius, float y_radius);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerImageFilter IMPELLER_NULLABLE
ImpellerImageFilterCreateErodeNew(float x_radius, float y_radius);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerImageFilter IMPELLER_NULLABLE
ImpellerImageFilterCreateMatrixNew(
    const ImpellerMatrix* IMPELLER_NONNULL matrix,
    ImpellerTextureSampling sampling);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerImageFilter IMPELLER_NULLABLE
ImpellerImageFilterCreateComposeNew(ImpellerImageFilter IMPELLER_NONNULL outer,
                                    ImpellerImageFilter IMPELLER_NONNULL inner);

//------------------------------------------------------------------------------
// Display List
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerDisplayListRetain(
    ImpellerDisplayList IMPELLER_NULLABLE display_list);

IMPELLER_EXPORT
void ImpellerDisplayListRelease(
    ImpellerDisplayList IMPELLER_NULLABLE display_list);

//------------------------------------------------------------------------------
// Display List Builder
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerDisplayListBuilder IMPELLER_NULLABLE
ImpellerDisplayListBuilderNew(const ImpellerRect* IMPELLER_NULLABLE cull_rect);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderRetain(
    ImpellerDisplayListBuilder IMPELLER_NULLABLE builder);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderRelease(
    ImpellerDisplayListBuilder IMPELLER_NULLABLE builder);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerDisplayList IMPELLER_NULLABLE
ImpellerDisplayListBuilderCreateDisplayListNew(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder);

//------------------------------------------------------------------------------
// Display List Builder: Managing the transformation stack.
//------------------------------------------------------------------------------
IMPELLER_EXPORT
void ImpellerDisplayListBuilderSave(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderSaveLayer(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL bounds,
    ImpellerPaint IMPELLER_NULLABLE paint,
    ImpellerImageFilter IMPELLER_NULLABLE backdrop);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderRestore(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderScale(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    float x_scale,
    float y_scale);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderRotate(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    float angle_degrees);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderTranslate(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    float x_translation,
    float y_translation);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderSetTransform(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerMatrix* IMPELLER_NONNULL transform);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderGetTransform(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    ImpellerMatrix* IMPELLER_NONNULL out_transform);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderResetTransform(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder);

IMPELLER_EXPORT
uint32_t ImpellerDisplayListBuilderGetSaveCount(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderRestoreToCount(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    uint32_t count);

//------------------------------------------------------------------------------
// Display List Builder: Clipping
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerDisplayListBuilderClipRect(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL rect,
    ImpellerClipOperation op);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderClipOval(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL oval_bounds,
    ImpellerClipOperation op);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderClipRoundedRect(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL rect,
    const ImpellerRoundingRadii* IMPELLER_NONNULL radii,
    ImpellerClipOperation op);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderClipPath(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    ImpellerPath IMPELLER_NONNULL path,
    ImpellerClipOperation op);

//------------------------------------------------------------------------------
// Display List Builder: Drawing Shapes
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawPaint(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawLine(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerPoint* IMPELLER_NONNULL from,
    const ImpellerPoint* IMPELLER_NONNULL to,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawDashedLine(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerPoint* IMPELLER_NONNULL from,
    const ImpellerPoint* IMPELLER_NONNULL to,
    float on_length,
    float off_length,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawRect(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL rect,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawOval(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL oval_bounds,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawRoundedRect(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL rect,
    const ImpellerRoundingRadii* IMPELLER_NONNULL radii,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawRoundedRectDifference(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    const ImpellerRect* IMPELLER_NONNULL outer_rect,
    const ImpellerRoundingRadii* IMPELLER_NONNULL outer_radii,
    const ImpellerRect* IMPELLER_NONNULL inner_rect,
    const ImpellerRoundingRadii* IMPELLER_NONNULL inner_radii,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawPath(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    ImpellerPath IMPELLER_NONNULL path,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawDisplayList(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    ImpellerDisplayList IMPELLER_NONNULL display_list,
    float opacity);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawParagraph(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    ImpellerParagraph IMPELLER_NONNULL paragraph,
    const ImpellerPoint* IMPELLER_NONNULL point);

//------------------------------------------------------------------------------
// Display List Builder: Drawing Textures
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawTexture(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    ImpellerTexture IMPELLER_NONNULL texture,
    const ImpellerPoint* IMPELLER_NONNULL point,
    ImpellerTextureSampling sampling,
    ImpellerPaint IMPELLER_NULLABLE paint);

IMPELLER_EXPORT
void ImpellerDisplayListBuilderDrawTextureRect(
    ImpellerDisplayListBuilder IMPELLER_NONNULL builder,
    ImpellerTexture IMPELLER_NONNULL texture,
    const ImpellerRect* IMPELLER_NONNULL src_rect,
    const ImpellerRect* IMPELLER_NONNULL dst_rect,
    ImpellerTextureSampling sampling,
    ImpellerPaint IMPELLER_NULLABLE paint);

//------------------------------------------------------------------------------
// Typography Context
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerTypographyContext IMPELLER_NULLABLE
ImpellerTypographyContextNew();

IMPELLER_EXPORT
void ImpellerTypographyContextRetain(
    ImpellerTypographyContext IMPELLER_NULLABLE context);

IMPELLER_EXPORT
void ImpellerTypographyContextRelease(
    ImpellerTypographyContext IMPELLER_NULLABLE context);

IMPELLER_EXPORT
bool ImpellerTypographyContextRegisterFont(
    ImpellerTypographyContext IMPELLER_NONNULL context,
    const ImpellerMapping* IMPELLER_NONNULL contents,
    void* IMPELLER_NULLABLE contents_on_release_user_data,
    const char* IMPELLER_NULLABLE family_name_alias);

//------------------------------------------------------------------------------
// Paragraph Style
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerParagraphStyle IMPELLER_NULLABLE
ImpellerParagraphStyleNew();

IMPELLER_EXPORT
void ImpellerParagraphStyleRetain(
    ImpellerParagraphStyle IMPELLER_NULLABLE paragraph_style);

IMPELLER_EXPORT
void ImpellerParagraphStyleRelease(
    ImpellerParagraphStyle IMPELLER_NULLABLE paragraph_style);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetForeground(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetBackground(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    ImpellerPaint IMPELLER_NONNULL paint);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetFontWeight(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    ImpellerFontWeight weight);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetFontStyle(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    ImpellerFontStyle style);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetFontFamily(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    const char* IMPELLER_NONNULL family_name);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetFontSize(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    float size);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetHeight(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    float height);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetTextAlignment(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    ImpellerTextAlignment align);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetTextDirection(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    ImpellerTextDirection direction);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetMaxLines(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    uint32_t max_lines);

IMPELLER_EXPORT
void ImpellerParagraphStyleSetLocale(
    ImpellerParagraphStyle IMPELLER_NONNULL paragraph_style,
    const char* IMPELLER_NONNULL locale);

//------------------------------------------------------------------------------
// Paragraph Builder
//------------------------------------------------------------------------------

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerParagraphBuilder IMPELLER_NULLABLE
ImpellerParagraphBuilderNew(ImpellerTypographyContext IMPELLER_NONNULL context);

IMPELLER_EXPORT
void ImpellerParagraphBuilderRetain(
    ImpellerParagraphBuilder IMPELLER_NULLABLE paragraph_builder);

IMPELLER_EXPORT
void ImpellerParagraphBuilderRelease(
    ImpellerParagraphBuilder IMPELLER_NULLABLE paragraph_builder);

IMPELLER_EXPORT
void ImpellerParagraphBuilderPushStyle(
    ImpellerParagraphBuilder IMPELLER_NONNULL paragraph_builder,
    ImpellerParagraphStyle IMPELLER_NONNULL style);

IMPELLER_EXPORT
void ImpellerParagraphBuilderPopStyle(
    ImpellerParagraphBuilder IMPELLER_NONNULL paragraph_builder);

IMPELLER_EXPORT
void ImpellerParagraphBuilderAddText(
    ImpellerParagraphBuilder IMPELLER_NONNULL paragraph_builder,
    const uint8_t* IMPELLER_NULLABLE data,
    uint32_t length);

IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerParagraph IMPELLER_NULLABLE
ImpellerParagraphBuilderBuildParagraphNew(
    ImpellerParagraphBuilder IMPELLER_NONNULL paragraph_builder,
    float width);

//------------------------------------------------------------------------------
// Paragraph
//------------------------------------------------------------------------------

IMPELLER_EXPORT
void ImpellerParagraphRetain(ImpellerParagraph IMPELLER_NULLABLE paragraph);

IMPELLER_EXPORT
void ImpellerParagraphRelease(ImpellerParagraph IMPELLER_NULLABLE paragraph);

IMPELLER_EXPORT
float ImpellerParagraphGetMaxWidth(
    ImpellerParagraph IMPELLER_NONNULL paragraph);

IMPELLER_EXPORT
float ImpellerParagraphGetHeight(ImpellerParagraph IMPELLER_NONNULL paragraph);

IMPELLER_EXPORT
float ImpellerParagraphGetLongestLineWidth(
    ImpellerParagraph IMPELLER_NONNULL paragraph);

IMPELLER_EXPORT
float ImpellerParagraphGetMinIntrinsicWidth(
    ImpellerParagraph IMPELLER_NONNULL paragraph);

IMPELLER_EXPORT
float ImpellerParagraphGetMaxIntrinsicWidth(
    ImpellerParagraph IMPELLER_NONNULL paragraph);

IMPELLER_EXPORT
float ImpellerParagraphGetIdeographicBaseline(
    ImpellerParagraph IMPELLER_NONNULL paragraph);

IMPELLER_EXPORT
float ImpellerParagraphGetAlphabeticBaseline(
    ImpellerParagraph IMPELLER_NONNULL paragraph);

IMPELLER_EXPORT
uint32_t ImpellerParagraphGetLineCount(
    ImpellerParagraph IMPELLER_NONNULL paragraph);

IMPELLER_EXTERN_C_END

#endif  // FLUTTER_IMPELLER_TOOLKIT_INTEROP_IMPELLER_H_

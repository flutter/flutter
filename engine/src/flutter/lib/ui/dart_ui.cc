// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/dart_ui.h"

#include <mutex>
#include <string_view>

#include "flutter/common/settings.h"
#include "flutter/fml/build_config.h"
#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/compositing/scene_builder.h"
#include "flutter/lib/ui/dart_runtime_hooks.h"
#include "flutter/lib/ui/gpu/context.h"
#include "flutter/lib/ui/isolate_name_server/isolate_name_server_natives.h"
#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/painting/codec.h"
#include "flutter/lib/ui/painting/color_filter.h"
#include "flutter/lib/ui/painting/engine_layer.h"
#include "flutter/lib/ui/painting/fragment_program.h"
#include "flutter/lib/ui/painting/fragment_shader.h"
#include "flutter/lib/ui/painting/gradient.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/image_descriptor.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/image_shader.h"
#include "flutter/lib/ui/painting/immutable_buffer.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/path_measure.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/painting/picture_recorder.h"
#include "flutter/lib/ui/painting/vertices.h"
#include "flutter/lib/ui/semantics/semantics_update.h"
#include "flutter/lib/ui/semantics/semantics_update_builder.h"
#include "flutter/lib/ui/semantics/string_attribute.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/lib/ui/text/paragraph.h"
#include "flutter/lib/ui/text/paragraph_builder.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/logging/dart_error.h"

#ifdef IMPELLER_ENABLE_3D
#include "flutter/lib/ui/painting/scene/scene_node.h"
#include "flutter/lib/ui/painting/scene/scene_shader.h"
#endif  // IMPELLER_ENABLE_3D

using tonic::ToDart;

namespace flutter {

typedef CanvasImage Image;
typedef CanvasPathMeasure PathMeasure;
typedef CanvasGradient Gradient;
typedef CanvasPath Path;

// List of native static functions used as @Native functions.
// Items are tuples of ('function_name', 'parameter_count'), where:
//   'function_name' is the fully qualified name of the native function.
//   'parameter_count' is the number of parameters the function has.
//
// These are used to:
// - Instantiate FfiDispatcher templates to automatically create FFI Native
//   bindings.
//   If the name does not match a native function, the template will fail to
//   instatiate, resulting in a compile time error.
// - Resolve the native function pointer associated with an @Native function.
//   If there is a mismatch between name or parameter count an @Native is
//   trying to resolve, an exception will be thrown.
#define FFI_FUNCTION_LIST(V)                                          \
  /* Constructors */                                                  \
  V(Canvas::Create, 6)                                                \
  V(ColorFilter::Create, 1)                                           \
  V(FragmentProgram::Create, 1)                                       \
  V(ReusableFragmentShader::Create, 4)                                \
  V(Gradient::Create, 1)                                              \
  V(ImageFilter::Create, 1)                                           \
  V(ImageShader::Create, 1)                                           \
  V(ParagraphBuilder::Create, 9)                                      \
  V(PathMeasure::Create, 3)                                           \
  V(Path::Create, 1)                                                  \
  V(PictureRecorder::Create, 1)                                       \
  V(SceneBuilder::Create, 1)                                          \
  V(SemanticsUpdateBuilder::Create, 1)                                \
  /* Other */                                                         \
  V(FontCollection::LoadFontFromList, 3)                              \
  V(ImageDescriptor::initEncoded, 3)                                  \
  V(ImmutableBuffer::init, 3)                                         \
  V(ImmutableBuffer::initFromAsset, 3)                                \
  V(ImmutableBuffer::initFromFile, 3)                                 \
  V(ImageDescriptor::initRaw, 6)                                      \
  V(IsolateNameServerNatives::LookupPortByName, 1)                    \
  V(IsolateNameServerNatives::RegisterPortWithName, 2)                \
  V(IsolateNameServerNatives::RemovePortNameMapping, 1)               \
  V(NativeStringAttribute::initLocaleStringAttribute, 4)              \
  V(NativeStringAttribute::initSpellOutStringAttribute, 3)            \
  V(PlatformConfigurationNativeApi::ImplicitViewEnabled, 0)           \
  V(PlatformConfigurationNativeApi::DefaultRouteName, 0)              \
  V(PlatformConfigurationNativeApi::ScheduleFrame, 0)                 \
  V(PlatformConfigurationNativeApi::Render, 1)                        \
  V(PlatformConfigurationNativeApi::UpdateSemantics, 1)               \
  V(PlatformConfigurationNativeApi::SetNeedsReportTimings, 1)         \
  V(PlatformConfigurationNativeApi::SetIsolateDebugName, 1)           \
  V(PlatformConfigurationNativeApi::RequestDartPerformanceMode, 1)    \
  V(PlatformConfigurationNativeApi::GetPersistentIsolateData, 0)      \
  V(PlatformConfigurationNativeApi::ComputePlatformResolvedLocale, 1) \
  V(PlatformConfigurationNativeApi::SendPlatformMessage, 3)           \
  V(PlatformConfigurationNativeApi::RespondToPlatformMessage, 2)      \
  V(PlatformConfigurationNativeApi::GetRootIsolateToken, 0)           \
  V(PlatformConfigurationNativeApi::RegisterBackgroundIsolate, 1)     \
  V(PlatformConfigurationNativeApi::SendPortPlatformMessage, 4)       \
  V(DartRuntimeHooks::Logger_PrintDebugString, 1)                     \
  V(DartRuntimeHooks::Logger_PrintString, 1)                          \
  V(DartRuntimeHooks::ScheduleMicrotask, 1)                           \
  V(DartRuntimeHooks::GetCallbackHandle, 1)                           \
  V(DartRuntimeHooks::GetCallbackFromHandle, 1)                       \
  V(DartPluginRegistrant_EnsureInitialized, 0)                        \
  V(Vertices::init, 6)

// List of native instance methods used as @Native functions.
// Items are tuples of ('class_name', 'method_name', 'parameter_count'), where:
//   'class_name' is the name of the class containing the method.
//   'method_name' is the name of the method.
//   'parameter_count' is the number of parameters the method has including the
//                     implicit `this` parameter.
//
// These are used to:
// - Instantiate FfiDispatcher templates to automatically create FFI Native
//   bindings.
//   If the name does not match a native function, the template will fail to
//   instatiate, resulting in a compile time error.
// - Resolve the native function pointer associated with an @Native function.
//   If there is a mismatch between names or parameter count an @Native is
//   trying to resolve, an exception will be thrown.
#define FFI_METHOD_LIST(V)                             \
  V(Canvas, clipPath, 3)                               \
  V(Canvas, clipRect, 7)                               \
  V(Canvas, clipRRect, 3)                              \
  V(Canvas, drawArc, 10)                               \
  V(Canvas, drawAtlas, 10)                             \
  V(Canvas, drawCircle, 6)                             \
  V(Canvas, drawColor, 3)                              \
  V(Canvas, drawDRRect, 5)                             \
  V(Canvas, drawImage, 7)                              \
  V(Canvas, drawImageNine, 13)                         \
  V(Canvas, drawImageRect, 13)                         \
  V(Canvas, drawLine, 7)                               \
  V(Canvas, drawOval, 7)                               \
  V(Canvas, drawPaint, 3)                              \
  V(Canvas, drawPath, 4)                               \
  V(Canvas, drawPicture, 2)                            \
  V(Canvas, drawPoints, 5)                             \
  V(Canvas, drawRRect, 4)                              \
  V(Canvas, drawRect, 7)                               \
  V(Canvas, drawShadow, 5)                             \
  V(Canvas, drawVertices, 5)                           \
  V(Canvas, getDestinationClipBounds, 2)               \
  V(Canvas, getLocalClipBounds, 2)                     \
  V(Canvas, getSaveCount, 1)                           \
  V(Canvas, getTransform, 2)                           \
  V(Canvas, restore, 1)                                \
  V(Canvas, restoreToCount, 2)                         \
  V(Canvas, rotate, 2)                                 \
  V(Canvas, save, 1)                                   \
  V(Canvas, saveLayer, 7)                              \
  V(Canvas, saveLayerWithoutBounds, 3)                 \
  V(Canvas, scale, 3)                                  \
  V(Canvas, skew, 3)                                   \
  V(Canvas, transform, 2)                              \
  V(Canvas, translate, 3)                              \
  V(Codec, dispose, 1)                                 \
  V(Codec, frameCount, 1)                              \
  V(Codec, getNextFrame, 2)                            \
  V(Codec, repetitionCount, 1)                         \
  V(ColorFilter, initLinearToSrgbGamma, 1)             \
  V(ColorFilter, initMatrix, 2)                        \
  V(ColorFilter, initMode, 3)                          \
  V(ColorFilter, initSrgbToLinearGamma, 1)             \
  V(EngineLayer, dispose, 1)                           \
  V(FragmentProgram, initFromAsset, 2)                 \
  V(ReusableFragmentShader, Dispose, 1)                \
  V(ReusableFragmentShader, SetImageSampler, 3)        \
  V(ReusableFragmentShader, ValidateSamplers, 1)       \
  V(Gradient, initLinear, 6)                           \
  V(Gradient, initRadial, 8)                           \
  V(Gradient, initSweep, 9)                            \
  V(Gradient, initTwoPointConical, 11)                 \
  V(Image, dispose, 1)                                 \
  V(Image, width, 1)                                   \
  V(Image, height, 1)                                  \
  V(Image, toByteData, 3)                              \
  V(Image, colorSpace, 1)                              \
  V(ImageDescriptor, bytesPerPixel, 1)                 \
  V(ImageDescriptor, dispose, 1)                       \
  V(ImageDescriptor, height, 1)                        \
  V(ImageDescriptor, instantiateCodec, 4)              \
  V(ImageDescriptor, width, 1)                         \
  V(ImageFilter, initBlur, 4)                          \
  V(ImageFilter, initDilate, 3)                        \
  V(ImageFilter, initErode, 3)                         \
  V(ImageFilter, initColorFilter, 2)                   \
  V(ImageFilter, initComposeFilter, 3)                 \
  V(ImageFilter, initMatrix, 3)                        \
  V(ImageShader, dispose, 1)                           \
  V(ImageShader, initWithImage, 6)                     \
  V(ImmutableBuffer, dispose, 1)                       \
  V(ImmutableBuffer, length, 1)                        \
  V(ParagraphBuilder, addPlaceholder, 6)               \
  V(ParagraphBuilder, addText, 2)                      \
  V(ParagraphBuilder, build, 2)                        \
  V(ParagraphBuilder, pop, 1)                          \
  V(ParagraphBuilder, pushStyle, 16)                   \
  V(Paragraph, alphabeticBaseline, 1)                  \
  V(Paragraph, computeLineMetrics, 1)                  \
  V(Paragraph, didExceedMaxLines, 1)                   \
  V(Paragraph, dispose, 1)                             \
  V(Paragraph, getLineBoundary, 2)                     \
  V(Paragraph, getPositionForOffset, 3)                \
  V(Paragraph, getRectsForPlaceholders, 1)             \
  V(Paragraph, getRectsForRange, 5)                    \
  V(Paragraph, getWordBoundary, 2)                     \
  V(Paragraph, height, 1)                              \
  V(Paragraph, ideographicBaseline, 1)                 \
  V(Paragraph, layout, 2)                              \
  V(Paragraph, longestLine, 1)                         \
  V(Paragraph, maxIntrinsicWidth, 1)                   \
  V(Paragraph, minIntrinsicWidth, 1)                   \
  V(Paragraph, paint, 4)                               \
  V(Paragraph, width, 1)                               \
  V(PathMeasure, setPath, 3)                           \
  V(PathMeasure, getLength, 2)                         \
  V(PathMeasure, getPosTan, 3)                         \
  V(PathMeasure, getSegment, 6)                        \
  V(PathMeasure, isClosed, 2)                          \
  V(PathMeasure, nextContour, 1)                       \
  V(Path, addArc, 7)                                   \
  V(Path, addOval, 5)                                  \
  V(Path, addPath, 4)                                  \
  V(Path, addPathWithMatrix, 5)                        \
  V(Path, addPolygon, 3)                               \
  V(Path, addRRect, 2)                                 \
  V(Path, addRect, 5)                                  \
  V(Path, arcTo, 8)                                    \
  V(Path, arcToPoint, 8)                               \
  V(Path, clone, 2)                                    \
  V(Path, close, 1)                                    \
  V(Path, conicTo, 6)                                  \
  V(Path, contains, 3)                                 \
  V(Path, cubicTo, 7)                                  \
  V(Path, extendWithPath, 4)                           \
  V(Path, extendWithPathAndMatrix, 5)                  \
  V(Path, getBounds, 1)                                \
  V(Path, getFillType, 1)                              \
  V(Path, lineTo, 3)                                   \
  V(Path, moveTo, 3)                                   \
  V(Path, op, 4)                                       \
  V(Path, quadraticBezierTo, 5)                        \
  V(Path, relativeArcToPoint, 8)                       \
  V(Path, relativeConicTo, 6)                          \
  V(Path, relativeCubicTo, 7)                          \
  V(Path, relativeLineTo, 3)                           \
  V(Path, relativeMoveTo, 3)                           \
  V(Path, relativeQuadraticBezierTo, 5)                \
  V(Path, reset, 1)                                    \
  V(Path, setFillType, 2)                              \
  V(Path, shift, 4)                                    \
  V(Path, transform, 3)                                \
  V(PictureRecorder, endRecording, 2)                  \
  V(Picture, GetAllocationSize, 1)                     \
  V(Picture, dispose, 1)                               \
  V(Picture, toImage, 4)                               \
  V(Picture, toImageSync, 4)                           \
  V(SceneBuilder, addPerformanceOverlay, 6)            \
  V(SceneBuilder, addPicture, 5)                       \
  V(SceneBuilder, addPlatformView, 6)                  \
  V(SceneBuilder, addRetained, 2)                      \
  V(SceneBuilder, addTexture, 8)                       \
  V(SceneBuilder, build, 2)                            \
  V(SceneBuilder, pop, 1)                              \
  V(SceneBuilder, pushBackdropFilter, 5)               \
  V(SceneBuilder, pushClipPath, 5)                     \
  V(SceneBuilder, pushClipRRect, 5)                    \
  V(SceneBuilder, pushClipRect, 8)                     \
  V(SceneBuilder, pushColorFilter, 4)                  \
  V(SceneBuilder, pushImageFilter, 4)                  \
  V(SceneBuilder, pushOffset, 5)                       \
  V(SceneBuilder, pushOpacity, 6)                      \
  V(SceneBuilder, pushShaderMask, 10)                  \
  V(SceneBuilder, pushTransformHandle, 4)              \
  V(SceneBuilder, setCheckerboardOffscreenLayers, 2)   \
  V(SceneBuilder, setCheckerboardRasterCacheImages, 2) \
  V(SceneBuilder, setRasterizerTracingThreshold, 2)    \
  V(Scene, dispose, 1)                                 \
  V(Scene, toImage, 4)                                 \
  V(Scene, toImageSync, 4)                             \
  V(SemanticsUpdateBuilder, build, 2)                  \
  V(SemanticsUpdateBuilder, updateCustomAction, 5)     \
  V(SemanticsUpdateBuilder, updateNode, 36)            \
  V(SemanticsUpdate, dispose, 1)                       \
  V(Vertices, dispose, 1)

#ifdef IMPELLER_ENABLE_3D

#define FFI_FUNCTION_LIST_3D(V) \
  V(SceneNode::Create, 1) V(SceneShader::Create, 2)

#define FFI_METHOD_LIST_3D(V)           \
  V(SceneNode, initFromAsset, 3)        \
  V(SceneNode, initFromTransform, 2)    \
  V(SceneNode, AddChild, 2)             \
  V(SceneNode, SetTransform, 2)         \
  V(SceneNode, SetAnimationState, 5)    \
  V(SceneNode, SeekAnimation, 3)        \
  V(SceneShader, SetCameraTransform, 2) \
  V(SceneShader, Dispose, 1)

#define FFI_FUNCTION_LIST_GPU(V) V(GpuContext::InitializeDefault, 1)

#define FFI_METHOD_LIST_GPU(V)

#endif  // IMPELLER_ENABLE_3D

#define FFI_FUNCTION_INSERT(FUNCTION, ARGS)     \
  g_function_dispatchers.insert(std::make_pair( \
      std::string_view(#FUNCTION),              \
      reinterpret_cast<void*>(                  \
          tonic::FfiDispatcher<void, decltype(&FUNCTION), &FUNCTION>::Call)));

#define FFI_METHOD_INSERT(CLASS, METHOD, ARGS)                                 \
  g_function_dispatchers.insert(                                               \
      std::make_pair(std::string_view(#CLASS "::" #METHOD),                    \
                     reinterpret_cast<void*>(                                  \
                         tonic::FfiDispatcher<CLASS, decltype(&CLASS::METHOD), \
                                              &CLASS::METHOD>::Call)));

namespace {

std::once_flag g_dispatchers_init_flag;
std::unordered_map<std::string_view, void*> g_function_dispatchers;

void* ResolveFfiNativeFunction(const char* name, uintptr_t args) {
  auto it = g_function_dispatchers.find(name);
  return (it != g_function_dispatchers.end()) ? it->second : nullptr;
}

void InitDispatcherMap() {
  FFI_FUNCTION_LIST(FFI_FUNCTION_INSERT)
  FFI_METHOD_LIST(FFI_METHOD_INSERT)

#ifdef IMPELLER_ENABLE_3D
  FFI_FUNCTION_LIST_3D(FFI_FUNCTION_INSERT)
  FFI_METHOD_LIST_3D(FFI_METHOD_INSERT)

  FFI_FUNCTION_LIST_GPU(FFI_FUNCTION_INSERT)
  FFI_METHOD_LIST_GPU(FFI_METHOD_INSERT)
#endif  // IMPELLER_ENABLE_3D
}

}  // anonymous namespace

void DartUI::InitForIsolate(const Settings& settings) {
  std::call_once(g_dispatchers_init_flag, InitDispatcherMap);

  auto dart_ui = Dart_LookupLibrary(ToDart("dart:ui"));
  if (Dart_IsError(dart_ui)) {
    Dart_PropagateError(dart_ui);
  }

  // Set up FFI Native resolver for dart:ui.
  Dart_Handle result =
      Dart_SetFfiNativeResolver(dart_ui, ResolveFfiNativeFunction);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }

  if (settings.enable_impeller) {
    result = Dart_SetField(dart_ui, ToDart("_impellerEnabled"), Dart_True());
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
  }
}

}  // namespace flutter

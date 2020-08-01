// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/dart_ui.h"

#include "flutter/fml/build_config.h"
#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/compositing/scene_builder.h"
#include "flutter/lib/ui/dart_runtime_hooks.h"
#include "flutter/lib/ui/isolate_name_server/isolate_name_server_natives.h"
#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/painting/codec.h"
#include "flutter/lib/ui/painting/color_filter.h"
#include "flutter/lib/ui/painting/engine_layer.h"
#include "flutter/lib/ui/painting/frame_info.h"
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
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/lib/ui/text/paragraph.h"
#include "flutter/lib/ui/text/paragraph_builder.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/logging/dart_error.h"

#if defined(LEGACY_FUCHSIA_EMBEDDER)
#include "flutter/lib/ui/compositing/scene_host.h"  // nogncheck
#endif

using tonic::ToDart;

namespace flutter {
namespace {

static tonic::DartLibraryNatives* g_natives;

Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                      int argument_count,
                                      bool* auto_setup_scope) {
  return g_natives->GetNativeFunction(name, argument_count, auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  return g_natives->GetSymbol(native_function);
}

}  // namespace

void DartUI::InitForGlobal() {
  if (!g_natives) {
    g_natives = new tonic::DartLibraryNatives();
    Canvas::RegisterNatives(g_natives);
    CanvasGradient::RegisterNatives(g_natives);
    CanvasImage::RegisterNatives(g_natives);
    CanvasPath::RegisterNatives(g_natives);
    CanvasPathMeasure::RegisterNatives(g_natives);
    Codec::RegisterNatives(g_natives);
    ColorFilter::RegisterNatives(g_natives);
    DartRuntimeHooks::RegisterNatives(g_natives);
    EngineLayer::RegisterNatives(g_natives);
    FontCollection::RegisterNatives(g_natives);
    FrameInfo::RegisterNatives(g_natives);
    ImageDescriptor::RegisterNatives(g_natives);
    ImageFilter::RegisterNatives(g_natives);
    ImageShader::RegisterNatives(g_natives);
    ImmutableBuffer::RegisterNatives(g_natives);
    IsolateNameServerNatives::RegisterNatives(g_natives);
    Paragraph::RegisterNatives(g_natives);
    ParagraphBuilder::RegisterNatives(g_natives);
    Picture::RegisterNatives(g_natives);
    PictureRecorder::RegisterNatives(g_natives);
    Scene::RegisterNatives(g_natives);
    SceneBuilder::RegisterNatives(g_natives);
    SemanticsUpdate::RegisterNatives(g_natives);
    SemanticsUpdateBuilder::RegisterNatives(g_natives);
    Vertices::RegisterNatives(g_natives);
    PlatformConfiguration::RegisterNatives(g_natives);
#if defined(LEGACY_FUCHSIA_EMBEDDER)
    SceneHost::RegisterNatives(g_natives);
#endif
  }
}

void DartUI::InitForIsolate() {
  FML_DCHECK(g_natives);
  Dart_Handle result = Dart_SetNativeResolver(
      Dart_LookupLibrary(ToDart("dart:ui")), GetNativeFunction, GetSymbol);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
}

}  // namespace flutter

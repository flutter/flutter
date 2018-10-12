// Copyright 2014 The Chromium Authors. All rights reserved.
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
#include "flutter/lib/ui/painting/engine_layer.h"
#include "flutter/lib/ui/painting/frame_info.h"
#include "flutter/lib/ui/painting/gradient.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/image_shader.h"
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
#include "flutter/lib/ui/window/window.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/logging/dart_error.h"

using tonic::ToDart;

namespace blink {
namespace {

static tonic::DartLibraryNatives* g_natives;
static tonic::DartLibraryNatives* g_natives_secondary;

Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                      int argument_count,
                                      bool* auto_setup_scope) {
  return g_natives->GetNativeFunction(name, argument_count, auto_setup_scope);
}

Dart_NativeFunction GetNativeFunctionSecondary(Dart_Handle name,
                                               int argument_count,
                                               bool* auto_setup_scope) {
  return g_natives_secondary->GetNativeFunction(name, argument_count,
                                                auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  return g_natives->GetSymbol(native_function);
}

const uint8_t* GetSymbolSecondary(Dart_NativeFunction native_function) {
  return g_natives_secondary->GetSymbol(native_function);
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
    DartRuntimeHooks::RegisterNatives(g_natives);
    EngineLayer::RegisterNatives(g_natives);
    FontCollection::RegisterNatives(g_natives);
    FrameInfo::RegisterNatives(g_natives);
    ImageFilter::RegisterNatives(g_natives);
    ImageShader::RegisterNatives(g_natives);
    IsolateNameServerNatives::RegisterNatives(g_natives);
    Paragraph::RegisterNatives(g_natives);
    ParagraphBuilder::RegisterNatives(g_natives);
    Picture::RegisterNatives(g_natives);
    PictureRecorder::RegisterNatives(g_natives);
    Scene::RegisterNatives(g_natives);
    SceneBuilder::RegisterNatives(g_natives);
    SceneHost::RegisterNatives(g_natives);
    SemanticsUpdate::RegisterNatives(g_natives);
    SemanticsUpdateBuilder::RegisterNatives(g_natives);
    Vertices::RegisterNatives(g_natives);
    Window::RegisterNatives(g_natives);

    // Secondary isolates do not provide UI-related APIs.
    g_natives_secondary = new tonic::DartLibraryNatives();
    DartRuntimeHooks::RegisterNatives(g_natives_secondary);
    IsolateNameServerNatives::RegisterNatives(g_natives_secondary);
  }
}

void DartUI::InitForIsolate(bool is_root_isolate) {
  FML_DCHECK(g_natives);
  auto get_native_function =
      is_root_isolate ? GetNativeFunction : GetNativeFunctionSecondary;
  auto get_symbol = is_root_isolate ? GetSymbol : GetSymbolSecondary;
  DART_CHECK_VALID(Dart_SetNativeResolver(Dart_LookupLibrary(ToDart("dart:ui")),
                                          get_native_function, get_symbol));
}

}  // namespace blink

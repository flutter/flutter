// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/dart_ui.h"

#include "flutter/lib/ui/painting/color_filter.h"
#include "flutter/lib/ui/painting/gradient.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/image_shader.h"
#include "flutter/lib/ui/painting/mask_filter.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_error.h"
#include "sky/engine/bindings/dart_runtime_hooks.h"
#include "sky/engine/bindings/mojo_services.h"
#include "sky/engine/core/compositing/Scene.h"
#include "sky/engine/core/compositing/SceneBuilder.h"
#include "sky/engine/core/painting/Canvas.h"
#include "sky/engine/core/painting/PictureRecorder.h"
#include "sky/engine/core/painting/painting.h"
#include "sky/engine/core/text/Paragraph.h"
#include "sky/engine/core/text/ParagraphBuilder.h"
#include "sky/engine/core/window/window.h"

namespace blink {
namespace {

static DartLibraryNatives* g_natives;

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
    g_natives = new DartLibraryNatives();
    Canvas::RegisterNatives(g_natives);
    CanvasGradient::RegisterNatives(g_natives);
    CanvasImage::RegisterNatives(g_natives);
    CanvasPath::RegisterNatives(g_natives);
    ColorFilter::RegisterNatives(g_natives);
    DartRuntimeHooks::RegisterNatives(g_natives);
    ImageFilter::RegisterNatives(g_natives);
    ImageShader::RegisterNatives(g_natives);
    MaskFilter::RegisterNatives(g_natives);
    MojoServices::RegisterNatives(g_natives);
    Painting::RegisterNatives(g_natives);
    Paragraph::RegisterNatives(g_natives);
    ParagraphBuilder::RegisterNatives(g_natives);
    Picture::RegisterNatives(g_natives);
    PictureRecorder::RegisterNatives(g_natives);
    Scene::RegisterNatives(g_natives);
    SceneBuilder::RegisterNatives(g_natives);
    Window::RegisterNatives(g_natives);
  }
}

void DartUI::InitForIsolate() {
  DCHECK(g_natives);
  DART_CHECK_VALID(Dart_SetNativeResolver(
      Dart_LookupLibrary(ToDart("dart:ui")), GetNativeFunction, GetSymbol));
}

}  // namespace blink

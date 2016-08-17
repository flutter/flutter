// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph_builder_stub.h"

#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

namespace blink {

static void ParagraphBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&ParagraphBuilder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ParagraphBuilder);

#define FOR_EACH_BINDING(V)      \
  V(ParagraphBuilder, pushStyle) \
  V(ParagraphBuilder, pop)       \
  V(ParagraphBuilder, addText)   \
  V(ParagraphBuilder, build)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ParagraphBuilder::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"ParagraphBuilder_constructor", ParagraphBuilder_constructor, 1, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

ParagraphBuilder::ParagraphBuilder() {}

ParagraphBuilder::~ParagraphBuilder() {}

void ParagraphBuilder::pushStyle(tonic::Int32List& encoded,
                                 const std::string& fontFamily,
                                 double fontSize,
                                 double letterSpacing,
                                 double wordSpacing,
                                 double height) {
  encoded.Release();
}

void ParagraphBuilder::pop() {}

void ParagraphBuilder::addText(const std::string& text) {}

ftl::RefPtr<Paragraph> ParagraphBuilder::build(tonic::Int32List& encoded,
                                               const std::string& fontFamily,
                                               double fontSize,
                                               double lineHeight) {
  encoded.Release();
  return Paragraph::create();
}

}  // namespace blink

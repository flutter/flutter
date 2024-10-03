// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/paragraph_builder.h"

#include "flutter/third_party/txt/src/skia/paragraph_builder_skia.h"
#include "impeller/base/validation.h"
#include "impeller/toolkit/interop/paragraph.h"

namespace impeller::interop {

ParagraphBuilder::ParagraphBuilder(const TypographyContext& context) {
  if (!context.IsValid()) {
    VALIDATION_LOG << "Invalid typography context.";
    return;
  }

  static txt::ParagraphStyle kBaseStyle;

  builder_ = std::make_unique<txt::ParagraphBuilderSkia>(
      kBaseStyle,                   //
      context.GetFontCollection(),  //
      true                          // is impeller enabled
  );
}

ParagraphBuilder::~ParagraphBuilder() = default;

bool ParagraphBuilder::IsValid() const {
  return !!builder_;
}

void ParagraphBuilder::PushStyle(const ParagraphStyle& style) {
  builder_->PushStyle(style.CreateTextStyle());
}

void ParagraphBuilder::PopStyle() {
  builder_->Pop();
}

void ParagraphBuilder::AddText(const uint8_t* data, size_t byte_length) {
  builder_->AddText(data, byte_length);
}

ScopedObject<Paragraph> ParagraphBuilder::Build(Scalar width) const {
  auto txt_paragraph = builder_->Build();
  if (!txt_paragraph) {
    return nullptr;
  }
  txt_paragraph->Layout(width);
  return Create<Paragraph>(std::move(txt_paragraph));
}

}  // namespace impeller::interop

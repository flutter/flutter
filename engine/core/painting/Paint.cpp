// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Paint.h"

#include "sky/engine/core/painting/ColorFilter.h"
#include "sky/engine/core/painting/DrawLooper.h"
#include "sky/engine/core/painting/MaskFilter.h"
#include "sky/engine/core/painting/Shader.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkString.h"

namespace blink {

namespace {

template <typename T>
void SkToString(const char* title, const T* sk_object, StringBuilder* result) {
  if (!sk_object)
    return;
  SkString string;
  sk_object->toString(&string);
  result->append(String::format(", %s: %s", title, string.c_str()));
}

}

Paint::Paint() {
  setIsAntiAlias(true);
}

Paint::~Paint() {
}

void Paint::setDrawLooper(DrawLooper* looper) {
  ASSERT(looper);
  paint_.setLooper(looper->looper());
}

void Paint::setColorFilter(ColorFilter* filter) {
  ASSERT(filter);
  paint_.setColorFilter(filter->filter());
}

void Paint::setMaskFilter(MaskFilter* filter) {
  ASSERT(filter);
  paint_.setMaskFilter(filter->filter());
}

void Paint::setShader(Shader* shader) {
  ASSERT(shader);
  paint_.setShader(shader->shader());
}

void Paint::setStyle(SkPaint::Style style) {
  paint_.setStyle(style);
}

void Paint::setTransferMode(SkXfermode::Mode transfer_mode) {
  paint_.setXfermodeMode(transfer_mode);
}

String Paint::toString() const {
  StringBuilder result;

  result.append("Paint(");

  result.append(String::format("color:Color(0x%.8x)", paint_.getColor()));

  SkToString("shader", paint_.getShader(), &result);
  SkToString("colorFilter", paint_.getColorFilter(), &result);
  SkToString("maskFilter", paint_.getMaskFilter(), &result);

  if (paint_.getLooper()) {
    // TODO(mpcomplete): Figure out how to show a drawLooper.
    result.append(", drawLooper:true");
  }
  result.append(")");

  return result.toString();
}

}  // namespace blink

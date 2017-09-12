// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_RENDERING_RENDEROBJECTINLINES_H_
#define SKY_ENGINE_CORE_RENDERING_RENDEROBJECTINLINES_H_

#include "flutter/sky/engine/core/rendering/RenderObject.h"

namespace blink {

// The following methods are inlined for performance but not put in
// RenderObject.h because that would unnecessarily tie RenderObject.h
// to StyleEngine.h for all users of RenderObject.h that don't use
// these methods.

inline RenderStyle* RenderObject::firstLineStyle() const {
  return style();
}

inline RenderStyle* RenderObject::style(bool firstLine) const {
  return style();
}

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDEROBJECTINLINES_H_

/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_SHAPEVALUE_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_SHAPEVALUE_H_

#include "flutter/sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "flutter/sky/engine/core/rendering/style/StyleImage.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"

namespace blink {

class ShapeValue : public RefCounted<ShapeValue> {
 public:
  enum ShapeValueType {
    // The Auto value is defined by a null ShapeValue*
    Box,
    Image
  };

  static PassRefPtr<ShapeValue> createBoxShapeValue(CSSBoxType cssBox) {
    return adoptRef(new ShapeValue(cssBox));
  }

  static PassRefPtr<ShapeValue> createImageValue(PassRefPtr<StyleImage> image) {
    return adoptRef(new ShapeValue(image));
  }

  ShapeValueType type() const { return m_type; }

  StyleImage* image() const { return m_image.get(); }
  bool isImageValid() const {
    if (!image())
      return false;
    return image()->isGeneratedImage();
  }
  void setImage(PassRefPtr<StyleImage> image) {
    ASSERT(type() == Image);
    if (m_image != image)
      m_image = image;
  }
  CSSBoxType cssBox() const { return m_cssBox; }

  bool operator==(const ShapeValue& other) const;

 private:
  ShapeValue(ShapeValueType type) : m_type(type), m_cssBox(BoxMissing) {}
  ShapeValue(PassRefPtr<StyleImage> image)
      : m_type(Image), m_image(image), m_cssBox(ContentBox) {}
  ShapeValue(CSSBoxType cssBox) : m_type(Box), m_cssBox(cssBox) {}

  ShapeValueType m_type;
  RefPtr<StyleImage> m_image;
  CSSBoxType m_cssBox;
};

inline bool ShapeValue::operator==(const ShapeValue& other) const {
  if (type() != other.type())
    return false;

  switch (type()) {
    case Box:
      return cssBox() == other.cssBox();
    case Image:
      return image() == other.image();
  }

  ASSERT_NOT_REACHED();
  return false;
}

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_SHAPEVALUE_H_

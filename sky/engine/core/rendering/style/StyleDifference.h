// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_STYLEDIFFERENCE_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_STYLEDIFFERENCE_H_

#include "flutter/sky/engine/wtf/Assertions.h"

namespace blink {

class StyleDifference {
 public:
  enum PropertyDifference {
    TransformChanged = 1 << 0,
    OpacityChanged = 1 << 1,
    ZIndexChanged = 1 << 2,
    FilterChanged = 1 << 3,
  };

  StyleDifference()
      : m_layoutType(NoLayout), m_propertySpecificDifferences(0) {}

  bool needsLayout() const { return m_layoutType != NoLayout; }
  void clearNeedsLayout() { m_layoutType = NoLayout; }

  // The offset of this positioned object has been updated.
  bool needsPositionedMovementLayout() const {
    return m_layoutType == PositionedMovement;
  }
  void setNeedsPositionedMovementLayout() {
    ASSERT(!needsFullLayout());
    m_layoutType = PositionedMovement;
  }

  bool needsFullLayout() const { return m_layoutType == FullLayout; }
  void setNeedsFullLayout() { m_layoutType = FullLayout; }

  bool transformChanged() const {
    return m_propertySpecificDifferences & TransformChanged;
  }
  void setTransformChanged() {
    m_propertySpecificDifferences |= TransformChanged;
  }

  bool opacityChanged() const {
    return m_propertySpecificDifferences & OpacityChanged;
  }
  void setOpacityChanged() { m_propertySpecificDifferences |= OpacityChanged; }

  bool zIndexChanged() const {
    return m_propertySpecificDifferences & ZIndexChanged;
  }
  void setZIndexChanged() { m_propertySpecificDifferences |= ZIndexChanged; }

  bool filterChanged() const {
    return m_propertySpecificDifferences & FilterChanged;
  }
  void setFilterChanged() { m_propertySpecificDifferences |= FilterChanged; }

 private:
  enum LayoutType { NoLayout = 0, PositionedMovement, FullLayout };
  unsigned m_layoutType : 2;

  unsigned m_propertySpecificDifferences : 5;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_STYLEDIFFERENCE_H_

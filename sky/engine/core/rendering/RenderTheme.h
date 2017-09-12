/*
 * This file is part of the theme implementation for form controls in WebCore.
 *
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Computer, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERTHEME_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERTHEME_H_

#include "flutter/sky/engine/core/rendering/RenderObject.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/RefCounted.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace blink {

class RenderTheme : public RefCounted<RenderTheme> {
 protected:
  RenderTheme();

 public:
  // This function is to be implemented in your platform-specific theme
  // implementation to hand back the appropriate platform theme.
  static RenderTheme& theme();

  Color focusRingColor() const;
  virtual double caretBlinkInterval() const { return 0.5; }

  // Text selection colors.
  Color activeSelectionBackgroundColor() const;
  Color inactiveSelectionBackgroundColor() const;
  Color activeSelectionForegroundColor() const;
  Color inactiveSelectionForegroundColor() const;

  virtual bool supportsSelectionForegroundColors() const { return true; }
  virtual Color platformDefaultCompositionBackgroundColor() const {
    return defaultCompositionBackgroundColor;
  }
  void setCustomFocusRingColor(const Color&);

  static Color tapHighlightColor();
  virtual Color platformTapHighlightColor() const {
    return RenderTheme::defaultTapHighlightColor;
  }

 protected:
  virtual Color platformActiveSelectionBackgroundColor() const;
  virtual Color platformInactiveSelectionBackgroundColor() const;
  virtual Color platformActiveSelectionForegroundColor() const;
  virtual Color platformInactiveSelectionForegroundColor() const;
  virtual Color platformFocusRingColor() const { return Color(0, 0, 0); }

 private:
  Color m_customFocusRingColor;
  bool m_hasCustomFocusRingColor;

  // This color is expected to be drawn on a semi-transparent overlay,
  // making it more transparent than its alpha value indicates.
  static const RGBA32 defaultTapHighlightColor = 0x66000000;
  static const RGBA32 defaultCompositionBackgroundColor = 0xFFFFDD55;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERTHEME_H_

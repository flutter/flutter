// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_SCROLLBAR_IMPL_H_
#define SKY_VIEWER_CC_SCROLLBAR_IMPL_H_

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "cc/input/scrollbar.h"
#include "sky/engine/public/platform/WebScrollbarThemePainter.h"

namespace blink {
class WebScrollbar;
class WebScrollbarThemeGeometry;
}

namespace sky_viewer_cc {

class ScrollbarImpl : public cc::Scrollbar {
 public:
  ScrollbarImpl(scoped_ptr<blink::WebScrollbar> scrollbar,
                blink::WebScrollbarThemePainter painter,
                scoped_ptr<blink::WebScrollbarThemeGeometry> geometry);
  virtual ~ScrollbarImpl();

  // cc::Scrollbar implementation.
  virtual cc::ScrollbarOrientation Orientation() const override;
  virtual bool IsLeftSideVerticalScrollbar() const override;
  // FIXME(sky): Remove once we merge repos.
  bool HasThumb() const override;
  virtual bool IsOverlay() const override;
  virtual gfx::Point Location() const override;
  virtual int ThumbThickness() const override;
  virtual int ThumbLength() const override;
  virtual gfx::Rect TrackRect() const override;
  virtual void PaintPart(SkCanvas* canvas,
                         cc::ScrollbarPart part,
                         const gfx::Rect& content_rect) override;

 private:
  scoped_ptr<blink::WebScrollbar> scrollbar_;
  blink::WebScrollbarThemePainter painter_;
  scoped_ptr<blink::WebScrollbarThemeGeometry> geometry_;

  DISALLOW_COPY_AND_ASSIGN(ScrollbarImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_SCROLLBAR_IMPL_H_

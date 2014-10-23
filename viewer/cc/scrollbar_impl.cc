// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/scrollbar_impl.h"

#include "base/logging.h"
#include "sky/engine/public/platform/WebScrollbar.h"
#include "sky/engine/public/platform/WebScrollbarThemeGeometry.h"

using blink::WebScrollbar;

namespace sky_viewer_cc {

ScrollbarImpl::ScrollbarImpl(
    scoped_ptr<WebScrollbar> scrollbar,
    blink::WebScrollbarThemePainter painter,
    scoped_ptr<blink::WebScrollbarThemeGeometry> geometry)
    : scrollbar_(scrollbar.Pass()),
      painter_(painter),
      geometry_(geometry.Pass()) {
}

ScrollbarImpl::~ScrollbarImpl() {
}

cc::ScrollbarOrientation ScrollbarImpl::Orientation() const {
  if (scrollbar_->orientation() == WebScrollbar::Horizontal)
    return cc::HORIZONTAL;
  return cc::VERTICAL;
}

bool ScrollbarImpl::IsLeftSideVerticalScrollbar() const {
  return scrollbar_->isLeftSideVerticalScrollbar();
}

bool ScrollbarImpl::HasThumb() const {
  return true;
};

bool ScrollbarImpl::IsOverlay() const {
  return scrollbar_->isOverlay();
}

gfx::Point ScrollbarImpl::Location() const {
  return scrollbar_->location();
}

int ScrollbarImpl::ThumbThickness() const {
  gfx::Rect thumb_rect = geometry_->thumbRect();
  if (scrollbar_->orientation() == WebScrollbar::Horizontal)
    return thumb_rect.height();
  return thumb_rect.width();
}

int ScrollbarImpl::ThumbLength() const {
  gfx::Rect thumb_rect = geometry_->thumbRect();
  if (scrollbar_->orientation() == WebScrollbar::Horizontal)
    return thumb_rect.width();
  return thumb_rect.height();
}

gfx::Rect ScrollbarImpl::TrackRect() const {
  return geometry_->trackRect();
}

void ScrollbarImpl::PaintPart(SkCanvas* canvas,
                              cc::ScrollbarPart part,
                              const gfx::Rect& content_rect) {
  if (part == cc::THUMB) {
    painter_.paintThumb(canvas, content_rect);
    return;
  }
}

}  // namespace sky_viewer_cc
